from faster_whisper import WhisperModel
import os
import numpy as np
import warnings
from typing import Optional, Dict, List, Tuple
import threading
import re
from collections import deque

warnings.filterwarnings("ignore")

_realtime_model = None
_accurate_model = None
_model_lock = threading.Lock()

REALTIME_MODEL = "small"
ACCURATE_MODEL = "medium"


class RealtimeTranscriber:
    def __init__(self, language: str = "de"):
        self.language = language
        self.model = None
        self.audio_buffer = deque(maxlen=10)
        self.context_text = ""
        self.last_transcription = ""

    def load_model(self):
        global _realtime_model
        with _model_lock:
            if _realtime_model is None:
                print(f"Loading Whisper '{REALTIME_MODEL}' for real-time...")
                _realtime_model = WhisperModel(
                    REALTIME_MODEL,
                    device="cpu",
                    compute_type="int8",
                    num_workers=2
                )
                print("Real-time model ready")
            self.model = _realtime_model

    def transcribe_chunk(self, audio_data: np.ndarray, sample_rate: int = 16000) -> Tuple[str, float]:
        if self.model is None:
            self.load_model()

        if audio_data.dtype != np.float32:
            audio_data = audio_data.astype(np.float32)

        if len(audio_data) > 0:
            max_val = np.max(np.abs(audio_data))
            if max_val > 1.0:
                audio_data = audio_data / max_val
            elif max_val < 0.01:
                return "", 0.0

        audio_data = self._preprocess_audio(audio_data, sample_rate)

        try:
            segments, info = self.model.transcribe(
                audio_data,
                language=self.language,
                task="transcribe",
                beam_size=3,
                best_of=3,
                patience=1.0,
                condition_on_previous_text=True,
                initial_prompt=self.context_text[-200:] if self.context_text else None,
                vad_filter=True,
                vad_parameters={
                    "threshold": 0.3,
                    "min_speech_duration_ms": 250,
                    "min_silence_duration_ms": 100,
                    "speech_pad_ms": 50,
                },
                word_timestamps=False,
                without_timestamps=True,
            )

            text_parts = []
            for seg in segments:
                text = seg.text.strip()
                if text:
                    text_parts.append(text)

            raw_text = ' '.join(text_parts)

            if raw_text:
                self.context_text += " " + raw_text
                if len(self.context_text) > 500:
                    self.context_text = self.context_text[-500:]

            confidence = info.language_probability if hasattr(info, 'language_probability') else 0.9

            return raw_text, confidence

        except Exception as e:
            print(f"Transcription error: {e}")
            return "", 0.0

    def _preprocess_audio(self, audio: np.ndarray, sample_rate: int) -> np.ndarray:
        if sample_rate != 16000:
            from scipy import signal
            num_samples = int(len(audio) * 16000 / sample_rate)
            audio = signal.resample(audio, num_samples)

        audio = audio - np.mean(audio)

        max_val = np.max(np.abs(audio))
        if max_val > 0:
            audio = audio / max_val * 0.95

        return audio

    def reset(self):
        self.context_text = ""
        self.last_transcription = ""
        self.audio_buffer.clear()


class TextCorrector:
    def __init__(self, language: str = "de"):
        self.language = language
        self.corrections_cache = {}
        self._init_patterns()

    def _init_patterns(self):
        self.filler_patterns = {
            "de": [
                (r'\b(ähm?|öhm?|hmm?|hm)\b', ''),
                (r'\b(also\s+ja|ja\s+also)\b', ''),
                (r'\b(sozusagen|quasi|halt|eben)\b', ''),
                (r'\b(ich\s+meine?)\s*,?\s*', ''),
            ],
            "en": [
                (r'\b(um+|uh+|er+|hmm?)\b', ''),
                (r'\b(you\s+know|i\s+mean|like)\b', ''),
                (r'\b(basically|actually|literally)\b', ''),
            ]
        }

        self.common_errors = {
            "de": {
                r'\bdas\s+das\b': 'das',
                r'\bund\s+und\b': 'und',
                r'\bist\s+ist\b': 'ist',
                r'\bein\s+ein\b': 'ein',
                r'\bdie\s+die\b': 'die',
                r'\bder\s+der\b': 'der',
                r'\bzu\s+zu\b': 'zu',
                r'\bso\s+so\b': 'so',
                r'\bwir\s+wir\b': 'wir',
                r'\bsie\s+sie\b': 'sie',
            },
            "en": {
                r'\bthe\s+the\b': 'the',
                r'\band\s+and\b': 'and',
                r'\bis\s+is\b': 'is',
                r'\ba\s+a\b': 'a',
                r'\bto\s+to\b': 'to',
                r'\bof\s+of\b': 'of',
            }
        }

        self.sentence_starters = {
            "de": ['Der', 'Die', 'Das', 'Ein', 'Eine', 'Wir', 'Sie', 'Es', 'Ich', 'Man', 'Also', 'Wenn', 'Als', 'Nach', 'Bei', 'Für', 'Mit', 'Durch', 'Über', 'Unter'],
            "en": ['The', 'A', 'An', 'We', 'They', 'It', 'I', 'You', 'This', 'That', 'When', 'If', 'As', 'For', 'With', 'From', 'To', 'In', 'On', 'At']
        }

    def correct_instant(self, text: str) -> str:
        if not text or not text.strip():
            return text

        lang = self.language[:2]

        for pattern, replacement in self.filler_patterns.get(lang, []):
            text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)

        for pattern, replacement in self.common_errors.get(lang, {}).items():
            text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)

        text = re.sub(r'\s+', ' ', text).strip()
        text = re.sub(r'\s+([.,!?;:])', r'\1', text)
        text = re.sub(r'([.,!?;:])\s*([.,!?;:])+', r'\1', text)

        if text and not text[0].isupper():
            text = text[0].upper() + text[1:]

        sentences = re.split(r'([.!?]\s+)', text)
        result = []
        for i, part in enumerate(sentences):
            if i > 0 and re.match(r'^[.!?]\s+$', sentences[i-1] if i > 0 else ''):
                if part and part[0].islower():
                    part = part[0].upper() + part[1:]
            result.append(part)
        text = ''.join(result)

        return text

    def correct_full(self, text: str, context: Optional[str] = None) -> str:
        text = self.correct_instant(text)

        sentences = re.split(r'(?<=[.!?])\s+', text)
        corrected_sentences = []

        for sentence in sentences:
            if not sentence.strip():
                continue

            sentence = sentence.strip()

            if sentence and sentence[0].islower():
                sentence = sentence[0].upper() + sentence[1:]

            if sentence and sentence[-1] not in '.!?':
                sentence += '.'

            corrected_sentences.append(sentence)

        return ' '.join(corrected_sentences)


