import json
import re
import os
import threading
from collections import defaultdict, Counter
from typing import Optional, List, Dict, Tuple, Set
from pathlib import Path
from datetime import datetime
import difflib
import math

LEARNING_DATA_DIR = Path(__file__).parent.parent / "learning_data"
LEARNING_DATA_DIR.mkdir(parents=True, exist_ok=True)

TRAINING_PAIRS_FILE = LEARNING_DATA_DIR / "training_pairs.jsonl"
LEARNED_PATTERNS_FILE = LEARNING_DATA_DIR / "learned_patterns.json"
NGRAM_MODEL_FILE = LEARNING_DATA_DIR / "ngram_model.json"
WORD_ALIGNMENTS_FILE = LEARNING_DATA_DIR / "word_alignments.json"
CORRECTION_STATS_FILE = LEARNING_DATA_DIR / "correction_stats.json"

MIN_PATTERN_OCCURRENCES = 2
NGRAM_SIZES = [2, 3, 4, 5]
CHAR_NGRAM_SIZES = [3, 4, 5]
CONFIDENCE_THRESHOLD = 0.7
MAX_EDIT_DISTANCE_RATIO = 0.4
MIN_WORD_LENGTH = 4

PROTECTED_WORDS = {
    'das', 'die', 'der', 'den', 'dem', 'des',
    'ist', 'sind', 'war', 'hat', 'haben',
    'ich', 'du', 'er', 'sie', 'es', 'wir',
    'ein', 'eine', 'einer', 'einem', 'einen',
    'und', 'oder', 'aber', 'wenn', 'weil',
    'auf', 'in', 'an', 'mit', 'von', 'zu',
    'nicht', 'auch', 'noch', 'nur', 'sehr',
}


class TrainingPair:

    def __init__(self, incorrect: str, correct: str,
                 context: Optional[str] = None,
                 timestamp: Optional[str] = None):
        self.incorrect = incorrect
        self.correct = correct
        self.context = context or ""
        self.timestamp = timestamp or datetime.now().isoformat()

    def to_dict(self) -> dict:
        return {
            "incorrect": self.incorrect,
            "correct": self.correct,
            "context": self.context,
            "timestamp": self.timestamp
        }

    @classmethod
    def from_dict(cls, data: dict) -> "TrainingPair":
        return cls(
            incorrect=data["incorrect"],
            correct=data["correct"],
            context=data.get("context", ""),
            timestamp=data.get("timestamp")
        )


class LearnedPattern:

    def __init__(self, pattern_type: str, incorrect: str, correct: str,
                 confidence: float = 0.0, occurrences: int = 0,
                 contexts: List[str] = None):
        self.pattern_type = pattern_type
        self.incorrect = incorrect
        self.correct = correct
        self.confidence = confidence
        self.occurrences = occurrences
        self.contexts = contexts or []

    def to_dict(self) -> dict:
        return {
            "pattern_type": self.pattern_type,
            "incorrect": self.incorrect,
            "correct": self.correct,
            "confidence": self.confidence,
            "occurrences": self.occurrences,
            "contexts": self.contexts[:10]
        }

    @classmethod
    def from_dict(cls, data: dict) -> "LearnedPattern":
        return cls(**data)


