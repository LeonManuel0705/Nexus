"""
Voice Profile Management for Teacher Voice Isolation

This module provides:
1. Teacher voice enrollment - record a sample to create a voice profile
2. Speaker verification - check if current audio matches the teacher
3. Profile persistence - save/load profiles to disk
"""

import numpy as np
import os
import json
import threading
from typing import Optional, Tuple, List
from pathlib import Path
import hashlib

PROFILES_DIR = Path(__file__).parent.parent / "voice_profiles"
EMBEDDING_DIM = 192
VERIFICATION_THRESHOLD = 0.70
HIGH_CONFIDENCE_THRESHOLD = 0.85
MIN_ENROLLMENT_DURATION = 30.0  # seconds
SAMPLE_RATE = 16000


class VoiceProfile:
    """Represents a speaker's voice profile with embeddings."""

    def __init__(self, name: str, profile_id: Optional[str] = None):
        self.name = name
        self.profile_id = profile_id or self._generate_id(name)
        self.embeddings: List[np.ndarray] = []
        self.total_duration = 0.0
        self.created_at: Optional[str] = None
        self.sample_count = 0

    def _generate_id(self, name: str) -> str:
        """Generate a unique profile ID."""
        import time
        data = f"{name}_{time.time()}".encode()
        return hashlib.md5(data).hexdigest()[:12]

    def add_embedding(self, embedding: np.ndarray, duration: float):
        """Add a new voice embedding from audio sample."""
        self.embeddings.append(embedding)
        self.total_duration += duration
        self.sample_count += 1

        # Keep max 100 embeddings, remove oldest
        if len(self.embeddings) > 100:
            self.embeddings.pop(0)

    def get_average_embedding(self) -> Optional[np.ndarray]:
        """Get the centroid of all embeddings."""
        if not self.embeddings:
            return None
        return np.mean(self.embeddings, axis=0)

    def verify(self, embedding: np.ndarray) -> Tuple[bool, float]:
        """
        Verify if an embedding matches this profile.
        Returns (is_match, confidence_score).
        """
        avg = self.get_average_embedding()
        if avg is None:
            return False, 0.0

        # Cosine similarity
        similarity = np.dot(avg, embedding) / (
            np.linalg.norm(avg) * np.linalg.norm(embedding) + 1e-8
        )

        is_match = similarity >= VERIFICATION_THRESHOLD
        confidence = min(1.0, max(0.0, (similarity - 0.5) / 0.5))

        return is_match, confidence

    def is_ready(self) -> bool:
        """Check if profile has enough samples for reliable verification."""
        return self.total_duration >= MIN_ENROLLMENT_DURATION and len(self.embeddings) >= 5

    def get_quality_score(self) -> float:
        """Get a quality score for the profile (0-1)."""
        if not self.embeddings:
            return 0.0

        # Based on duration and sample consistency
        duration_score = min(1.0, self.total_duration / 60.0)  # Max at 60s

        # Check embedding consistency (lower std = better)
        if len(self.embeddings) > 1:
            stacked = np.stack(self.embeddings)
            std_score = 1.0 - min(1.0, np.mean(np.std(stacked, axis=0)))
        else:
            std_score = 0.5

        return (duration_score * 0.6 + std_score * 0.4)

    def to_dict(self) -> dict:
        """Serialize profile to dictionary."""
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
        """Deserialize profile from dictionary."""
        profile = cls(data['name'], data['profile_id'])
        profile.embeddings = [np.array(e) for e in data['embeddings']]
        profile.total_duration = data['total_duration']
        profile.created_at = data.get('created_at')
        profile.sample_count = data.get('sample_count', len(profile.embeddings))
        return profile


