"""
Speaker Diarization Module for Voice Notes
==========================================

Identifies and tracks different speakers (teacher vs students) by analyzing
voice characteristics from audio waveforms.

Uses speaker embeddings to create voice "fingerprints" and clusters them
to identify the dominant speaker (teacher).
"""

import numpy as np
from collections import deque
from typing import Optional, Tuple, List, Dict
import threading

# Speaker identification settings
EMBEDDING_DIM = 192  # ECAPA-TDNN embedding dimension
MIN_SPEECH_DURATION = 0.5  # Minimum seconds to extract embedding
TEACHER_CONFIRMATION_COUNT = 3  # Number of times a speaker must be dominant
SIMILARITY_THRESHOLD = 0.75  # Cosine similarity threshold for same speaker
TEACHER_DOMINANCE_RATIO = 0.6  # Teacher should speak > 60% of the time

# Voice characteristics for heuristic detection
TEACHER_FREQ_RANGE = (85, 300)  # Typical adult voice fundamental frequency
STUDENT_FREQ_RANGE = (150, 400)  # Children/teens have higher pitch


class SpeakerProfile:
    """Represents a unique speaker's voice profile."""

    def __init__(self, speaker_id: int, embedding: np.ndarray):
        self.id = speaker_id
        self.embeddings: List[np.ndarray] = [embedding]
        self.speak_count = 1
        self.total_duration = 0.0
        self.is_teacher = False

    def add_embedding(self, embedding: np.ndarray, duration: float):
        """Add a new embedding sample for this speaker."""
        self.embeddings.append(embedding)
        self.speak_count += 1
        self.total_duration += duration
        # Keep only last 20 embeddings for memory efficiency
        if len(self.embeddings) > 20:
            self.embeddings.pop(0)

    def get_average_embedding(self) -> np.ndarray:
        """Get the average embedding for this speaker."""
        return np.mean(self.embeddings, axis=0)

    def similarity(self, embedding: np.ndarray) -> float:
        """Calculate cosine similarity with a new embedding."""
        avg = self.get_average_embedding()
        return np.dot(avg, embedding) / (np.linalg.norm(avg) * np.linalg.norm(embedding) + 1e-8)