class TextAligner:

    @staticmethod
    def align_texts(incorrect: str, correct: str) -> List[Tuple[str, str]]:
        inc_words = incorrect.split()
        cor_words = correct.split()

        matcher = difflib.SequenceMatcher(None, inc_words, cor_words)
        alignments = []

        for tag, i1, i2, j1, j2 in matcher.get_opcodes():
            if tag == 'replace':
                inc_phrase = ' '.join(inc_words[i1:i2])
                cor_phrase = ' '.join(cor_words[j1:j2])
                if inc_phrase != cor_phrase:
                    alignments.append((inc_phrase, cor_phrase))
            elif tag == 'delete':
                inc_phrase = ' '.join(inc_words[i1:i2])
                alignments.append((inc_phrase, ''))
            elif tag == 'insert':
                cor_phrase = ' '.join(cor_words[j1:j2])
                alignments.append(('', cor_phrase))

        return alignments

    @staticmethod
    def extract_word_corrections(incorrect: str, correct: str) -> Dict[str, str]:
        alignments = TextAligner.align_texts(incorrect, correct)
        word_corrections = {}

        for inc, cor in alignments:
            if ' ' not in inc and ' ' not in cor and inc and cor:
                word_corrections[inc] = cor
            elif ' ' not in inc and inc and cor:
                word_corrections[inc] = cor
            elif inc and cor:
                word_corrections[inc] = cor

        return word_corrections


class PatternExtractor:

    @staticmethod
    def extract_char_patterns(incorrect: str, correct: str) -> List[Tuple[str, str]]:
        patterns = []

        prefix_len = 0
        for i in range(min(len(incorrect), len(correct))):
            if incorrect[i] == correct[i]:
                prefix_len += 1
            else:
                break

        suffix_len = 0
        for i in range(1, min(len(incorrect), len(correct)) - prefix_len + 1):
            if incorrect[-i] == correct[-i]:
                suffix_len += 1
            else:
                break

        if prefix_len > 0 or suffix_len > 0:
            inc_middle = incorrect[prefix_len:len(incorrect)-suffix_len if suffix_len else None]
            cor_middle = correct[prefix_len:len(correct)-suffix_len if suffix_len else None]

            if inc_middle != cor_middle:
                patterns.append((inc_middle, cor_middle))

        return patterns

    @staticmethod
    def extract_ngrams(text: str, n: int) -> List[str]:
        words = text.split()
        if len(words) < n:
            return []
        return [' '.join(words[i:i+n]) for i in range(len(words) - n + 1)]

    @staticmethod
    def extract_char_ngrams(word: str, n: int) -> Set[str]:
        if len(word) < n:
            return set()
        return {word[i:i+n] for i in range(len(word) - n + 1)}

    @staticmethod
    def phonetic_hash(word: str) -> str:
        word = word.lower()

        replacements = [
            ('sch', 'S'),
            ('ch', 'X'),
            ('ck', 'K'),
            ('ph', 'F'),
            ('qu', 'KV'),
            ('ß', 'S'),
            ('ae', 'E'),
            ('oe', 'O'),
            ('ue', 'U'),
            ('ä', 'E'),
            ('ö', 'O'),
            ('ü', 'U'),
            ('ei', 'AI'),
            ('ie', 'I'),
            ('eu', 'OI'),
            ('äu', 'OI'),
            ('au', 'AU'),
            ('th', 'T'),
            ('dt', 'T'),
            ('v', 'F'),
            ('w', 'V'),
            ('z', 'TS'),
            ('c', 'K'),
            ('x', 'KS'),
            ('y', 'I'),
        ]

        result = word
        for old, new in replacements:
            result = result.replace(old, new)

        prev = ''
        cleaned = ''
        for c in result:
            if c != prev:
                cleaned += c
                prev = c

        return cleaned


