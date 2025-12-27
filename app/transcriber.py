"""
Transcriber Module for Voice Notes
===================================

Handles speech-to-text transcription with:
- Fast Whisper models for real-time and accurate transcription
- Speaker diarization to identify teacher vs students
- AI-powered context-aware text correction
- Shows transcription ONLY after correction is complete
"""

from faster_whisper import WhisperModel
import os
import numpy as np
import warnings
from typing import Optional, Dict, List
import threading

warnings.filterwarnings("ignore")

# Whisper model settings
_fast_model = None  # base - for chunk transcription
_accurate_model = None  # small - for final transcription
FAST_MODEL_NAME = "base"
ACCURATE_MODEL_NAME = "small"

# Import our new modules
from speaker_diarization import get_diarizer, is_teacher_audio, reset_speaker_tracking
from ai_corrector import get_corrector, correct_transcription, get_ai_status


def get_fast_model():
    """Get the fast Whisper model."""
    global _fast_model
    if _fast_model is None:
        print(f"Loading Whisper '{FAST_MODEL_NAME}' model...")
        _fast_model = WhisperModel(FAST_MODEL_NAME, device="cpu", compute_type="int8")
        print("Fast model ready")
    return _fast_model


def get_accurate_model():
    """Get the accurate Whisper model."""
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
    apply_correction: bool = True,
    subject: Optional[str] = None
) -> Optional[str]:
    """
    Transcribe an audio chunk with speaker filtering and correction.

    IMPORTANT: Returns text ONLY after AI correction is applied.
    This ensures the user sees clean, corrected text.

    Args:
        audio_data: Audio samples (float32)
        sample_rate: Sample rate
        filter_non_teacher: If True, skip non-teacher audio
        apply_correction: If True, apply AI correction before returning
        subject: Optional subject context for better correction

    Returns:
        Corrected transcription text, or None if filtered out
    """
    # Ensure correct format
    if audio_data.dtype != np.float32:
        audio_data = audio_data.astype(np.float32)

    if len(audio_data) > 0 and np.max(np.abs(audio_data)) > 1.0:
        audio_data = audio_data / 32768.0

    # Check if this is teacher speaking
    if filter_non_teacher:
        diarizer = get_diarizer()
        diarizer.sample_rate = sample_rate
        is_teacher, confidence = diarizer.process_audio_chunk(audio_data)

        if not is_teacher:
            # Skip non-teacher audio
            return None

    # Transcribe with fast model
    model = get_fast_model()

    try:
        segments, info = model.transcribe(
            audio_data,
            language=None,
            vad_filter=True,
            beam_size=1,
            best_of=1,
        )

        text_parts = [seg.text.strip() for seg in segments]
        raw_text = ' '.join(text_parts)

        if not raw_text.strip():
            return None

        # Apply AI correction BEFORE returning
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
    """
    Transcribe a complete audio file with full processing pipeline.

    Args:
        audio_path: Path to audio file
        subject: Optional subject context (e.g., "Mathe", "Physik")
        apply_correction: Whether to apply AI correction

    Returns:
        Result dict with transcription and metadata
    """
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

        # Transcribe with VAD filtering
        segments, info = model.transcribe(
            audio_path,
            language=None,
            vad_filter=True,
            vad_parameters=dict(
                min_silence_duration_ms=500,
                speech_pad_ms=200,
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

        # Apply AI correction
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
    """Delete a temporary audio file."""
    try:
        if os.path.exists(audio_path):
            os.remove(audio_path)
            return True
        return False
    except Exception as e:
        print(f"Error deleting audio file: {e}")
        return False


def get_available_models() -> List[Dict]:
    """Get list of available Whisper models."""
    return [
        {'name': 'base', 'description': 'Fast (real-time chunks)', 'size': '~150 MB'},
        {'name': 'small', 'description': 'Accurate (final transcription)', 'size': '~500 MB'},
        {'name': 'medium', 'description': 'High accuracy', 'size': '~1.5 GB'},
        {'name': 'large-v3', 'description': 'Best accuracy', 'size': '~3 GB'}
    ]


def preload_model(model_name: str = "base"):
    """Preload models at startup."""
    get_fast_model()
    # Also initialize the AI corrector in background
    threading.Thread(target=lambda: get_corrector().is_ai_available(), daemon=True).start()


def get_ollama_status() -> Dict:
    """Get Ollama status (deprecated, kept for compatibility)."""
    return {
        'available': False,
        'model': None,
        'message': 'Ollama replaced by faster local AI (MLX)'
    }


def get_correction_status() -> Dict:
    """Get AI correction status."""
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
    """Reset transcription session (call when starting new recording)."""
    reset_speaker_tracking()
