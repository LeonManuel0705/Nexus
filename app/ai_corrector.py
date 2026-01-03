import os
import json
import threading
from typing import Optional, Tuple, List, Dict
from pathlib import Path
import re

MLX_MODEL = "mlx-community/Qwen2.5-3B-Instruct-4bit"
MAX_TOKENS = 300
TEMPERATURE = 0.1
REPETITION_PENALTY = 1.2
USE_MLX_AI = True
NUM_FEW_SHOT_EXAMPLES = 5

LEARNING_DATA_DIR = Path(__file__).parent.parent / "learning_data"

class AICorrector:
    def __init__(self):
        self._model = None
        self._tokenizer = None
        self._model_lock = threading.Lock()
        self._model_loaded = False
        self._mlx_available = False
        self._language_tool = None
        self._lt_lang = None
        self._training_pairs: List[Dict] = []
        self._word_alignments: Dict = {}
        self._load_training_data()

    def _load_training_data(self):
        try:
            training_file = LEARNING_DATA_DIR / "training_pairs.jsonl"
            if training_file.exists():
                self._training_pairs = []
                seen = set()
                with open(training_file, 'r', encoding='utf-8') as f:
                    for line in f:
                        if line.strip():
                            pair = json.loads(line)
                            key = (pair.get('incorrect', ''), pair.get('correct', ''))
                            if key not in seen:
                                seen.add(key)
                                self._training_pairs.append(pair)
                print(f"Loaded {len(self._training_pairs)} training pairs for few-shot learning")

            alignments_file = LEARNING_DATA_DIR / "word_alignments.json"
            if alignments_file.exists():
                with open(alignments_file, 'r', encoding='utf-8') as f:
                    self._word_alignments = json.load(f)
                print(f"Loaded word alignments with {len(self._word_alignments.get('word_corrections', {}))} entries")
        except Exception as e:
            print(f"Failed to load training data: {e}")

    def reload_training_data(self):
        self._load_training_data()

    def _find_similar_examples(self, text: str, n: int = NUM_FEW_SHOT_EXAMPLES) -> List[Dict]:
        if not self._training_pairs:
            return []

        text_words = set(text.lower().split())
        scored_pairs = []

        for pair in self._training_pairs:
            incorrect = pair.get('incorrect', '').lower()
            incorrect_words = set(incorrect.split())

            if not incorrect_words:
                continue
            intersection = len(text_words & incorrect_words)
            union = len(text_words | incorrect_words)
            similarity = intersection / union if union > 0 else 0

            if incorrect in text.lower():
                similarity += 0.5

            if similarity > 0:
                scored_pairs.append((similarity, pair))

        scored_pairs.sort(key=lambda x: x[0], reverse=True)
        return [pair for _, pair in scored_pairs[:n]]

    def _apply_known_corrections(self, text: str) -> str:
        if not self._word_alignments:
            return text

        word_corrections = self._word_alignments.get('word_corrections', {})
        result = text

        sorted_corrections = sorted(word_corrections.items(), key=lambda x: len(x[0]), reverse=True)

        for incorrect, corrections in sorted_corrections:
            if not corrections:
                continue

            if len(incorrect) < 5:
                continue

            best_correction, count = max(corrections.items(), key=lambda x: x[1])

            if count < 2:
                continue

            pattern = re.compile(r'\b' + re.escape(incorrect) + r'\b', re.IGNORECASE)
            result = pattern.sub(best_correction, result)

        return result

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
            return self._post_process_text(text, language)

        try:
            matches = tool.check(text)
            corrected = text
            for match in reversed(matches):
                if match.replacements:
                    start = match.offset
                    error_len = getattr(match, 'errorLength', None) or getattr(match, 'error_length', None) or len(match.context.split())
                    end = start + error_len
                    corrected = corrected[:start] + match.replacements[0] + corrected[end:]
            return self._post_process_text(corrected, language)
        except Exception as e:
            print(f"LanguageTool correction failed: {e}")
            return self._post_process_text(text, language)

    def _post_process_text(self, text: str, language: str) -> str:
        if not text:
            return text

        text = re.sub(r'\s+', ' ', text).strip()

        text = re.sub(r'\s+([.,!?;:])', r'\1', text)

        text = re.sub(r'([.,!?;:])\s*([.,!?;:])', r'\1', text)

        text = re.sub(r'\.\s*,', ',', text)
        text = re.sub(r',\s*\.', '.', text)

        text = self._merge_fragments(text, language)

        text = re.sub(r'([.!?])\s*', r'\1 ', text)
        text = text.strip()

        if text and text[0].islower():
            text = text[0].upper() + text[1:]

        sentences = re.split(r'([.!?]\s+)', text)
        result = []
        for i, part in enumerate(sentences):
            if i > 0 and sentences[i-1].strip() in '.!?':
                if part and part[0].islower():
                    part = part[0].upper() + part[1:]
            result.append(part)
        text = ''.join(result)

        text = self._remove_very_short_sentences(text, language)

        if text and text[-1] not in '.!?':
            text += '.'

        return text

    def _merge_fragments(self, text: str, language: str) -> str:
        if language == "de":
            incomplete_patterns = [
                r'\.\s+(dass|weil|wenn|obwohl|damit|sodass|ob|als|während|bevor|nachdem|sobald|falls|sofern)\s+',
                r'\.\s+(und|oder|aber|denn|sondern|doch|jedoch)\s+',
                r'\.\s+(der|die|das|den|dem|des)\s+',
                r'(ist|sind|war|waren|hat|haben|wird|werden|kann|können|muss|müssen|soll|sollen)\s*\.\s+([A-ZÄÖÜ])',
            ]
        else:
            incomplete_patterns = [
                r'\.\s+(that|because|when|although|if|while|before|after|unless|since)\s+',
                r'\.\s+(and|or|but|so|yet|for|nor)\s+',
                r'\.\s+(the|a|an)\s+',
                r'(is|are|was|were|has|have|will|would|can|could|must|should)\s*\.\s+([A-Z])',
            ]

        for pattern in incomplete_patterns[:-1]:
            text = re.sub(pattern, lambda m: ', ' + m.group(1).lower() + ' ', text, flags=re.IGNORECASE)

        if incomplete_patterns:
            text = re.sub(incomplete_patterns[-1], r'\1 \2', text, flags=re.IGNORECASE)

        return text

    def _remove_very_short_sentences(self, text: str, language: str) -> str:
        return text

    def _build_prompt(self, text: str, subject: Optional[str], language: str) -> str:
        examples = self._find_similar_examples(text)

        if language == "de":
            system_msg = """Du bist ein Experte für die Korrektur von Sprachtranskriptionen.
Deine Aufgabe ist es, fehlerhafte Transkriptionen zu korrigieren und dabei:
- Falsch erkannte Wörter zu korrigieren
- Grammatik und Satzstruktur zu verbessern
- Den gemeinten Sinn beizubehalten
- NUR den korrigierten Text auszugeben, keine Erklärungen"""

            examples_text = ""
            if examples:
                examples_text = "\n\nBeispiele für Korrekturen:\n"
                for ex in examples:
                    examples_text += f"Falsch: {ex['incorrect']}\nRichtig: {ex['correct']}\n\n"

            prompt = f"""<|im_start|>system
{system_msg}{examples_text}<|im_end|>
<|im_start|>user
Korrigiere diese Transkription: {text}<|im_end|>
<|im_start|>assistant
"""
        else:
            system_msg = """You are an expert at correcting speech transcriptions.
Your task is to fix transcription errors by:
- Correcting misrecognized words
- Improving grammar and sentence structure
- Preserving the intended meaning
- Output ONLY the corrected text, no explanations"""

            examples_text = ""
            if examples:
                examples_text = "\n\nExamples of corrections:\n"
                for ex in examples:
                    examples_text += f"Wrong: {ex['incorrect']}\nCorrect: {ex['correct']}\n\n"

            prompt = f"""<|im_start|>system
{system_msg}{examples_text}<|im_end|>
<|im_start|>user
Fix this transcription: {text}<|im_end|>
<|im_start|>assistant
"""

        return prompt

    def _generate_with_mlx(self, prompt: str) -> str:
        try:
            from mlx_lm import generate
            import inspect

            sig = inspect.signature(generate)
            params = sig.parameters

            kwargs = {
                'model': self._model,
                'tokenizer': self._tokenizer,
                'prompt': prompt,
                'max_tokens': MAX_TOKENS,
                'verbose': False
            }

            if 'temperature' in params or 'temp' in params:
                temp_key = 'temp' if 'temp' in params else 'temperature'
                kwargs[temp_key] = TEMPERATURE

            if 'repetition_penalty' in params:
                kwargs['repetition_penalty'] = REPETITION_PENALTY

            response = generate(**kwargs)
            response = response.strip()

            response = self._clean_mlx_response(response)

            return response

        except Exception as e:
            print(f"MLX generation error: {e}")
            return ""

    def _clean_mlx_response(self, response: str) -> str:
        if not response:
            return ""

        lines = response.split('\n')
        clean_lines = []
        for line in lines:
            line = line.strip()
            skip_patterns = [
                'here is', 'here\'s', 'the corrected', 'corrected text',
                'corrected version', 'i have', 'i\'ve', 'note:', 'explanation:',
                'changes made', 'changes:', 'original:', 'fixed:', 'result:',
                '---', '===', '***', 'step', 'rule', '1.', '2.', '3.',
                'if you have any questions', 'feel free to ask', 'i hope this helps',
                'let me know', 'i\'m here to help', 'happy to help', 'please provide',
                'thank you for', 'you\'re welcome', 'this is a correct', 'the sentence',
                'the text', 'in english', 'translates to', 'it means', 'literally means',
                'this phrase', 'the phrase', 'the word', 'is often used', 'it\'s often',
                'it is often', 'commonly used', 'a common phrase', 'the corrected german',
                'hier ist', 'die korrigierte', 'korrigierte version', 'korrigierter text',
                'wenn du fragen hast', 'bei fragen', 'ich hoffe', 'gerne geschehen',
            ]
            if any(p in line.lower() for p in skip_patterns):
                continue
            if line.startswith(('-', '*', '#', '>', '•')):
                continue
            if line:
                clean_lines.append(line)

        response = ' '.join(clean_lines)

        response = re.sub(r'\s*\([^)]*(?:corrected|fixed|changed|removed|korrigiert|geändert)[^)]*\)\s*', ' ', response, flags=re.IGNORECASE)
        response = re.sub(r'\s*\[[^\]]*(?:corrected|fixed|changed|removed|korrigiert|geändert)[^\]]*\]\s*', ' ', response, flags=re.IGNORECASE)

        ai_commentary_patterns = [
            r'(?:also,?\s*)?if you have any questions.*$',
            r'feel free to ask.*$',
            r'i(?:\'m| am) here to help.*$',
            r'(?:i )?hope this helps.*$',
            r'let me know if.*$',
            r'please (?:provide|let me know).*$',
            r'thank you for (?:using|your).*$',
            r'this is a (?:correct|proper|simple|common).*$',
            r'the (?:text|sentence|phrase|word) (?:is|means|translates).*$',
            r'in (?:german|english),?\s*(?:this|it|the).*$',
            r'(?:it|this) (?:literally|basically|essentially) (?:means|translates).*$',
            r'(?:it|this) (?:is|can be) (?:often|commonly|frequently) used.*$',
            r'bei fragen.*$',
            r'wenn (?:du|sie) fragen.*$',
            r'ich hoffe.*$',
        ]
        for pattern in ai_commentary_patterns:
            response = re.sub(pattern, '', response, flags=re.IGNORECASE)

        markers = [
            '\n\nCorrection:', '\nCorrection:', 'Correction:',
            '\n\nCorrected:', '\nCorrected:', 'Corrected:',
            '\n\nExplanation:', '\nExplanation:', 'Explanation:',
            '\n\nNote:', '\nNote:', 'Note:',
            'Here is', 'Here\'s', 'The corrected',
            '\n\nKorrigiert:', '\nKorrigiert:', 'Korrigiert:',
            'Hier ist', 'Die korrigierte',
        ]

        first_cut = len(response)
        for marker in markers:
            idx = response.lower().find(marker.lower())
            if idx > 0 and idx < first_cut:
                first_cut = idx

        response = response[:first_cut].strip()

        sentences = re.split(r'(?<=[.!?])\s+', response)
        seen = set()
        unique_sentences = []
        for s in sentences:
            s_clean = s.strip().lower()
            if s_clean and s_clean not in seen:
                seen.add(s_clean)
                unique_sentences.append(s.strip())

        response = ' '.join(unique_sentences)

        if response and response[-1] not in '.!?':
            last_sentence = max(
                response.rfind('.'),
                response.rfind('!'),
                response.rfind('?')
            )
            if last_sentence > len(response) * 0.3:
                response = response[:last_sentence + 1]

        response = re.sub(r'\s+', ' ', response).strip()

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

        text = self._apply_known_corrections(text)

        if USE_MLX_AI and self._load_model() and self._mlx_available:
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
            ],
            "en": [
                r'\buh+\b', r'\bum+\b', r'\bhm+\b', r'\ber+\b',
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

        training_info = f", {len(self._training_pairs)} training examples" if self._training_pairs else ""

        return {
            'mlx_available': self._mlx_available,
            'model': MLX_MODEL if self._mlx_available else None,
            'fallback': 'LanguageTool',
            'training_pairs': len(self._training_pairs),
            'word_corrections': len(self._word_alignments.get('word_corrections', {})),
            'message': (
                f'AI correction ready (MLX/Qwen2.5-3B){training_info}'
                if self._mlx_available
                else f'Using LanguageTool (MLX requires Apple Silicon){training_info}'
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
