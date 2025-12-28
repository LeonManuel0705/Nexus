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
            base_prompt = ""
            if self.language == "de":
                base_prompt = "Dies ist eine Vorlesung oder Unterrichtsstunde auf Deutsch. "
            elif self.language == "en":
                base_prompt = "This is a lecture or class in English. "

            if self.context_text:
                initial_prompt = base_prompt + self.context_text[-300:]
            else:
                initial_prompt = base_prompt if base_prompt else None

            segments, info = self.model.transcribe(
                audio_data,
                language=self.language,
                task="transcribe",
                beam_size=5,
                best_of=5,
                patience=1.5,
                length_penalty=1.0,
                repetition_penalty=1.2,
                no_repeat_ngram_size=3,
                temperature=[0.0, 0.2, 0.4],
                compression_ratio_threshold=2.4,
                log_prob_threshold=-1.0,
                no_speech_threshold=0.6,
                condition_on_previous_text=True,
                initial_prompt=initial_prompt,
                vad_filter=True,
                vad_parameters={
                    "threshold": 0.35,
                    "min_speech_duration_ms": 200,
                    "min_silence_duration_ms": 150,
                    "speech_pad_ms": 100,
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

        self.lowercase_words = {
            "de": ['und', 'oder', 'aber', 'denn', 'weil', 'dass', 'wenn', 'als', 'ob', 'damit',
                   'der', 'die', 'das', 'den', 'dem', 'des', 'ein', 'eine', 'einer', 'einem',
                   'zu', 'von', 'mit', 'bei', 'nach', 'aus', 'für', 'über', 'unter', 'zwischen',
                   'ist', 'sind', 'war', 'waren', 'hat', 'haben', 'wird', 'werden', 'kann', 'können',
                   'ich', 'du', 'er', 'sie', 'es', 'wir', 'ihr', 'man', 'sich', 'nicht', 'auch'],
            "en": ['and', 'or', 'but', 'the', 'a', 'an', 'is', 'are', 'was', 'were', 'has', 'have',
                   'to', 'of', 'in', 'on', 'at', 'for', 'with', 'from', 'by', 'about', 'into',
                   'i', 'you', 'he', 'she', 'it', 'we', 'they', 'this', 'that', 'not', 'also']
        }

        self.number_words_de = {
            'null': '0', 'eins': '1', 'zwei': '2', 'drei': '3', 'vier': '4',
            'fünf': '5', 'sechs': '6', 'sieben': '7', 'acht': '8', 'neun': '9',
            'zehn': '10', 'elf': '11', 'zwölf': '12', 'dreizehn': '13', 'vierzehn': '14',
            'fünfzehn': '15', 'sechzehn': '16', 'siebzehn': '17', 'achtzehn': '18', 'neunzehn': '19',
            'zwanzig': '20', 'dreißig': '30', 'vierzig': '40', 'fünfzig': '50',
            'sechzig': '60', 'siebzig': '70', 'achtzig': '80', 'neunzig': '90',
            'hundert': '100', 'tausend': '1000', 'million': '1000000',
            'einundzwanzig': '21', 'zweiundzwanzig': '22', 'dreiundzwanzig': '23',
            'vierundzwanzig': '24', 'fünfundzwanzig': '25', 'sechsundzwanzig': '26',
            'siebenundzwanzig': '27', 'achtundzwanzig': '28', 'neunundzwanzig': '29',
            'einunddreißig': '31', 'zweiunddreißig': '32',
            'einundvierzig': '41', 'zweiundvierzig': '42',
            'einundfünfzig': '51', 'zweiundfünfzig': '52',
        }

        self.number_words_en = {
            'zero': '0', 'one': '1', 'two': '2', 'three': '3', 'four': '4',
            'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'nine': '9',
            'ten': '10', 'eleven': '11', 'twelve': '12', 'thirteen': '13', 'fourteen': '14',
            'fifteen': '15', 'sixteen': '16', 'seventeen': '17', 'eighteen': '18', 'nineteen': '19',
            'twenty': '20', 'thirty': '30', 'forty': '40', 'fifty': '50',
            'sixty': '60', 'seventy': '70', 'eighty': '80', 'ninety': '90',
            'hundred': '100', 'thousand': '1000', 'million': '1000000',
        }

        self.url_triggers = [
            'slash', 'http', 'https', 'www', 'punkt', 'dot', 'at', 'colon',
            'doppelpunkt', 'schrägstrich'
        ]

        self.domain_endings = ['.com', '.de', '.org', '.net', '.io', '.edu', '.gov', '.co', '.info']

        self.english_tech_corrections = {
            'rekarding': 'recording',
            'rekord': 'record',
            'rekords': 'records',
            'rekorder': 'recorder',
            'seyf': 'save',
            'seif': 'save',
            'lokal': 'local',
            'lokale': 'local',
            'lokalhost': 'localhost',
            'lokel': 'local',
            'lokälhost': 'localhost',
            'serfer': 'server',
            'datei': 'file',
            'uploat': 'upload',
            'uploaden': 'upload',
            'downloat': 'download',
            'downloaden': 'download',
            'klick': 'click',
            'klicken': 'click',
        }

        self.math_operators = {}

    def _convert_numbers(self, text: str) -> str:
        lang = self.language[:2]
        number_words = self.number_words_de if lang == 'de' else self.number_words_en

        words = text.split()
        result = []
        i = 0

        while i < len(words):
            word_lower = words[i].lower().rstrip('.,!?;:')
            punctuation = ''
            if words[i] and words[i][-1] in '.,!?;:':
                punctuation = words[i][-1]

            if word_lower in number_words:
                result.append(number_words[word_lower] + punctuation)
            elif lang == 'de' and 'und' in word_lower:
                converted = self._parse_compound_german_number(word_lower)
                if converted:
                    result.append(converted + punctuation)
                else:
                    result.append(words[i])
            else:
                result.append(words[i])
            i += 1

        return ' '.join(result)

    def _parse_compound_german_number(self, word: str) -> Optional[str]:
        ones = {'ein': 1, 'zwei': 2, 'drei': 3, 'vier': 4, 'fünf': 5,
                'sechs': 6, 'sieben': 7, 'acht': 8, 'neun': 9}
        tens = {'zwanzig': 20, 'dreißig': 30, 'vierzig': 40, 'fünfzig': 50,
                'sechzig': 60, 'siebzig': 70, 'achtzig': 80, 'neunzig': 90}

        for one_word, one_val in ones.items():
            for ten_word, ten_val in tens.items():
                if word == f"{one_word}und{ten_word}":
                    return str(one_val + ten_val)

        return None

    def _detect_and_format_urls(self, text: str) -> str:
        text = re.sub(r'\b(http|https)\s+(doppelpunkt|colon)\s*(slash|schrägstrich)\s*(slash|schrägstrich)\s*',
                      r'https://', text, flags=re.IGNORECASE)

        text = re.sub(r'\b(www)\s+(punkt|dot)\s*', r'www.', text, flags=re.IGNORECASE)

        text = re.sub(r'\blocalhost\s+(doppelpunkt|colon)\s*(\d+)',
                      r'localhost:\2', text, flags=re.IGNORECASE)
        text = re.sub(r'\blocal\s+host\s+(doppelpunkt|colon)\s*(\d+)',
                      r'localhost:\2', text, flags=re.IGNORECASE)

        text = re.sub(r'\s+(punkt|dot)\s+(com|de|org|net|io|edu|gov|co|info|local|localhost)\b',
                      r'.\2', text, flags=re.IGNORECASE)

        text = re.sub(r'\s*(slash|schrägstrich)\s*', '/', text, flags=re.IGNORECASE)

        text = re.sub(r'(https?://\S+)', lambda m: m.group(1).lower(), text)
        text = re.sub(r'\blocalhost:\d+\b', lambda m: m.group(0).lower(), text)

        return text

    def _correct_tech_terms(self, text: str) -> str:
        words = text.split()
        result = []

        for word in words:
            word_lower = word.lower().rstrip('.,!?;:')
            punctuation = ''
            if word and word[-1] in '.,!?;:':
                punctuation = word[-1]
                word_base = word[:-1]
            else:
                word_base = word

            if word_lower in self.english_tech_corrections:
                corrected = self.english_tech_corrections[word_lower]
                if word_base[0].isupper():
                    corrected = corrected.capitalize()
                result.append(corrected + punctuation)
            else:
                result.append(word)

        return ' '.join(result)

    def _format_math(self, text: str) -> str:
        return text

    def _format_special_chars(self, text: str) -> str:
        replacements = {
            r'\bat\s+zeichen\b': '@',
            r'\bat\s+sign\b': '@',
            r'\bät\b': '@',
            r'\bklammeraffe\b': '@',
            r'\bunderscore\b': '_',
            r'\bunterstrich\b': '_',
            r'\bbindestrich\b': '-',
            r'\bminus\b': '-',
            r'\bplus\b': '+',
            r'\bgleich\b': '=',
            r'\bequals\b': '=',
            r'\bprozent\b': '%',
            r'\bpercent\b': '%',
            r'\beuro\b': '€',
            r'\bdollar\b': '$',
            r'\bhashtag\b': '#',
            r'\bund zeichen\b': '&',
            r'\bampersand\b': '&',
            r'\bsternchen\b': '*',
            r'\basterisk\b': '*',
        }

        for pattern, replacement in replacements.items():
            text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)

        return text

    def _is_likely_mid_sentence(self, before_text: str, after_word: str) -> bool:
        lang = self.language[:2]
        lowercase_words = self.lowercase_words.get(lang, [])

        if after_word.lower() in lowercase_words:
            return True

        if before_text and before_text[-1] == ',':
            return True

        return False

    def correct_instant(self, text: str) -> str:
        if not text or not text.strip():
            return text

        lang = self.language[:2]

        for pattern, replacement in self.filler_patterns.get(lang, []):
            text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)

        for pattern, replacement in self.common_errors.get(lang, {}).items():
            text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)

        text = self._correct_tech_terms(text)
        text = self._convert_numbers(text)
        text = self._detect_and_format_urls(text)
        text = self._format_special_chars(text)
        text = self._format_math(text)

        text = re.sub(r'\s+', ' ', text).strip()
        text = re.sub(r'\s+([.,!?;:])', r'\1', text)
        text = re.sub(r'([.,!?;:])\s*([.,!?;:])+', r'\1', text)

        if text and not text[0].isupper():
            text = text[0].upper() + text[1:]

        return text

    def correct_full(self, text: str, context: Optional[str] = None) -> str:
        if not text or not text.strip():
            return text

        lang = self.language[:2]

        for pattern, replacement in self.filler_patterns.get(lang, []):
            text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)

        for pattern, replacement in self.common_errors.get(lang, {}).items():
            text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)

        text = self._correct_tech_terms(text)
        text = self._convert_numbers(text)
        text = self._detect_and_format_urls(text)
        text = self._format_special_chars(text)
        text = self._format_math(text)

        text = re.sub(r'\s+', ' ', text).strip()
        text = re.sub(r'\s+([.,!?;:])', r'\1', text)
        text = re.sub(r'([.,!?;:])\s*([.,!?;:])+', r'\1', text)

        result = []
        i = 0
        while i < len(text):
            if text[i] == '.':
                if i + 2 < len(text) and text[i + 1] == ' ':
                    next_word_match = re.match(r'\s+(\w+)', text[i + 1:])
                    if next_word_match:
                        next_word = next_word_match.group(1)
                        before_text = text[:i]

                        if self._is_likely_mid_sentence(before_text, next_word):
                            result.append(',')
                            i += 1
                            continue

                result.append(text[i])
            else:
                result.append(text[i])
            i += 1

        text = ''.join(result)

        text = re.sub(r',\s*,+', ',', text)

        if text and text[0].islower():
            text = text[0].upper() + text[1:]

        sentences = re.split(r'([.!?]\s+)', text)
        final_result = []
        for j, part in enumerate(sentences):
            if j > 0 and j - 1 < len(sentences) and re.match(r'^[.!?]\s+$', sentences[j - 1]):
                if part and len(part) > 0 and part[0].islower():
                    part = part[0].upper() + part[1:]
            final_result.append(part)

        text = ''.join(final_result)

        if text and text[-1] not in '.!?':
            text += '.'

        return text