class VoiceProfileManager:
    """Manages voice profiles including enrollment and verification."""

    def __init__(self):
        self._model = None
        self._model_lock = threading.Lock()
        self._model_loaded = False
        self._current_profile: Optional[VoiceProfile] = None
        self._enrollment_buffer: List[np.ndarray] = []
        self._is_enrolling = False

        # Ensure profiles directory exists
        PROFILES_DIR.mkdir(parents=True, exist_ok=True)

    def _load_model(self) -> bool:
        """Load the speaker embedding model."""
        if self._model_loaded:
            return self._model is not None

        with self._model_lock:
            if self._model_loaded:
                return self._model is not None

            try:
                from speechbrain.inference.speaker import EncoderClassifier

                model_dir = Path(__file__).parent.parent / "models" / "speaker_model"
                model_dir.mkdir(parents=True, exist_ok=True)

                # Use MPS (Metal) on Apple Silicon if available
                import torch
                if torch.backends.mps.is_available():
                    device = "mps"
                    print("Using Apple Silicon Neural Engine (MPS)")
                else:
                    device = "cpu"

                self._model = EncoderClassifier.from_hparams(
                    source="speechbrain/spkrec-ecapa-voxceleb",
                    savedir=str(model_dir),
                    run_opts={"device": device}
                )
                self._model_loaded = True
                print(f"Voice profile model loaded on {device}")
                return True

            except Exception as e:
                print(f"Failed to load speaker model: {e}")
                self._model_loaded = True
                return False

    def _extract_embedding(self, audio: np.ndarray) -> Optional[np.ndarray]:
        """Extract speaker embedding from audio."""
        if not self._load_model() or self._model is None:
            return None

        try:
            import torch

            # Normalize audio
            if audio.dtype != np.float32:
                audio = audio.astype(np.float32)

            if np.max(np.abs(audio)) > 1.0:
                audio = audio / (np.max(np.abs(audio)) + 1e-8)

            audio_tensor = torch.tensor(audio).unsqueeze(0)

            with torch.no_grad():
                embedding = self._model.encode_batch(audio_tensor)
                return embedding.squeeze().cpu().numpy()

        except Exception as e:
            print(f"Embedding extraction error: {e}")
            return None

    # ==================== Enrollment ====================

    def start_enrollment(self, teacher_name: str) -> str:
        """Start the enrollment process for a new teacher profile."""
        from datetime import datetime

        self._current_profile = VoiceProfile(teacher_name)
        self._current_profile.created_at = datetime.now().isoformat()
        self._enrollment_buffer = []
        self._is_enrolling = True

        return self._current_profile.profile_id

    def add_enrollment_audio(self, audio: np.ndarray) -> dict:
        """
        Add audio chunk during enrollment.
        Returns status dict with progress info.
        """
        if not self._is_enrolling or self._current_profile is None:
            return {'error': 'Not in enrollment mode'}

        # Extract embedding
        embedding = self._extract_embedding(audio)
        if embedding is None:
            return {
                'status': 'processing',
                'message': 'Audio processed (model loading...)',
                'duration': self._current_profile.total_duration,
                'is_ready': False
            }

        # Add to profile
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
        """Complete enrollment and save the profile."""
        if not self._is_enrolling or self._current_profile is None:
            return {'error': 'Not in enrollment mode'}

        if not self._current_profile.is_ready():
            return {
                'error': 'Not enough audio samples',
                'duration': self._current_profile.total_duration,
                'required': MIN_ENROLLMENT_DURATION
            }

        # Save profile
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
        """Cancel ongoing enrollment."""
        self._is_enrolling = False
        self._current_profile = None
        self._enrollment_buffer = []

    # ==================== Verification ====================

    def load_profile(self, profile_id: str) -> bool:
        """Load a saved profile for verification."""
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
        """
        Verify if audio matches the current profile.
        Returns (is_teacher, confidence).
        """
        if self._current_profile is None:
            return True, 0.5  # No profile = accept all

        embedding = self._extract_embedding(audio)
        if embedding is None:
            return True, 0.5  # Can't verify = accept

        return self._current_profile.verify(embedding)

    def is_teacher_speaking(self, audio: np.ndarray) -> bool:
        """Simple check if audio is from the enrolled teacher."""
        is_match, confidence = self.verify_audio(audio)
        return is_match and confidence >= 0.4

    # ==================== Profile Management ====================

    def list_profiles(self) -> List[dict]:
        """List all saved profiles."""
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
        """Delete a saved profile."""
        profile_path = PROFILES_DIR / f"{profile_id}.json"

        if profile_path.exists():
            profile_path.unlink()
            if self._current_profile and self._current_profile.profile_id == profile_id:
                self._current_profile = None
            return True
        return False

    def get_current_profile(self) -> Optional[dict]:
        """Get info about the currently loaded profile."""
        if self._current_profile is None:
            return None

        return {
            'profile_id': self._current_profile.profile_id,
            'name': self._current_profile.name,
            'is_ready': self._current_profile.is_ready(),
            'quality_score': self._current_profile.get_quality_score()
        }


# Global instance
_profile_manager: Optional[VoiceProfileManager] = None


def get_profile_manager() -> VoiceProfileManager:
    """Get the global profile manager instance."""
    global _profile_manager
    if _profile_manager is None:
        _profile_manager = VoiceProfileManager()
    return _profile_manager


def verify_teacher_audio(audio: np.ndarray) -> Tuple[bool, float]:
    """Verify if audio is from the enrolled teacher."""
    return get_profile_manager().verify_audio(audio)


def is_teacher_audio(audio: np.ndarray) -> bool:
    """Check if audio is from the enrolled teacher."""
    return get_profile_manager().is_teacher_speaking(audio)
