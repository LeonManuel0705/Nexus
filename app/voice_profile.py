import numpy as np
import os
import json
import threading
from typing import Optional, Tuple, List
from pathlib import Path
import hashlib

PROFILES_DIR = Path(__file__).parent.parent / "voice_profiles"
EMBEDDING_DIM = 192
DEFAULT_VERIFICATION_THRESHOLD = 0.30  # Default cosine similarity threshold
HIGH_CONFIDENCE_THRESHOLD = 0.50
MIN_ENROLLMENT_DURATION = 30.0
SAMPLE_RATE = 16000


def get_verification_threshold() -> float:
    """Get the current verification threshold from adaptive system."""
    try:
        from adaptive_system import get_param
        return get_param("voice_threshold")
    except:
        return DEFAULT_VERIFICATION_THRESHOLD

# Use the larger, more accurate WavLM-based model
# Options: "speechbrain/spkrec-ecapa-voxceleb" (faster, less accurate)
#          "microsoft/wavlm-base-plus-sv" (slower, more accurate)
#          "speechbrain/spkrec-resnet-voxceleb" (good balance)
SPEAKER_MODEL = "speechbrain/spkrec-ecapa-voxceleb"  # Default, can be changed


class VoiceProfile:

    def __init__(self, name: str, profile_id: Optional[str] = None):
        self.name = name
        self.profile_id = profile_id or self._generate_id(name)
        self.embeddings: List[np.ndarray] = []
        self.total_duration = 0.0
        self.created_at: Optional[str] = None
        self.sample_count = 0

    def _generate_id(self, name: str) -> str:
        import time
        data = f"{name}_{time.time()}".encode()
        return hashlib.md5(data).hexdigest()[:12]

    def add_embedding(self, embedding: np.ndarray, duration: float):
        self.embeddings.append(embedding)
        self.total_duration += duration
        self.sample_count += 1
        if len(self.embeddings) > 100:
            self.embeddings.pop(0)

    def get_average_embedding(self) -> Optional[np.ndarray]:
        if not self.embeddings:
            return None
        return np.mean(self.embeddings, axis=0)

    def verify(self, embedding: np.ndarray) -> Tuple[bool, float]:
        avg = self.get_average_embedding()
        if avg is None:
            return False, 0.0

        # Get threshold from adaptive system
        threshold = get_verification_threshold()

        # Normalize embeddings for cosine similarity
        avg_norm = avg / (np.linalg.norm(avg) + 1e-8)
        emb_norm = embedding / (np.linalg.norm(embedding) + 1e-8)

        similarity = np.dot(avg_norm, emb_norm)

        is_match = similarity >= threshold
        # Map similarity to confidence: threshold -> 0.0, 1.0 -> 1.0
        confidence = min(1.0, max(0.0, (similarity - threshold) / (1.0 - threshold)))

        print(f"[VoiceFilter] Similarity: {similarity:.3f}, Threshold: {threshold}, Match: {is_match}, Confidence: {confidence:.3f}")

        return is_match, confidence

    def verify_multi(self, embedding: np.ndarray, top_k: int = 5) -> Tuple[bool, float]:
        """Compare against multiple stored embeddings for more robust matching."""
        if not self.embeddings:
            return False, 0.0

        # Get threshold from adaptive system
        threshold = get_verification_threshold()

        # Compare against the most recent embeddings
        recent_embeddings = self.embeddings[-top_k:] if len(self.embeddings) > top_k else self.embeddings

        similarities = []
        emb_norm = embedding / (np.linalg.norm(embedding) + 1e-8)

        for stored_emb in recent_embeddings:
            stored_norm = stored_emb / (np.linalg.norm(stored_emb) + 1e-8)
            sim = np.dot(stored_norm, emb_norm)
            similarities.append(sim)

        # Use the maximum similarity (best match)
        max_similarity = max(similarities)
        avg_similarity = np.mean(similarities)

        # Use a combination: mostly max, but penalize if average is low
        combined_similarity = 0.7 * max_similarity + 0.3 * avg_similarity

        is_match = combined_similarity >= threshold
        confidence = min(1.0, max(0.0, (combined_similarity - threshold) / (1.0 - threshold)))

        print(f"[VoiceFilter] Max: {max_similarity:.3f}, Avg: {avg_similarity:.3f}, Combined: {combined_similarity:.3f}, Threshold: {threshold}, Match: {is_match}")

        return is_match, confidence

    def is_ready(self) -> bool:
        return self.total_duration >= MIN_ENROLLMENT_DURATION and len(self.embeddings) >= 5

    def get_quality_score(self) -> float:
        if not self.embeddings:
            return 0.0

        duration_score = min(1.0, self.total_duration / 60.0)

        if len(self.embeddings) > 1:
            stacked = np.stack(self.embeddings)
            std_score = 1.0 - min(1.0, np.mean(np.std(stacked, axis=0)))
        else:
            std_score = 0.5

        return (duration_score * 0.6 + std_score * 0.4)

    def to_dict(self) -> dict:
        return {
            'name': self.name,
            'profile_id': self.profile_id,
            'embeddings': [e.tolist() for e in self.embeddings],
            'total_duration': self.total_duration,
            'created_at': self.created_at,
            'sample_count': self.sample_count
        }

    @classmethod
    def from_dict(cls, data: dict) -> 'VoiceProfile':
        profile = cls(data['name'], data['profile_id'])
        profile.embeddings = [np.array(e) for e in data['embeddings']]
        profile.total_duration = data['total_duration']
        profile.created_at = data.get('created_at')
        profile.sample_count = data.get('sample_count', len(profile.embeddings))
        return profile


