import os
import json
import re
from typing import Dict, List, Optional, Tuple

VOCABULARY_PATH = os.path.expanduser("~/Documents/voice-notes/data/custom_vocabulary.json")

def load_vocabulary() -> Dict[str, str]:
    if not os.path.exists(VOCABULARY_PATH):
        return {}
    try:
        with open(VOCABULARY_PATH, 'r', encoding='utf-8') as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return {}

def save_vocabulary(vocab: Dict[str, str]) -> bool:
    os.makedirs(os.path.dirname(VOCABULARY_PATH), exist_ok=True)
    try:
        with open(VOCABULARY_PATH, 'w', encoding='utf-8') as f:
            json.dump(vocab, f, ensure_ascii=False, indent=2)
        return True
    except IOError:
        return False

def add_word(phonetic: str, spelling: str) -> bool:
    if not phonetic or not spelling:
        return False
    phonetic = phonetic.strip().lower()
    spelling = spelling.strip()
    if not phonetic or not spelling:
        return False
    vocab = load_vocabulary()
    vocab[phonetic] = spelling
    return save_vocabulary(vocab)

def remove_word(phonetic: str) -> bool:
    phonetic = phonetic.strip().lower()
    vocab = load_vocabulary()
    if phonetic in vocab:
        del vocab[phonetic]
        return save_vocabulary(vocab)
    return False

def get_all_words() -> List[Dict[str, str]]:
    vocab = load_vocabulary()
    return [{"phonetic": p, "spelling": s} for p, s in sorted(vocab.items())]

def apply_vocabulary(text: str) -> str:
    if not text:
        return text
    vocab = load_vocabulary()
    if not vocab:
        return text
    result = text
    for phonetic, spelling in vocab.items():
        pattern = re.compile(re.escape(phonetic), re.IGNORECASE)
        result = pattern.sub(spelling, result)
    return result

def apply_vocabulary_fuzzy(text: str, threshold: float = 0.8) -> Tuple[str, List[Dict]]:
    if not text:
        return text, []
    vocab = load_vocabulary()
    if not vocab:
        return text, []
    replacements = []
    result = text
    words = text.split()
    for i, word in enumerate(words):
        word_lower = word.lower().strip('.,!?;:')
        for phonetic, spelling in vocab.items():
            if word_lower == phonetic:
                clean_word = word.strip('.,!?;:')
                punctuation = word[len(clean_word):]
                new_word = spelling + punctuation
                if word[0].isupper() and spelling[0].islower():
                    new_word = spelling[0].upper() + spelling[1:] + punctuation
                words[i] = new_word
                replacements.append({
                    "original": clean_word,
                    "replacement": spelling,
                    "position": i
                })
                break
    result = ' '.join(words)
    return result, replacements

def get_vocabulary_count() -> int:
    return len(load_vocabulary())