_transcriber: Optional[RealtimeTranscriber] = None
_corrector: Optional[TextCorrector] = None


def get_realtime_transcriber(language: str = "de") -> RealtimeTranscriber:
    global _transcriber
    if _transcriber is None or _transcriber.language != language:
        _transcriber = RealtimeTranscriber(language)
    return _transcriber


def get_text_corrector(language: str = "de") -> TextCorrector:
    global _corrector
    if _corrector is None or _corrector.language != language:
        _corrector = TextCorrector(language)
    return _corrector


def transcribe_audio_chunk(
    audio_data: np.ndarray,
    sample_rate: int = 16000,
    language: str = "de",
    apply_instant_correction: bool = True
) -> Tuple[str, str, float]:
    transcriber = get_realtime_transcriber(language)
    corrector = get_text_corrector(language)

    raw_text, confidence = transcriber.transcribe_chunk(audio_data, sample_rate)

    if apply_instant_correction and raw_text:
        corrected_text = corrector.correct_instant(raw_text)
    else:
        corrected_text = raw_text

    return raw_text, corrected_text, confidence


def transcribe_audio(
    audio_path: str,
    language: str = "de",
    apply_correction: bool = True
) -> Dict:
    global _accurate_model

    if not os.path.exists(audio_path):
        return {
            'success': False,
            'error': f"Audio file not found: {audio_path}",
            'text': '',
            'language': None,
            'segments': []
        }

    try:
        with _model_lock:
            if _accurate_model is None:
                print(f"Loading Whisper '{ACCURATE_MODEL}' for final transcription...")
                _accurate_model = WhisperModel(
                    ACCURATE_MODEL,
                    device="cpu",
                    compute_type="int8"
                )
                print("Accurate model ready")

        segments, info = _accurate_model.transcribe(
            audio_path,
            language=language,
            task="transcribe",
            beam_size=5,
            best_of=5,
            patience=1.5,
            condition_on_previous_text=True,
            vad_filter=True,
            vad_parameters={
                "threshold": 0.4,
                "min_speech_duration_ms": 300,
                "min_silence_duration_ms": 200,
                "speech_pad_ms": 100,
            }
        )

        all_segments = []
        full_text = []

        for seg in segments:
            text = seg.text.strip()
            if text:
                all_segments.append({
                    'start': seg.start,
                    'end': seg.end,
                    'text': text
                })
                full_text.append(text)

        raw_text = ' '.join(full_text)

        if apply_correction and raw_text:
            corrector = get_text_corrector(language)
            corrected_text = corrector.correct_full(raw_text)
        else:
            corrected_text = raw_text

        return {
            'success': True,
            'text': corrected_text,
            'raw_text': raw_text,
            'language': info.language,
            'segments': all_segments,
            'used_ai_correction': apply_correction,
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
        {'name': 'small', 'description': 'Real-time transcription', 'size': '~500 MB'},
        {'name': 'medium', 'description': 'Final transcription', 'size': '~1.5 GB'},
    ]


def preload_model():
    def _load():
        transcriber = get_realtime_transcriber("de")
        transcriber.load_model()
    threading.Thread(target=_load, daemon=True).start()


def reset_session():
    global _transcriber
    if _transcriber is not None:
        _transcriber.reset()


def get_correction_status() -> Dict:
    return {
        'ai_correction': {
            'available': True,
            'model': 'Integrated TextCorrector',
            'message': 'Instant grammar correction active'
        },
        'speaker_diarization': {
            'num_speakers': 0,
            'teacher_detected': False
        }
    }


def get_ollama_status() -> Dict:
    return {
        'available': False,
        'model': None,
        'message': 'Using integrated correction'
    }