class SpeakerDiarizer:
    """
    Analyzes audio to identify different speakers and determine which is the teacher.

    The algorithm:
    1. Extract speaker embeddings from audio chunks using ECAPA-TDNN
    2. Cluster embeddings to identify unique speakers
    3. Track speaking time per speaker
    4. Identify the dominant speaker (most speaking time) as teacher
    5. Filter out non-teacher speech from transcription
    """

    def __init__(self, sample_rate: int = 16000):
        self.sample_rate = sample_rate
        self.speakers: Dict[int, SpeakerProfile] = {}
        self.next_speaker_id = 0
        self.teacher_id: Optional[int] = None
        self.teacher_confirmed = False
        self._model = None
        self._model_lock = threading.Lock()
        self._model_loaded = False

        # Fallback: frequency-based detection when model unavailable
        self.use_frequency_fallback = False
        self.frequency_history = deque(maxlen=50)

    def _load_model(self):
        """Lazy load the speaker embedding model."""
        if self._model_loaded:
            return self._model is not None

        with self._model_lock:
            if self._model_loaded:
                return self._model is not None

            try:
                from speechbrain.inference.speaker import EncoderClassifier
                import os

                model_dir = os.path.expanduser("~/Documents/voice-notes/models/speaker_model")
                self._model = EncoderClassifier.from_hparams(
                    source="speechbrain/spkrec-ecapa-voxceleb",
                    savedir=model_dir,
                    run_opts={"device": "cpu"}
                )
                self._model_loaded = True
                print("Speaker diarization model loaded")
                return True
            except Exception as e:
                print(f"Speaker model unavailable, using frequency fallback: {e}")
                self.use_frequency_fallback = True
                self._model_loaded = True
                return False

    def _extract_embedding(self, audio: np.ndarray) -> Optional[np.ndarray]:
        """Extract speaker embedding from audio using ECAPA-TDNN."""
        if not self._load_model() or self._model is None:
            return None

        try:
            import torch

            # Ensure audio is the right format
            if audio.dtype != np.float32:
                audio = audio.astype(np.float32)

            # Normalize
            if np.max(np.abs(audio)) > 1.0:
                audio = audio / np.max(np.abs(audio))

            # Convert to tensor
            audio_tensor = torch.tensor(audio).unsqueeze(0)

            # Extract embedding
            with torch.no_grad():
                embedding = self._model.encode_batch(audio_tensor)
                return embedding.squeeze().numpy()

        except Exception as e:
            print(f"Embedding extraction error: {e}")
            return None

    def _estimate_fundamental_frequency(self, audio: np.ndarray) -> float:
        """Estimate fundamental frequency (F0) using autocorrelation."""
        try:
            # High-pass filter to remove DC offset
            audio = audio - np.mean(audio)

            # Autocorrelation
            corr = np.correlate(audio, audio, mode='full')
            corr = corr[len(corr)//2:]

            # Find first peak after initial decay
            min_lag = int(self.sample_rate / 400)  # Max 400Hz
            max_lag = int(self.sample_rate / 75)   # Min 75Hz

            if max_lag > len(corr):
                max_lag = len(corr) - 1

            # Find the peak in the valid range
            search_range = corr[min_lag:max_lag]
            if len(search_range) == 0:
                return 0.0

            peak_idx = np.argmax(search_range) + min_lag

            if peak_idx > 0:
                f0 = self.sample_rate / peak_idx
                return f0
            return 0.0

        except Exception:
            return 0.0

    def _find_matching_speaker(self, embedding: np.ndarray) -> Optional[int]:
        """Find a speaker that matches the given embedding."""
        best_match = None
        best_similarity = SIMILARITY_THRESHOLD

        for speaker_id, profile in self.speakers.items():
            sim = profile.similarity(embedding)
            if sim > best_similarity:
                best_similarity = sim
                best_match = speaker_id

        return best_match

    def _update_teacher_detection(self):
        """Determine which speaker is the teacher based on dominance."""
        if len(self.speakers) == 0:
            return

        # Find speaker with most speaking time
        max_duration = 0
        total_duration = 0
        dominant_speaker = None

        for speaker_id, profile in self.speakers.items():
            total_duration += profile.total_duration
            if profile.total_duration > max_duration:
                max_duration = profile.total_duration
                dominant_speaker = speaker_id

        if dominant_speaker is None or total_duration == 0:
            return

        # Check if dominant speaker meets threshold
        dominance_ratio = max_duration / total_duration

        if dominance_ratio >= TEACHER_DOMINANCE_RATIO:
            if self.teacher_id != dominant_speaker:
                self.teacher_id = dominant_speaker
                self.speakers[dominant_speaker].is_teacher = True

                # Mark others as not teacher
                for sid, profile in self.speakers.items():
                    if sid != dominant_speaker:
                        profile.is_teacher = False

    def process_audio_chunk(self, audio: np.ndarray) -> Tuple[bool, float]:
        """
        Process an audio chunk and determine if it's the teacher speaking.

        Args:
            audio: Audio samples (float32, mono)

        Returns:
            Tuple of (is_teacher, confidence)
        """
        duration = len(audio) / self.sample_rate

        if duration < MIN_SPEECH_DURATION:
            return False, 0.0

        # Use frequency-based fallback if model unavailable
        if self.use_frequency_fallback:
            return self._process_with_frequency(audio)

        # Extract speaker embedding
        embedding = self._extract_embedding(audio)

        if embedding is None:
            # Fallback to frequency analysis
            return self._process_with_frequency(audio)

        # Find or create speaker profile
        speaker_id = self._find_matching_speaker(embedding)

        if speaker_id is None:
            # New speaker
            speaker_id = self.next_speaker_id
            self.next_speaker_id += 1
            self.speakers[speaker_id] = SpeakerProfile(speaker_id, embedding)
        else:
            # Existing speaker
            self.speakers[speaker_id].add_embedding(embedding, duration)

        # Update teacher detection
        self._update_teacher_detection()

        # Check if this is the teacher
        is_teacher = (speaker_id == self.teacher_id)

        # Calculate confidence
        if is_teacher and self.teacher_id is not None:
            profile = self.speakers[self.teacher_id]
            confidence = min(1.0, profile.speak_count / TEACHER_CONFIRMATION_COUNT)
        else:
            confidence = 0.5  # Uncertain

        return is_teacher, confidence

    def _process_with_frequency(self, audio: np.ndarray) -> Tuple[bool, float]:
        """Fallback: Use frequency analysis to detect teacher voice."""
        f0 = self._estimate_fundamental_frequency(audio)

        if f0 == 0:
            return False, 0.0

        self.frequency_history.append(f0)

        # Teacher typically has lower, more consistent pitch
        if len(self.frequency_history) < 5:
            # Not enough data yet - assume teacher
            return True, 0.5

        avg_f0 = np.mean(list(self.frequency_history))
        std_f0 = np.std(list(self.frequency_history))

        # Teacher criteria: lower pitch, consistent
        is_lower_pitch = TEACHER_FREQ_RANGE[0] <= f0 <= TEACHER_FREQ_RANGE[1]
        is_consistent = std_f0 < 50  # Low variance

        # Higher volume (RMS) often indicates teacher projecting voice
        rms = np.sqrt(np.mean(audio ** 2))
        is_loud = rms > 0.02

        if is_lower_pitch and is_consistent and is_loud:
            return True, 0.8
        elif is_lower_pitch and is_loud:
            return True, 0.6
        elif is_loud:
            return True, 0.4
        else:
            return False, 0.3

    def is_teacher_speaking(self, audio: np.ndarray) -> bool:
        """Simple check if the audio is likely the teacher speaking."""
        is_teacher, confidence = self.process_audio_chunk(audio)
        return is_teacher and confidence >= 0.4

    def get_speaker_stats(self) -> Dict:
        """Get statistics about detected speakers."""
        stats = {
            'num_speakers': len(self.speakers),
            'teacher_id': self.teacher_id,
            'teacher_confirmed': self.teacher_confirmed,
            'speakers': []
        }

        for speaker_id, profile in self.speakers.items():
            stats['speakers'].append({
                'id': speaker_id,
                'speak_count': profile.speak_count,
                'total_duration': round(profile.total_duration, 1),
                'is_teacher': profile.is_teacher
            })

        return stats

    def reset(self):
        """Reset speaker tracking for a new recording session."""
        self.speakers.clear()
        self.next_speaker_id = 0
        self.teacher_id = None
        self.teacher_confirmed = False
        self.frequency_history.clear()


# Global diarizer instance
_diarizer: Optional[SpeakerDiarizer] = None


def get_diarizer() -> SpeakerDiarizer:
    """Get or create the global speaker diarizer."""
    global _diarizer
    if _diarizer is None:
        _diarizer = SpeakerDiarizer()
    return _diarizer


def is_teacher_audio(audio: np.ndarray, sample_rate: int = 16000) -> bool:
    """
    Convenience function to check if audio is from the teacher.

    Args:
        audio: Audio samples
        sample_rate: Sample rate of audio

    Returns:
        True if audio is likely from the teacher
    """
    diarizer = get_diarizer()
    if diarizer.sample_rate != sample_rate:
        diarizer.sample_rate = sample_rate
    return diarizer.is_teacher_speaking(audio)


def reset_speaker_tracking():
    """Reset speaker tracking for a new session."""
    global _diarizer
    if _diarizer is not None:
        _diarizer.reset()
