import numpy as np
from collections import deque
from typing import Optional, Tuple, List, Dict
import threading

EMBEDDING_DIM = 192
MIN_SPEECH_DURATION = 0.5
TEACHER_CONFIRMATION_COUNT = 3
SIMILARITY_THRESHOLD = 0.75
TEACHER_DOMINANCE_RATIO = 0.6

TEACHER_FREQ_RANGE = (85, 300)
STUDENT_FREQ_RANGE = (150, 400)


class SpeakerProfile:
    def __init__(self, speaker_id: int, embedding: np.ndarray):
        self.id = speaker_id
        self.embeddings: List[np.ndarray] = [embedding]
        self.speak_count = 1
        self.total_duration = 0.0
        self.is_teacher = False

    def add_embedding(self, embedding: np.ndarray, duration: float):
        self.embeddings.append(embedding)
        self.speak_count += 1
        self.total_duration += duration
        if len(self.embeddings) > 20:
            self.embeddings.pop(0)

    def get_average_embedding(self) -> np.ndarray:
        return np.mean(self.embeddings, axis=0)

    def similarity(self, embedding: np.ndarray) -> float:
        avg = self.get_average_embedding()
        return np.dot(avg, embedding) / (np.linalg.norm(avg) * np.linalg.norm(embedding) + 1e-8)


class SpeakerDiarizer:
    def __init__(self, sample_rate: int = 16000):
        self.sample_rate = sample_rate
        self.speakers: Dict[int, SpeakerProfile] = {}
        self.next_speaker_id = 0
        self.teacher_id: Optional[int] = None
        self.teacher_confirmed = False
        self._model = None
        self._model_lock = threading.Lock()
        self._model_loaded = False

        self.use_frequency_fallback = False
        self.frequency_history = deque(maxlen=50)

    def _load_model(self):
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
        if not self._load_model() or self._model is None:
            return None

        try:
            import torch

            if audio.dtype != np.float32:
                audio = audio.astype(np.float32)

            if np.max(np.abs(audio)) > 1.0:
                audio = audio / np.max(np.abs(audio))

            audio_tensor = torch.tensor(audio).unsqueeze(0)

            with torch.no_grad():
                embedding = self._model.encode_batch(audio_tensor)
                return embedding.squeeze().numpy()

        except Exception as e:
            print(f"Embedding extraction error: {e}")
            return None

    def _estimate_fundamental_frequency(self, audio: np.ndarray) -> float:
        try:
            audio = audio - np.mean(audio)

            corr = np.correlate(audio, audio, mode='full')
            corr = corr[len(corr)//2:]

            min_lag = int(self.sample_rate / 400)
            max_lag = int(self.sample_rate / 75)

            if max_lag > len(corr):
                max_lag = len(corr) - 1

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
        best_match = None
        best_similarity = SIMILARITY_THRESHOLD

        for speaker_id, profile in self.speakers.items():
            sim = profile.similarity(embedding)
            if sim > best_similarity:
                best_similarity = sim
                best_match = speaker_id

        return best_match

    def _update_teacher_detection(self):
        if len(self.speakers) == 0:
            return

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

        dominance_ratio = max_duration / total_duration

        if dominance_ratio >= TEACHER_DOMINANCE_RATIO:
            if self.teacher_id != dominant_speaker:
                self.teacher_id = dominant_speaker
                self.speakers[dominant_speaker].is_teacher = True

                for sid, profile in self.speakers.items():
                    if sid != dominant_speaker:
                        profile.is_teacher = False

    def process_audio_chunk(self, audio: np.ndarray) -> Tuple[bool, float]:
        duration = len(audio) / self.sample_rate

        if duration < MIN_SPEECH_DURATION:
            return False, 0.0

        if self.use_frequency_fallback:
            return self._process_with_frequency(audio)

        embedding = self._extract_embedding(audio)

        if embedding is None:
            return self._process_with_frequency(audio)

        speaker_id = self._find_matching_speaker(embedding)

        if speaker_id is None:
            speaker_id = self.next_speaker_id
            self.next_speaker_id += 1
            self.speakers[speaker_id] = SpeakerProfile(speaker_id, embedding)
        else:
            self.speakers[speaker_id].add_embedding(embedding, duration)

        self._update_teacher_detection()

        is_teacher = (speaker_id == self.teacher_id)

        if is_teacher and self.teacher_id is not None:
            profile = self.speakers[self.teacher_id]
            confidence = min(1.0, profile.speak_count / TEACHER_CONFIRMATION_COUNT)
        else:
            confidence = 0.5

        return is_teacher, confidence

    def _process_with_frequency(self, audio: np.ndarray) -> Tuple[bool, float]:
        f0 = self._estimate_fundamental_frequency(audio)

        if f0 == 0:
            return False, 0.0

        self.frequency_history.append(f0)

        if len(self.frequency_history) < 5:
            return True, 0.5

        avg_f0 = np.mean(list(self.frequency_history))
        std_f0 = np.std(list(self.frequency_history))

        is_lower_pitch = TEACHER_FREQ_RANGE[0] <= f0 <= TEACHER_FREQ_RANGE[1]
        is_consistent = std_f0 < 50

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
        is_teacher, confidence = self.process_audio_chunk(audio)
        return is_teacher and confidence >= 0.4

    def get_speaker_stats(self) -> Dict:
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
        self.speakers.clear()
        self.next_speaker_id = 0
        self.teacher_id = None
        self.teacher_confirmed = False
        self.frequency_history.clear()


_diarizer: Optional[SpeakerDiarizer] = None


def get_diarizer() -> SpeakerDiarizer:
    global _diarizer
    if _diarizer is None:
        _diarizer = SpeakerDiarizer()
    return _diarizer


def is_teacher_audio(audio: np.ndarray, sample_rate: int = 16000) -> bool:
    diarizer = get_diarizer()
    if diarizer.sample_rate != sample_rate:
        diarizer.sample_rate = sample_rate
    return diarizer.is_teacher_speaking(audio)


def reset_speaker_tracking():
    global _diarizer
    if _diarizer is not None:
        _diarizer.reset()