class VoiceProfileManager:

    def __init__(self):
        self._model = None
        self._model_lock = threading.Lock()
        self._model_loaded = False
        self._current_profile: Optional[VoiceProfile] = None
        self._enrollment_buffer: List[np.ndarray] = []
        self._is_enrolling = False
        PROFILES_DIR.mkdir(parents=True, exist_ok=True)

    def _load_model(self) -> bool:
        if self._model_loaded:
            return self._model is not None

        with self._model_lock:
            if self._model_loaded:
                return self._model is not None

            try:
                from speechbrain.inference.speaker import EncoderClassifier

                model_dir = Path(__file__).parent.parent / "models" / "speaker_model"
                model_dir.mkdir(parents=True, exist_ok=True)

                import torch
                if torch.backends.mps.is_available():
                    device = "mps"
                else:
                    device = "cpu"

                self._model = EncoderClassifier.from_hparams(
                    source="speechbrain/spkrec-ecapa-voxceleb",
                    savedir=str(model_dir),
                    run_opts={"device": device}
                )
                self._model_loaded = True
                return True

            except Exception as e:
                print(f"Failed to load speaker model: {e}")
                self._model_loaded = True
                return False

    def _preprocess_audio(self, audio: np.ndarray) -> np.ndarray:
        """Preprocess audio for better speaker recognition."""
        from scipy import signal

        if audio.dtype != np.float32:
            audio = audio.astype(np.float32)

        # Remove DC offset
        audio = audio - np.mean(audio)

        # Check if audio has enough energy (not silence)
        energy = np.sqrt(np.mean(audio ** 2))
        if energy < 0.001:
            return audio  # Return as-is if too quiet

        # Apply pre-emphasis filter (boost high frequencies for speech)
        pre_emphasis = 0.97
        audio = np.append(audio[0], audio[1:] - pre_emphasis * audio[:-1])

        # Normalize to [-1, 1]
        max_val = np.max(np.abs(audio))
        if max_val > 0:
            audio = audio / max_val * 0.95

        return audio

    def _extract_embedding(self, audio: np.ndarray) -> Optional[np.ndarray]:
        if not self._load_model() or self._model is None:
            return None

        try:
            import torch

            # Preprocess audio
            audio = self._preprocess_audio(audio)

            # Check minimum length (at least 0.5 seconds)
            min_samples = int(SAMPLE_RATE * 0.5)
            if len(audio) < min_samples:
                print(f"[VoiceFilter] Audio too short: {len(audio)} samples")
                return None

            audio_tensor = torch.tensor(audio).unsqueeze(0)

            with torch.no_grad():
                embedding = self._model.encode_batch(audio_tensor)
                emb = embedding.squeeze().cpu().numpy()

                # L2 normalize the embedding
                emb = emb / (np.linalg.norm(emb) + 1e-8)
                return emb

        except Exception as e:
            print(f"Embedding extraction error: {e}")
            return None

    def start_enrollment(self, teacher_name: str) -> str:
        from datetime import datetime

        self._current_profile = VoiceProfile(teacher_name)
        self._current_profile.created_at = datetime.now().isoformat()
        self._enrollment_buffer = []
        self._is_enrolling = True

        return self._current_profile.profile_id

    def add_enrollment_audio(self, audio: np.ndarray) -> dict:
        if not self._is_enrolling or self._current_profile is None:
            return {'error': 'Not in enrollment mode'}

        embedding = self._extract_embedding(audio)
        if embedding is None:
            return {
                'status': 'processing',
                'message': 'Audio processed (model loading...)',
                'duration': self._current_profile.total_duration,
                'is_ready': False
            }

        duration = len(audio) / SAMPLE_RATE
        self._current_profile.add_embedding(embedding, duration)

        is_ready = self._current_profile.is_ready()
        quality = self._current_profile.get_quality_score()

        return {
            'status': 'success',
            'duration': self._current_profile.total_duration,
            'sample_count': self._current_profile.sample_count,
            'is_ready': is_ready,
            'quality_score': quality,
            'min_duration': MIN_ENROLLMENT_DURATION
        }

    def finish_enrollment(self) -> dict:
        if not self._is_enrolling or self._current_profile is None:
            return {'error': 'Not in enrollment mode'}

        if not self._current_profile.is_ready():
            return {
                'error': 'Not enough audio samples',
                'duration': self._current_profile.total_duration,
                'required': MIN_ENROLLMENT_DURATION
            }

        profile_path = PROFILES_DIR / f"{self._current_profile.profile_id}.json"
        with open(profile_path, 'w') as f:
            json.dump(self._current_profile.to_dict(), f)

        result = {
            'status': 'success',
            'profile_id': self._current_profile.profile_id,
            'name': self._current_profile.name,
            'duration': self._current_profile.total_duration,
            'quality_score': self._current_profile.get_quality_score()
        }

        self._is_enrolling = False
        return result

    def cancel_enrollment(self):
        self._is_enrolling = False
        self._current_profile = None
        self._enrollment_buffer = []

    def load_profile(self, profile_id: str) -> bool:
        profile_path = PROFILES_DIR / f"{profile_id}.json"

        if not profile_path.exists():
            return False

        try:
            with open(profile_path, 'r') as f:
                data = json.load(f)
            self._current_profile = VoiceProfile.from_dict(data)
            return True
        except Exception as e:
            print(f"Error loading profile: {e}")
            return False

    def verify_audio(self, audio: np.ndarray) -> Tuple[bool, float]:
        if self._current_profile is None:
            return True, 0.5

        embedding = self._extract_embedding(audio)
        if embedding is None:
            # If embedding extraction fails, allow transcription (don't block)
            return True, 0.5

        # Use multi-comparison for more robust matching
        return self._current_profile.verify_multi(embedding, top_k=5)

    def is_teacher_speaking(self, audio: np.ndarray) -> bool:
        is_match, confidence = self.verify_audio(audio)
        return is_match  # Just use the match result, confidence is already factored in

    def list_profiles(self) -> List[dict]:
        profiles = []

        for path in PROFILES_DIR.glob("*.json"):
            try:
                with open(path, 'r') as f:
                    data = json.load(f)
                profiles.append({
                    'profile_id': data['profile_id'],
                    'name': data['name'],
                    'created_at': data.get('created_at'),
                    'duration': data.get('total_duration', 0)
                })
            except Exception:
                continue

        return sorted(profiles, key=lambda x: x.get('created_at', ''), reverse=True)

    def delete_profile(self, profile_id: str) -> bool:
        profile_path = PROFILES_DIR / f"{profile_id}.json"

        if profile_path.exists():
            profile_path.unlink()
            if self._current_profile and self._current_profile.profile_id == profile_id:
                self._current_profile = None
            return True
        return False

    def get_current_profile(self) -> Optional[dict]:
        if self._current_profile is None:
            return None

        return {
            'profile_id': self._current_profile.profile_id,
            'name': self._current_profile.name,
            'is_ready': self._current_profile.is_ready(),
            'quality_score': self._current_profile.get_quality_score()
        }


_profile_manager: Optional[VoiceProfileManager] = None


def get_profile_manager() -> VoiceProfileManager:
    global _profile_manager
    if _profile_manager is None:
        _profile_manager = VoiceProfileManager()
    return _profile_manager


def verify_teacher_audio(audio: np.ndarray) -> Tuple[bool, float]:
    return get_profile_manager().verify_audio(audio)


def is_teacher_audio(audio: np.ndarray) -> bool:
    return get_profile_manager().is_teacher_speaking(audio)