class LearningEngine:

    def __init__(self):
        self._lock = threading.Lock()
        self._training_pairs: List[TrainingPair] = []
        self._learned_patterns: Dict[str, LearnedPattern] = {}
        self._word_corrections: Dict[str, Counter] = defaultdict(Counter)
        self._phrase_corrections: Dict[str, Counter] = defaultdict(Counter)
        self._ngram_corrections: Dict[str, Counter] = defaultdict(Counter)
        self._phonetic_clusters: Dict[str, Set[str]] = defaultdict(set)
        self._context_associations: Dict[str, Set[str]] = defaultdict(set)
        self._stats = {
            "total_pairs": 0,
            "unique_word_corrections": 0,
            "unique_phrase_corrections": 0,
            "last_trained": None
        }

        self._load_data()

    def _load_data(self):
        if TRAINING_PAIRS_FILE.exists():
            try:
                with open(TRAINING_PAIRS_FILE, 'r', encoding='utf-8') as f:
                    for line in f:
                        try:
                            data = json.loads(line.strip())
                            self._training_pairs.append(TrainingPair.from_dict(data))
                        except:
                            continue
            except Exception as e:
                print(f"Error loading training pairs: {e}")

        if LEARNED_PATTERNS_FILE.exists():
            try:
                with open(LEARNED_PATTERNS_FILE, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    for key, pattern_data in data.get("patterns", {}).items():
                        self._learned_patterns[key] = LearnedPattern.from_dict(pattern_data)
                    self._stats = data.get("stats", self._stats)
            except Exception as e:
                print(f"Error loading learned patterns: {e}")

        if WORD_ALIGNMENTS_FILE.exists():
            try:
                with open(WORD_ALIGNMENTS_FILE, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    for key, counts in data.get("word_corrections", {}).items():
                        self._word_corrections[key] = Counter(counts)
                    for key, counts in data.get("phrase_corrections", {}).items():
                        self._phrase_corrections[key] = Counter(counts)
            except Exception as e:
                print(f"Error loading word alignments: {e}")

    def _save_data(self):
        with self._lock:
            try:
                patterns_data = {
                    "patterns": {k: v.to_dict() for k, v in self._learned_patterns.items()},
                    "stats": self._stats
                }
                with open(LEARNED_PATTERNS_FILE, 'w', encoding='utf-8') as f:
                    json.dump(patterns_data, f, ensure_ascii=False, indent=2)
            except Exception as e:
                print(f"Error saving learned patterns: {e}")

            try:
                alignments_data = {
                    "word_corrections": {k: dict(v) for k, v in self._word_corrections.items()},
                    "phrase_corrections": {k: dict(v) for k, v in self._phrase_corrections.items()}
                }
                with open(WORD_ALIGNMENTS_FILE, 'w', encoding='utf-8') as f:
                    json.dump(alignments_data, f, ensure_ascii=False, indent=2)
            except Exception as e:
                print(f"Error saving word alignments: {e}")

    def add_training_pair(self, incorrect: str, correct: str, context: str = "") -> dict:
        pair = TrainingPair(incorrect, correct, context)

        with self._lock:
            self._training_pairs.append(pair)

            try:
                with open(TRAINING_PAIRS_FILE, 'a', encoding='utf-8') as f:
                    f.write(json.dumps(pair.to_dict(), ensure_ascii=False) + '\n')
            except Exception as e:
                print(f"Error saving training pair: {e}")

        self._learn_from_pair(pair)
        self._save_data()

        return {
            "status": "added",
            "total_pairs": len(self._training_pairs),
            "patterns_learned": len(self._learned_patterns)
        }

    def _learn_from_pair(self, pair: TrainingPair):
        incorrect = pair.incorrect
        correct = pair.correct

        word_corrections = TextAligner.extract_word_corrections(incorrect, correct)
        for inc_word, cor_word in word_corrections.items():
            if inc_word and cor_word:
                self._word_corrections[inc_word.lower()][cor_word] += 1

                inc_hash = PatternExtractor.phonetic_hash(inc_word)
                cor_hash = PatternExtractor.phonetic_hash(cor_word)
                self._phonetic_clusters[inc_hash].add(cor_word)
                self._phonetic_clusters[cor_hash].add(cor_word)

        alignments = TextAligner.align_texts(incorrect, correct)
        for inc_phrase, cor_phrase in alignments:
            if inc_phrase and cor_phrase and ' ' in inc_phrase:
                self._phrase_corrections[inc_phrase.lower()][cor_phrase] += 1

        for n in NGRAM_SIZES:
            inc_ngrams = PatternExtractor.extract_ngrams(incorrect.lower(), n)
            cor_ngrams = PatternExtractor.extract_ngrams(correct.lower(), n)

            for i, (inc_ng, cor_ng) in enumerate(zip(inc_ngrams, cor_ngrams)):
                if inc_ng != cor_ng:
                    self._ngram_corrections[inc_ng][cor_ng] += 1

        context_words = set(re.findall(r'\b[A-Za-zÄÖÜäöüß]{4,}\b', pair.context.lower()))
        for inc_word in word_corrections.keys():
            self._context_associations[inc_word.lower()].update(context_words)

        self._update_learned_patterns()

    def _update_learned_patterns(self):
        for incorrect, corrections in self._word_corrections.items():
            most_common = corrections.most_common(1)
            if most_common:
                correct, count = most_common[0]
                if count >= MIN_PATTERN_OCCURRENCES:
                    total = sum(corrections.values())
                    confidence = count / total

                    pattern_key = f"word:{incorrect}"
                    self._learned_patterns[pattern_key] = LearnedPattern(
                        pattern_type="word",
                        incorrect=incorrect,
                        correct=correct,
                        confidence=confidence,
                        occurrences=count,
                        contexts=list(self._context_associations.get(incorrect, []))[:10]
                    )

        for incorrect, corrections in self._phrase_corrections.items():
            most_common = corrections.most_common(1)
            if most_common:
                correct, count = most_common[0]
                if count >= MIN_PATTERN_OCCURRENCES:
                    total = sum(corrections.values())
                    confidence = count / total

                    pattern_key = f"phrase:{incorrect}"
                    self._learned_patterns[pattern_key] = LearnedPattern(
                        pattern_type="phrase",
                        incorrect=incorrect,
                        correct=correct,
                        confidence=confidence,
                        occurrences=count
                    )

        self._stats["total_pairs"] = len(self._training_pairs)
        self._stats["unique_word_corrections"] = len(self._word_corrections)
        self._stats["unique_phrase_corrections"] = len(self._phrase_corrections)
        self._stats["last_trained"] = datetime.now().isoformat()

    def train_from_all_pairs(self):
        with self._lock:
            self._word_corrections.clear()
            self._phrase_corrections.clear()
            self._ngram_corrections.clear()
            self._phonetic_clusters.clear()
            self._context_associations.clear()
            self._learned_patterns.clear()

            for pair in self._training_pairs:
                self._learn_from_pair(pair)

            self._save_data()

        return {
            "status": "trained",
            "total_pairs": len(self._training_pairs),
            "patterns_learned": len(self._learned_patterns),
            "word_corrections": len(self._word_corrections),
            "phrase_corrections": len(self._phrase_corrections)
        }

    def get_correction(self, word: str, context: List[str] = None) -> Optional[Tuple[str, float]]:
        word_lower = word.lower()

        if word_lower in PROTECTED_WORDS:
            return None
        if len(word) < MIN_WORD_LENGTH:
            return None

        pattern_key = f"word:{word_lower}"
        if pattern_key in self._learned_patterns:
            pattern = self._learned_patterns[pattern_key]
            if pattern.confidence >= CONFIDENCE_THRESHOLD:
                correction = pattern.correct
                if word[0].isupper() and correction[0].islower():
                    correction = correction[0].upper() + correction[1:]
                return correction, pattern.confidence

        word_hash = PatternExtractor.phonetic_hash(word)
        if word_hash in self._phonetic_clusters:
            candidates = self._phonetic_clusters[word_hash]
            best_match = None
            best_score = 0

            for candidate in candidates:
                if candidate.lower() != word_lower:
                    ratio = difflib.SequenceMatcher(None, word_lower, candidate.lower()).ratio()
                    if ratio > best_score and ratio >= 0.6:
                        best_match = candidate
                        best_score = ratio

            if best_match and best_score >= CONFIDENCE_THRESHOLD:
                if word[0].isupper() and best_match[0].islower():
                    best_match = best_match[0].upper() + best_match[1:]
                return best_match, best_score

        return None

    def get_phrase_correction(self, phrase: str) -> Optional[Tuple[str, float]]:
        phrase_lower = phrase.lower()

        pattern_key = f"phrase:{phrase_lower}"
        if pattern_key in self._learned_patterns:
            pattern = self._learned_patterns[pattern_key]
            if pattern.confidence >= CONFIDENCE_THRESHOLD:
                return pattern.correct, pattern.confidence

        return None

    def get_stats(self) -> dict:
        return {
            **self._stats,
            "total_patterns": len(self._learned_patterns),
            "phonetic_clusters": len(self._phonetic_clusters)
        }


class LearningCorrector:

    def __init__(self):
        self.engine = LearningEngine()
        self._phrase_cache: Dict[str, Tuple[str, float]] = {}

    def correct(self, text: str, context: str = "") -> Tuple[str, List[dict]]:
        corrections_made = []
        result = text

        phrase_patterns = sorted(
            [(k, v) for k, v in self.engine._learned_patterns.items()
             if v.pattern_type == "phrase"],
            key=lambda x: len(x[1].incorrect),
            reverse=True
        )

        for pattern_key, pattern in phrase_patterns:
            if pattern.confidence >= CONFIDENCE_THRESHOLD:
                if pattern.incorrect.lower() in result.lower():
                    regex = re.compile(re.escape(pattern.incorrect), re.IGNORECASE)
                    new_result = regex.sub(pattern.correct, result)

                    if new_result != result:
                        corrections_made.append({
                            "type": "phrase",
                            "original": pattern.incorrect,
                            "corrected": pattern.correct,
                            "confidence": pattern.confidence
                        })
                        result = new_result

        words = re.findall(r'\b[A-Za-zÄÖÜäöüß]+\b', result)
        context_words = re.findall(r'\b[A-Za-zÄÖÜäöüß]+\b', context.lower())

        for word in words:
            correction = self.engine.get_correction(word, context_words)
            if correction:
                corrected_word, confidence = correction
                if corrected_word.lower() != word.lower():
                    pattern = re.compile(r'\b' + re.escape(word) + r'\b')
                    new_result = pattern.sub(corrected_word, result, count=1)

                    if new_result != result:
                        corrections_made.append({
                            "type": "word",
                            "original": word,
                            "corrected": corrected_word,
                            "confidence": confidence
                        })
                        result = new_result

        return result, corrections_made

    def add_training_example(self, incorrect: str, correct: str, context: str = "") -> dict:
        return self.engine.add_training_pair(incorrect, correct, context)

    def retrain(self) -> dict:
        return self.engine.train_from_all_pairs()

    def get_stats(self) -> dict:
        return self.engine.get_stats()


_learning_corrector: Optional[LearningCorrector] = None
_corrector_lock = threading.Lock()


def get_learning_corrector() -> LearningCorrector:
    global _learning_corrector
    if _learning_corrector is None:
        with _corrector_lock:
            if _learning_corrector is None:
                _learning_corrector = LearningCorrector()
    return _learning_corrector


def add_training_pair(incorrect: str, correct: str, context: str = "") -> dict:
    return get_learning_corrector().add_training_example(incorrect, correct, context)


def correct_with_learning(text: str, context: str = "") -> str:
    corrected, _ = get_learning_corrector().correct(text, context)
    return corrected


def correct_with_details(text: str, context: str = "") -> Tuple[str, List[dict]]:
    return get_learning_corrector().correct(text, context)


def retrain_model() -> dict:
    return get_learning_corrector().retrain()


def get_learning_stats() -> dict:
    return get_learning_corrector().get_stats()


def bulk_add_training_pairs(pairs: List[Tuple[str, str]]) -> dict:
    corrector = get_learning_corrector()
    for incorrect, correct in pairs:
        corrector.add_training_example(incorrect, correct)
    return corrector.retrain()