_transcriber: Optional[RealtimeTranscriber] = None
_corrector: Optional[TextCorrector] = None
_ai_corrector_available: Optional[bool] = None


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


def apply_ai_correction(text: str, language: str = "de", subject: Optional[str] = None) -> str:
    global _ai_corrector_available

    if not text or not text.strip():
        return text

    try:
        from ai_corrector import get_corrector, correct_transcription

        if _ai_corrector_available is None:
            corrector = get_corrector()
            _ai_corrector_available = corrector.is_ai_available()

        if _ai_corrector_available:
            return correct_transcription(text, subject, language)
        else:
            return text

    except ImportError:
        _ai_corrector_available = False
        return text
    except Exception as e:
        print(f"AI correction error: {e}")
        return text


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
                    compute_type="int8",
                    num_workers=4
                )
                print("Accurate model ready")

        segments, info = _accurate_model.transcribe(
            audio_path,
            language=language,
            task="transcribe",
            beam_size=3,
            best_of=1,
            patience=1.0,
            condition_on_previous_text=True,
            vad_filter=True,
            vad_parameters={
                "threshold": 0.4,
                "min_speech_duration_ms": 250,
                "min_silence_duration_ms": 200,
                "speech_pad_ms": 50,
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
    try:
        from ai_corrector import get_ai_status
        ai_status = get_ai_status()
        return {
            'ai_correction': ai_status,
            'speaker_diarization': {
                'num_speakers': 0,
                'teacher_detected': False
            }
        }
    except ImportError:
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
