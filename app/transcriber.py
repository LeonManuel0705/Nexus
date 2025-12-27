from faster_whisper import WhisperModel
import os
import numpy as np
import warnings
from typing import Optional, Dict, List
import threading

warnings.filterwarnings("ignore")

_fast_model = None
_accurate_model = None
FAST_MODEL_NAME = "tiny"
ACCURATE_MODEL_NAME = "base"

from speaker_diarization import get_diarizer, reset_speaker_tracking
from ai_corrector import get_corrector, correct_transcription, get_ai_status


def get_fast_model():
    global _fast_model
    if _fast_model is None:
        print(f"Loading Whisper '{FAST_MODEL_NAME}' model...")
        _fast_model = WhisperModel(FAST_MODEL_NAME, device="cpu", compute_type="int8")
        print("Fast model ready")
    return _fast_model


def get_accurate_model():
    global _accurate_model
    if _accurate_model is None:
        print(f"Loading Whisper '{ACCURATE_MODEL_NAME}' model...")
        _accurate_model = WhisperModel(ACCURATE_MODEL_NAME, device="cpu", compute_type="int8")
        print("Accurate model ready")
    return _accurate_model


def transcribe_audio_chunk(
    audio_data: np.ndarray,
    sample_rate: int = 16000,
    filter_non_teacher: bool = True,
    apply_correction: bool = False,
    subject: Optional[str] = None
) -> Optional[str]:
    if audio_data.dtype != np.float32:
        audio_data = audio_data.astype(np.float32)

    if len(audio_data) > 0 and np.max(np.abs(audio_data)) > 1.0:
        audio_data = audio_data / 32768.0

    if filter_non_teacher:
        diarizer = get_diarizer()
        diarizer.sample_rate = sample_rate
        is_teacher, confidence = diarizer.process_audio_chunk(audio_data)
        if not is_teacher:
            return None

    model = get_fast_model()

    try:
        segments, info = model.transcribe(
            audio_data,
            language=None,
            vad_filter=True,
            beam_size=1,
            best_of=1,
            without_timestamps=True,
            condition_on_previous_text=False,
        )

        text_parts = [seg.text.strip() for seg in segments]
        raw_text = ' '.join(text_parts)

        if not raw_text.strip():
            return None

        if apply_correction:
            corrected = correct_transcription(raw_text, subject, info.language)
            return corrected if corrected.strip() else None

        return raw_text

    except Exception as e:
        print(f"Transcription error: {e}")
        return None


def transcribe_audio(
    audio_path: str,
    subject: Optional[str] = None,
    apply_correction: bool = True
) -> Dict:
    if not os.path.exists(audio_path):
        return {
            'success': False,
            'error': f"Audio file not found: {audio_path}",
            'text': '',
            'language': None,
            'segments': []
        }

    try:
        model = get_accurate_model()

        segments, info = model.transcribe(
            audio_path,
            language=None,
            vad_filter=True,
            vad_parameters=dict(
                min_silence_duration_ms=300,
                speech_pad_ms=100,
            )
        )

        all_segments = []
        full_text = []

        for seg in segments:
            all_segments.append({
                'start': seg.start,
                'end': seg.end,
                'text': seg.text.strip()
            })
            full_text.append(seg.text.strip())

        raw_text = ' '.join(full_text)

        if apply_correction and raw_text:
            corrector = get_corrector()
            corrected_text, used_ai = corrector.correct(
                raw_text,
                subject=subject,
                language=info.language
            )
        else:
            corrected_text = raw_text
            used_ai = False

        return {
            'success': True,
            'text': corrected_text,
            'raw_text': raw_text,
            'language': info.language,
            'segments': all_segments,
            'used_ai_correction': used_ai,
            'error': None
        }

    except Exception as e:
        return {
            'success': False,
            'error': str(e),
            'text': '',
            'language': None,
            'segments': []
        }


def cleanup_audio_file(audio_path: str) -> bool:
    try:
        if os.path.exists(audio_path):
            os.remove(audio_path)
            return True
        return False
    except Exception as e:
        print(f"Error deleting audio file: {e}")
        return False


def get_available_models() -> List[Dict]:
    return [
        {'name': 'tiny', 'description': 'Ultra-fast (real-time)', 'size': '~75 MB'},
        {'name': 'base', 'description': 'Fast and accurate', 'size': '~150 MB'},
        {'name': 'small', 'description': 'High accuracy', 'size': '~500 MB'},
        {'name': 'medium', 'description': 'Very high accuracy', 'size': '~1.5 GB'},
    ]


def preload_model(model_name: str = "tiny"):
    get_fast_model()
    threading.Thread(target=lambda: get_corrector().is_ai_available(), daemon=True).start()


def get_ollama_status() -> Dict:
    return {
        'available': False,
        'model': None,
        'message': 'Ollama replaced by faster local AI (MLX)'
    }


def get_correction_status() -> Dict:
    ai_status = get_ai_status()
    diarizer = get_diarizer()
    speaker_stats = diarizer.get_speaker_stats()

    return {
        'ai_correction': ai_status,
        'speaker_diarization': {
            'num_speakers': speaker_stats['num_speakers'],
            'teacher_detected': speaker_stats['teacher_id'] is not None
        }
    }


def reset_session():
    reset_speaker_tracking()
