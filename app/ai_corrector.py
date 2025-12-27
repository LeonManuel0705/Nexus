"""
AI Text Corrector for Voice Notes
=================================

Fast, offline AI-powered text correction using MLX on Apple Silicon.
Understands context to fix transcription errors intelligently.

Falls back to LanguageTool on non-Apple Silicon or if MLX unavailable.
"""

import os
import threading
from typing import Optional, Tuple
import re

# MLX model settings
MLX_MODEL = "mlx-community/Qwen2.5-0.5B-Instruct-4bit"  # Fast, 500MB, great quality
MAX_TOKENS = 512
TEMPERATURE = 0.1  # Low for consistent corrections


class AICorrector:
    """
    Context-aware AI text corrector using MLX for fast inference.

    Features:
    - Fixes spelling and grammar errors
    - Understands subject context (math, physics, etc.)
    - Filters irrelevant content
    - Runs entirely offline on Apple Silicon
    """

    def __init__(self):
        self._model = None
        self._tokenizer = None
        self._model_lock = threading.Lock()
        self._model_loaded = False
        self._mlx_available = False
        self._language_tool = None
        self._lt_lang = None

    def _check_mlx_available(self) -> bool:
        """Check if MLX is available (Apple Silicon only)."""
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
        """Lazy load the MLX model."""
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
        """Get LanguageTool instance for fallback correction."""
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
        """Fallback correction using LanguageTool."""
        tool = self._get_language_tool(language)
        if tool is None:
            return text

        try:
            matches = tool.check(text)
            corrected = text
            for match in reversed(matches):
                if match.replacements:
                    start = match.offset
                    end = match.offset + match.errorLength
                    corrected = corrected[:start] + match.replacements[0] + corrected[end:]
            return corrected
        except Exception as e:
            print(f"LanguageTool correction failed: {e}")
            return text

    def _build_prompt(self, text: str, subject: Optional[str], language: str) -> str:
        """Build the correction prompt."""
        lang_name = "German" if language == "de" else "English"

        subject_context = ""
        if subject:
            subject_context = f"This is a {subject} lecture. "

        # Concise prompt for fast inference
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
        """Generate correction using MLX."""
        try:
            from mlx_lm import generate

            response = generate(
                self._model,
                self._tokenizer,
                prompt=prompt,
                max_tokens=MAX_TOKENS,
                temp=TEMPERATURE,
                verbose=False
            )

            # Clean up response
            response = response.strip()

            # Remove any trailing incomplete sentences
            if response and response[-1] not in '.!?':
                last_sentence = max(
                    response.rfind('.'),
                    response.rfind('!'),
                    response.rfind('?')
                )
                if last_sentence > len(response) * 0.5:
                    response = response[:last_sentence + 1]

            return response

        except Exception as e:
            print(f"MLX generation error: {e}")
            return ""

    def correct(
        self,
        text: str,
        subject: Optional[str] = None,
        language: str = "de"
    ) -> Tuple[str, bool]:
        """
        Correct text using AI with context awareness.

        Args:
            text: Raw transcription text
            subject: Optional subject context (e.g., "Mathe", "Physik")
            language: Language code ("de" or "en")

        Returns:
            Tuple of (corrected_text, used_ai)
            used_ai is True if MLX was used, False if fell back to LanguageTool
        """
        if not text or not text.strip():
            return text, False

        # Remove filler words first (fast, always works)
        text = self._remove_fillers(text, language)

        # Try MLX if available
        if self._load_model() and self._mlx_available:
            prompt = self._build_prompt(text, subject, language)
            corrected = self._generate_with_mlx(prompt)

            if corrected and len(corrected) > 10:
                return corrected, True

        # Fallback to LanguageTool
        corrected = self._correct_with_language_tool(text, language)
        return corrected, False

    def _remove_fillers(self, text: str, language: str) -> str:
        """Remove filler words from text."""
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

        # Clean up extra spaces
        result = re.sub(r'\s+', ' ', result).strip()
        return result

    def is_ai_available(self) -> bool:
        """Check if AI correction is available."""
        return self._load_model() and self._mlx_available

    def get_status(self) -> dict:
        """Get corrector status for UI."""
        self._load_model()  # Ensure status is accurate

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


# Global corrector instance
_corrector: Optional[AICorrector] = None


def get_corrector() -> AICorrector:
    """Get or create the global AI corrector."""
    global _corrector
    if _corrector is None:
        _corrector = AICorrector()
    return _corrector


def correct_transcription(
    text: str,
    subject: Optional[str] = None,
    language: str = "de"
) -> str:
    """
    Convenience function to correct transcription text.

    Args:
        text: Raw transcription
        subject: Optional subject context
        language: Language code

    Returns:
        Corrected text
    """
    corrector = get_corrector()
    corrected, _ = corrector.correct(text, subject, language)
    return corrected


def get_ai_status() -> dict:
    """Get AI corrector status."""
    return get_corrector().get_status()
