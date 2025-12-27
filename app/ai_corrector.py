import os
import threading
from typing import Optional, Tuple
import re

MLX_MODEL = "mlx-community/Qwen2.5-1.5B-Instruct-4bit"  # Larger model for better output
MAX_TOKENS = 256  # Reduced to prevent runaway generation
TEMPERATURE = 0.1
REPETITION_PENALTY = 1.2


class AICorrector:
    def __init__(self):
        self._model = None
        self._tokenizer = None
        self._model_lock = threading.Lock()
        self._model_loaded = False
        self._mlx_available = False
        self._language_tool = None
        self._lt_lang = None

    def _check_mlx_available(self) -> bool:
        try:
            import platform
            if platform.processor() != 'arm':
                return False
            import mlx
            import mlx_lm
            return True
        except ImportError:
            return False

    def _load_model(self) -> bool:
        if self._model_loaded:
            return self._mlx_available

        with self._model_lock:
            if self._model_loaded:
                return self._mlx_available

            self._mlx_available = self._check_mlx_available()

            if self._mlx_available:
                try:
                    from mlx_lm import load
                    print(f"Loading AI model ({MLX_MODEL})...")
                    self._model, self._tokenizer = load(MLX_MODEL)
                    print("AI corrector ready (MLX)")
                except Exception as e:
                    print(f"MLX model load failed: {e}")
                    self._mlx_available = False

            self._model_loaded = True
            return self._mlx_available

    def _get_language_tool(self, language: str):
        lang_map = {
            "de": "de-DE",
            "en": "en-US",
        }
        lt_lang = lang_map.get(language, "de-DE")

        if self._language_tool is not None and self._lt_lang == lt_lang:
            return self._language_tool

        try:
            import language_tool_python

            if self._language_tool is not None:
                try:
                    self._language_tool.close()
                except:
                    pass

            self._language_tool = language_tool_python.LanguageTool(lt_lang)
            self._lt_lang = lt_lang
            return self._language_tool
        except Exception as e:
            print(f"LanguageTool unavailable: {e}")
            return None

    def _correct_with_language_tool(self, text: str, language: str) -> str:
        tool = self._get_language_tool(language)
        if tool is None:
            return text

        try:
            matches = tool.check(text)
            corrected = text
            for match in reversed(matches):
                if match.replacements:
                    start = match.offset
                    error_len = getattr(match, 'errorLength', None) or getattr(match, 'error_length', None) or len(match.context.split())
                    end = start + error_len
                    corrected = corrected[:start] + match.replacements[0] + corrected[end:]
            return corrected
        except Exception as e:
            print(f"LanguageTool correction failed: {e}")
            return text

    def _build_prompt(self, text: str, subject: Optional[str], language: str) -> str:
        lang_name = "German" if language == "de" else "English"

        subject_context = ""
        if subject:
            subject_context = f"This is a {subject} lecture. "

        prompt = f"""Fix this {lang_name} classroom transcription. {subject_context}Rules:
1. Fix spelling/grammar errors
2. Remove filler words (um, uh, äh, ähm)
3. Keep only lecture content, remove off-topic chat
4. Keep same language
5. Return ONLY the corrected text

Text: {text}

Corrected:"""

        return prompt

    def _generate_with_mlx(self, prompt: str) -> str:
        try:
            from mlx_lm import generate
            import inspect

            # Check which parameters the generate function accepts
            sig = inspect.signature(generate)
            params = sig.parameters

            # Build kwargs based on available parameters
            kwargs = {
                'model': self._model,
                'tokenizer': self._tokenizer,
                'prompt': prompt,
                'max_tokens': MAX_TOKENS,
                'verbose': False
            }

            # Only add temperature if supported
            if 'temperature' in params or 'temp' in params:
                temp_key = 'temp' if 'temp' in params else 'temperature'
                kwargs[temp_key] = TEMPERATURE

            # Add repetition penalty if supported
            if 'repetition_penalty' in params:
                kwargs['repetition_penalty'] = REPETITION_PENALTY

            response = generate(**kwargs)
            response = response.strip()

            # Clean up the response - remove any "Correction:", "Corrected:", "Explanation:" prefixes
            response = self._clean_mlx_response(response)

            return response

        except Exception as e:
            print(f"MLX generation error: {e}")
            return ""

    def _clean_mlx_response(self, response: str) -> str:
        """Clean up MLX model output - remove repetitions and meta-text."""
        if not response:
            return ""

        # Split by common repetition markers
        markers = [
            '\n\nCorrection:', '\nCorrection:', 'Correction:',
            '\n\nCorrected:', '\nCorrected:', 'Corrected:',
            '\n\nExplanation:', '\nExplanation:', 'Explanation:',
            '\n\nNote:', '\nNote:', 'Note:',
            '\n\n1.', '\n1.',
            '\n\nSentence', '\nSentence',
        ]

        # Find the first occurrence of any marker and cut there
        first_cut = len(response)
        for marker in markers:
            idx = response.find(marker)
            if idx > 0 and idx < first_cut:
                first_cut = idx

        response = response[:first_cut].strip()

        # Remove duplicate sentences (same sentence appearing multiple times)
        sentences = re.split(r'(?<=[.!?])\s+', response)
        seen = set()
        unique_sentences = []
        for s in sentences:
            s_clean = s.strip().lower()
            if s_clean and s_clean not in seen:
                seen.add(s_clean)
                unique_sentences.append(s.strip())

        response = ' '.join(unique_sentences)

        # Ensure proper ending
        if response and response[-1] not in '.!?':
            last_sentence = max(
                response.rfind('.'),
                response.rfind('!'),
                response.rfind('?')
            )
            if last_sentence > len(response) * 0.3:
                response = response[:last_sentence + 1]

        return response

    def correct(
        self,
        text: str,
        subject: Optional[str] = None,
        language: str = "de"
    ) -> Tuple[str, bool]:
        if not text or not text.strip():
            return text, False

        text = self._remove_fillers(text, language)

        if self._load_model() and self._mlx_available:
            prompt = self._build_prompt(text, subject, language)
            corrected = self._generate_with_mlx(prompt)

            if corrected and len(corrected) > 10:
                return corrected, True

        corrected = self._correct_with_language_tool(text, language)
        return corrected, False

    def _remove_fillers(self, text: str, language: str) -> str:
        fillers = {
            "de": [
                r'\bähm?\b', r'\böhm?\b', r'\bhmm?\b', r'\bhm\b',
                r'\bja\s+also\b', r'\balso\s+ja\b', r'\bso\s+quasi\b',
            ],
            "en": [
                r'\buh+\b', r'\bum+\b', r'\bhm+\b', r'\ber+\b',
                r'\byou know\b', r'\bso\s+yeah\b',
            ]
        }

        patterns = fillers.get(language, fillers["de"])
        result = text

        for pattern in patterns:
            result = re.sub(pattern, '', result, flags=re.IGNORECASE)

        result = re.sub(r'\s+', ' ', result).strip()
        return result

    def is_ai_available(self) -> bool:
        return self._load_model() and self._mlx_available

    def get_status(self) -> dict:
        self._load_model()

        return {
            'mlx_available': self._mlx_available,
            'model': MLX_MODEL if self._mlx_available else None,
            'fallback': 'LanguageTool',
            'message': (
                'AI correction ready (MLX/Qwen2.5)'
                if self._mlx_available
                else 'Using LanguageTool (MLX requires Apple Silicon)'
            )
        }


_corrector: Optional[AICorrector] = None


def get_corrector() -> AICorrector:
    global _corrector
    if _corrector is None:
        _corrector = AICorrector()
    return _corrector


def correct_transcription(
    text: str,
    subject: Optional[str] = None,
    language: str = "de"
) -> str:
    corrector = get_corrector()
    corrected, _ = corrector.correct(text, subject, language)
    return corrected


def get_ai_status() -> dict:
    return get_corrector().get_status()
