"""
Smart Post-Processor for Voice Notes
=====================================

A multi-pass, context-aware post-processing system that:
1. Analyzes text in real-time during transcription
2. Performs comprehensive final-pass analysis
3. Detects semantically incoherent words (topic outliers)
4. Replaces nonsensical words based on context + phonetic similarity
5. Verifies corrections with retry logic (max 3 attempts)
6. Logs unresolved issues for review

This system is designed to be extremely thorough and precise.
"""

import re
import json
import math
import threading
from collections import Counter, defaultdict
from typing import Optional, List, Dict, Tuple, Set
from pathlib import Path
from datetime import datetime
from dataclasses import dataclass, field
import difflib

# Try to import extended vocabulary data
try:
    from german_vocabulary import (
        WHISPER_ERROR_CORRECTIONS,
        SEMANTIC_CLUSTERS,
        PHONETIC_WORD_GROUPS,
        ACADEMIC_VOCABULARY,
        PHRASE_CORRECTIONS,
        get_correction_candidates,
        get_semantic_cluster,
        is_academic_term,
        apply_phrase_corrections,
    )
    EXTENDED_VOCAB_AVAILABLE = True
except ImportError:
    EXTENDED_VOCAB_AVAILABLE = False
    WHISPER_ERROR_CORRECTIONS = {}
    SEMANTIC_CLUSTERS = {}
    PHONETIC_WORD_GROUPS = {}
    ACADEMIC_VOCABULARY = {}
    PHRASE_CORRECTIONS = {}
    apply_phrase_corrections = lambda x: x  # No-op fallback

# Try to import learning-based corrector
try:
    from learning_corrector import correct_with_learning, get_learning_stats
    LEARNING_CORRECTOR_AVAILABLE = True
except ImportError:
    LEARNING_CORRECTOR_AVAILABLE = False
    correct_with_learning = lambda x, c="": x  # No-op fallback

# ============================================================================
# CONFIGURATION
# ============================================================================

POSTPROCESSOR_LOG_DIR = Path(__file__).parent.parent / "postprocessor_logs"
POSTPROCESSOR_LOG_DIR.mkdir(parents=True, exist_ok=True)

MAX_CORRECTION_ATTEMPTS = 3
SEMANTIC_OUTLIER_THRESHOLD = 0.15  # Lower = more conservative (fewer false positives)
PHONETIC_SIMILARITY_THRESHOLD = 0.80  # Higher = more strict matching
MIN_WORD_LENGTH_FOR_ANALYSIS = 4  # Minimum word length to check (includes "Offen" etc.)
CONTEXT_WINDOW_SIZE = 50  # words before/after for context
MIN_REPLACEMENT_CONFIDENCE = 0.90  # Minimum confidence to actually replace a word
ONLY_REPLACE_KNOWN_ERRORS = True  # Only replace words in known error list

# ============================================================================
# DATA CLASSES
# ============================================================================

@dataclass
class WordAnalysis:
    """Analysis result for a single word."""
    word: str
    position: int
    sentence_index: int
    is_outlier: bool = False
    outlier_score: float = 0.0
    context_words: List[str] = field(default_factory=list)
    suggested_replacements: List[Tuple[str, float]] = field(default_factory=list)
    issue_type: Optional[str] = None
    resolved: bool = False
    replacement_used: Optional[str] = None
    attempts: int = 0


@dataclass
class SentenceAnalysis:
    """Analysis result for a sentence."""
    text: str
    index: int
    words: List[str] = field(default_factory=list)
    topic_keywords: List[str] = field(default_factory=list)
    grammar_issues: List[Dict] = field(default_factory=list)
    logic_issues: List[Dict] = field(default_factory=list)
    word_analyses: List[WordAnalysis] = field(default_factory=list)
    corrected_text: Optional[str] = None
    confidence: float = 1.0


@dataclass
class DocumentAnalysis:
    """Full document analysis."""
    original_text: str
    sentences: List[SentenceAnalysis] = field(default_factory=list)
    global_topic: Optional[str] = None
    topic_keywords: List[str] = field(default_factory=list)
    word_frequency: Dict[str, int] = field(default_factory=dict)
    unresolved_issues: List[Dict] = field(default_factory=list)
    corrected_text: Optional[str] = None
    processing_log: List[str] = field(default_factory=list)


# ============================================================================
# GERMAN LANGUAGE DATA
# ============================================================================

class GermanLanguageData:
    """Comprehensive German language data for analysis."""

    # Common German words that should rarely be flagged as outliers
    COMMON_WORDS = {
        # Articles & Pronouns
        'der', 'die', 'das', 'den', 'dem', 'des', 'ein', 'eine', 'einer', 'eines', 'einem', 'einen',
        'ich', 'du', 'er', 'sie', 'es', 'wir', 'ihr', 'sie', 'Sie',
        'mein', 'dein', 'sein', 'ihr', 'unser', 'euer', 'ihr',
        'dieser', 'diese', 'dieses', 'jener', 'jene', 'jenes',
        'welcher', 'welche', 'welches', 'was', 'wer', 'wen', 'wem', 'wessen',
        'man', 'sich', 'selbst', 'einander',

        # Prepositions
        'in', 'an', 'auf', 'aus', 'bei', 'durch', 'für', 'gegen', 'hinter', 'mit',
        'nach', 'neben', 'ohne', 'über', 'um', 'unter', 'von', 'vor', 'zu', 'zwischen',
        'während', 'wegen', 'trotz', 'statt', 'anstatt', 'außer', 'gegenüber',

        # Conjunctions
        'und', 'oder', 'aber', 'denn', 'sondern', 'doch', 'jedoch', 'weil', 'dass',
        'wenn', 'ob', 'als', 'obwohl', 'damit', 'sodass', 'bevor', 'nachdem', 'sobald',
        'falls', 'sofern', 'während', 'indem', 'weder', 'noch', 'sowohl', 'als auch',

        # Common verbs
        'sein', 'haben', 'werden', 'können', 'müssen', 'sollen', 'wollen', 'dürfen', 'mögen',
        'ist', 'sind', 'war', 'waren', 'hat', 'hatte', 'haben', 'hatten',
        'wird', 'werden', 'wurde', 'wurden', 'kann', 'können', 'konnte', 'konnten',
        'muss', 'müssen', 'musste', 'mussten', 'soll', 'sollen', 'sollte', 'sollten',
        'will', 'wollen', 'wollte', 'wollten', 'darf', 'dürfen', 'durfte', 'durften',
        'macht', 'machen', 'machte', 'gemacht', 'geht', 'gehen', 'ging', 'gegangen',
        'kommt', 'kommen', 'kam', 'gekommen', 'gibt', 'geben', 'gab', 'gegeben',
        'nimmt', 'nehmen', 'nahm', 'genommen', 'sieht', 'sehen', 'sah', 'gesehen',
        'weiß', 'wissen', 'wusste', 'gewusst', 'denkt', 'denken', 'dachte', 'gedacht',
        'sagt', 'sagen', 'sagte', 'gesagt', 'heißt', 'heißen', 'hieß', 'geheißen',

        # Adverbs
        'nicht', 'auch', 'noch', 'schon', 'nur', 'sehr', 'so', 'wie', 'dann', 'da',
        'hier', 'dort', 'wo', 'wann', 'warum', 'weshalb', 'wieso', 'wozu', 'woher', 'wohin',
        'immer', 'nie', 'niemals', 'manchmal', 'oft', 'selten', 'wieder', 'bereits',
        'jetzt', 'heute', 'morgen', 'gestern', 'bald', 'später', 'früher', 'gleich',
        'vielleicht', 'wirklich', 'eigentlich', 'natürlich', 'wahrscheinlich', 'bestimmt',
        'ganz', 'ziemlich', 'besonders', 'etwas', 'nichts', 'alles', 'viel', 'wenig',
        'mehr', 'weniger', 'am meisten', 'am wenigsten', 'genug', 'zu', 'fast', 'kaum',
        'etwa', 'ungefähr', 'circa', 'mindestens', 'höchstens', 'wenigstens', 'zumindest',
        'also', 'ja', 'nein', 'doch', 'eben', 'halt', 'mal', 'wohl', 'etwa', 'bloß',

        # Adjectives (common)
        'gut', 'schlecht', 'groß', 'klein', 'alt', 'neu', 'jung', 'lang', 'kurz',
        'hoch', 'niedrig', 'tief', 'breit', 'schmal', 'dick', 'dünn', 'schwer', 'leicht',
        'schnell', 'langsam', 'stark', 'schwach', 'hart', 'weich', 'hell', 'dunkel',
        'warm', 'kalt', 'heiß', 'kühl', 'nass', 'trocken', 'sauber', 'schmutzig',
        'richtig', 'falsch', 'wahr', 'wichtig', 'unwichtig', 'nötig', 'möglich', 'unmöglich',
        'einfach', 'schwierig', 'leicht', 'kompliziert', 'klar', 'unklar', 'deutlich',
        'schön', 'hässlich', 'interessant', 'langweilig', 'toll', 'super', 'prima',
        'erste', 'zweite', 'dritte', 'letzte', 'nächste', 'andere', 'gleiche', 'selbe',
        'ganze', 'halbe', 'viele', 'wenige', 'einige', 'manche', 'alle', 'keine', 'jede',

        # Numbers
        'eins', 'zwei', 'drei', 'vier', 'fünf', 'sechs', 'sieben', 'acht', 'neun', 'zehn',
        'elf', 'zwölf', 'dreizehn', 'vierzehn', 'fünfzehn', 'sechzehn', 'siebzehn',
        'achtzehn', 'neunzehn', 'zwanzig', 'dreißig', 'vierzig', 'fünfzig', 'sechzig',
        'siebzig', 'achtzig', 'neunzig', 'hundert', 'tausend', 'million', 'milliarde',

        # Time expressions
        'Uhr', 'Minute', 'Stunde', 'Tag', 'Woche', 'Monat', 'Jahr',
        'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag',
        'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August',
        'September', 'Oktober', 'November', 'Dezember',
    }

    # Topic categories with associated keywords
    TOPIC_KEYWORDS = {
        'technologie': {
            'Computer', 'Software', 'Hardware', 'Programm', 'Programmierung', 'Code',
            'Algorithmus', 'Daten', 'Internet', 'Netzwerk', 'Server', 'Cloud',
            'Künstliche', 'Intelligenz', 'KI', 'AI', 'Machine', 'Learning', 'Lernen',
            'Maschine', 'Roboter', 'Automatisierung', 'Digital', 'App', 'Anwendung',
            'System', 'Prozessor', 'Speicher', 'Datenbank', 'API', 'Framework',
            'Python', 'JavaScript', 'Java', 'Entwicklung', 'Developer', 'Entwickler',
            'Bug', 'Feature', 'Update', 'Version', 'Release', 'Deploy', 'Deployment',
        },
        'wissenschaft': {
            'Forschung', 'Studie', 'Experiment', 'Hypothese', 'Theorie', 'Beweis',
            'Wissenschaft', 'Wissenschaftler', 'Labor', 'Analyse', 'Ergebnis',
            'Methode', 'Daten', 'Statistik', 'Messung', 'Observation', 'Beobachtung',
            'Publikation', 'Paper', 'Artikel', 'Journal', 'Peer', 'Review',
        },
        'medizin': {
            'Patient', 'Arzt', 'Ärztin', 'Krankenhaus', 'Klinik', 'Behandlung',
            'Therapie', 'Medikament', 'Diagnose', 'Symptom', 'Krankheit', 'Gesundheit',
            'Operation', 'Chirurgie', 'Pflege', 'Heilung', 'Prävention', 'Impfung',
            'Virus', 'Bakterie', 'Infektion', 'Immunsystem', 'Blut', 'Herz', 'Lunge',
        },
        'wirtschaft': {
            'Unternehmen', 'Firma', 'Geschäft', 'Business', 'Markt', 'Handel',
            'Investition', 'Kapital', 'Gewinn', 'Verlust', 'Umsatz', 'Kosten',
            'Budget', 'Finanzen', 'Bank', 'Kredit', 'Aktie', 'Börse', 'Anlage',
            'Management', 'Strategie', 'Marketing', 'Vertrieb', 'Produkt', 'Kunde',
            'Mitarbeiter', 'Gehalt', 'Lohn', 'Steuer', 'Wirtschaft', 'Ökonomie',
        },
        'bildung': {
            'Schule', 'Universität', 'Hochschule', 'Studium', 'Student', 'Schüler',
            'Lehrer', 'Professor', 'Dozent', 'Unterricht', 'Vorlesung', 'Seminar',
            'Prüfung', 'Klausur', 'Test', 'Note', 'Abschluss', 'Diplom', 'Bachelor',
            'Master', 'Doktor', 'Promotion', 'Bildung', 'Lernen', 'Wissen', 'Fach',
        },
        'politik': {
            'Regierung', 'Parlament', 'Gesetz', 'Politik', 'Politiker', 'Partei',
            'Wahl', 'Abstimmung', 'Demokratie', 'Staat', 'Nation', 'Land',
            'Minister', 'Kanzler', 'Präsident', 'Opposition', 'Koalition',
            'Reform', 'Beschluss', 'Antrag', 'Debatte', 'Diskussion',
        },
        'kunst': {
            'Kunst', 'Künstler', 'Maler', 'Malerei', 'Gemälde', 'Bild', 'Skulptur',
            'Museum', 'Galerie', 'Ausstellung', 'Musik', 'Musiker', 'Komponist',
            'Konzert', 'Orchester', 'Theater', 'Bühne', 'Schauspieler', 'Film',
            'Literatur', 'Autor', 'Buch', 'Roman', 'Gedicht', 'Poesie',
        },
        'sport': {
            'Sport', 'Sportler', 'Athlet', 'Training', 'Wettkampf', 'Spiel',
            'Mannschaft', 'Team', 'Trainer', 'Sieg', 'Niederlage', 'Meisterschaft',
            'Turnier', 'Liga', 'Fußball', 'Tennis', 'Basketball', 'Schwimmen',
            'Laufen', 'Marathon', 'Olympia', 'Olympische', 'Medaille', 'Rekord',
        },
        'natur': {
            'Natur', 'Umwelt', 'Klima', 'Wetter', 'Tier', 'Pflanze', 'Baum', 'Wald',
            'Berg', 'Fluss', 'See', 'Meer', 'Ozean', 'Erde', 'Luft', 'Wasser',
            'Ökologie', 'Ökosystem', 'Artenschutz', 'Nachhaltigkeit', 'Recycling',
            'Energie', 'Solar', 'Wind', 'Erneuerbar', 'CO2', 'Emission',
        },
    }

    # Phonetic confusion pairs in German (Whisper often confuses these)
    PHONETIC_CONFUSIONS = {
        # Vowel confusions
        'ei': ['ai', 'ey', 'ay', 'i'],
        'ie': ['i', 'ih', 'ieh'],
        'eu': ['oi', 'äu', 'oy'],
        'äu': ['eu', 'oi', 'oy'],
        'au': ['ao', 'aw', 'ou'],
        'ä': ['e', 'ae', 'eh'],
        'ö': ['oe', 'e', 'o'],
        'ü': ['ue', 'u', 'i', 'y'],

        # Consonant confusions
        'ch': ['sch', 'k', 'g', 'h'],
        'sch': ['ch', 's', 'sh'],
        'sp': ['schp', 'shp'],
        'st': ['scht', 'sht'],
        'pf': ['f', 'p'],
        'tz': ['z', 'ts', 'ss'],
        'ck': ['k', 'c', 'kk'],
        'ss': ['s', 'ß', 'z'],
        'ß': ['ss', 's'],
        'v': ['f', 'w'],
        'w': ['v', 'u'],
        'qu': ['kw', 'ku', 'kv'],

        # Ending confusions
        'en': ['n', 'ern', 'an'],
        'er': ['a', 'ar', 'or'],
        'el': ['l', 'al', 'ol'],
        'ig': ['ich', 'ik', 'isch'],
        'ung': ['ong', 'unk', 'ing'],
        'heit': ['keit', 'hait', 'ait'],
        'keit': ['heit', 'kait', 'ait'],
        'lich': ['lig', 'isch', 'lisch'],
        'isch': ['isch', 'ig', 'lich'],
    }

    # Common Whisper transcription errors in German
    # ONLY include words that are NOT valid German words
    COMMON_WHISPER_ERRORS = {
        # Clear transcription errors (gibberish -> real words)
        'Seesucht': ['Sehnsucht'],  # Not a German word -> Sehnsucht
        'Sesucht': ['Sehnsucht'],   # Not a German word
        'Sänsucht': ['Sehnsucht'],  # Not a German word
        'Reindacht': ['wirklich'],  # Not a German word
        'Koffen': ['Koffer'],       # Not a German word

        # NOTE: 'Offen', 'Saftgeschmack', 'Potenzial', 'heftig' are all VALID German words
        # and should NOT be corrected

        # Only correct clear spelling errors, not valid alternatives
    }

    # Grammar patterns that indicate errors
    GRAMMAR_ERROR_PATTERNS = [
        # Double words
        (r'\b(\w+)\s+\1\b', 'repeated_word', 'Wiederholtes Wort: "{0}"'),

        # Missing verb patterns
        (r'\b(Ich|Du|Er|Sie|Es|Wir|Ihr)\s+(der|die|das|den|dem|des)\b',
         'missing_verb_after_pronoun', 'Mögliches fehlendes Verb nach Pronomen'),

        # Wrong article gender (common patterns)
        (r'\bder\s+(Frau|Mädchen|Kind|Haus|Buch|Auto)\b',
         'wrong_article', 'Falscher Artikel'),
        (r'\bdie\s+(Mann|Junge|Tisch|Stuhl|Baum|Computer)\b',
         'wrong_article', 'Falscher Artikel'),

        # Sentence fragments
        (r'^(Und|Oder|Aber|Weil|Dass|Wenn|Ob)\s*[,.]',
         'fragment_start', 'Satzfragment am Anfang'),

        # Double punctuation
        (r'[.!?]{2,}', 'double_punctuation', 'Doppelte Satzzeichen'),
        (r',\s*[.!?]', 'comma_before_end', 'Komma vor Satzende'),

        # Incomplete subordinate clauses
        (r'\b(dass|weil|wenn|obwohl|ob)\s+[A-ZÄÖÜ]',
         'subordinate_missing_comma', 'Möglicherweise fehlendes Komma nach Nebensatz'),
    ]


# ============================================================================
# ENGLISH LANGUAGE DATA
# ============================================================================

class EnglishLanguageData:
    """Comprehensive English language data for analysis."""

    COMMON_WORDS = {
        # Articles & Pronouns
        'the', 'a', 'an', 'this', 'that', 'these', 'those',
        'i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them',
        'my', 'your', 'his', 'her', 'its', 'our', 'their',
        'mine', 'yours', 'hers', 'ours', 'theirs',
        'myself', 'yourself', 'himself', 'herself', 'itself', 'ourselves', 'themselves',
        'who', 'whom', 'whose', 'which', 'what', 'whoever', 'whatever',

        # Prepositions
        'in', 'on', 'at', 'to', 'for', 'with', 'by', 'from', 'of', 'about',
        'into', 'through', 'during', 'before', 'after', 'above', 'below',
        'between', 'under', 'over', 'out', 'up', 'down', 'off', 'across',

        # Conjunctions
        'and', 'or', 'but', 'so', 'yet', 'for', 'nor', 'because', 'although',
        'while', 'if', 'when', 'where', 'that', 'which', 'who', 'whom',
        'unless', 'until', 'since', 'whether', 'though', 'whereas',

        # Common verbs
        'be', 'is', 'am', 'are', 'was', 'were', 'been', 'being',
        'have', 'has', 'had', 'having', 'do', 'does', 'did', 'done', 'doing',
        'will', 'would', 'shall', 'should', 'may', 'might', 'must', 'can', 'could',
        'go', 'goes', 'went', 'gone', 'going', 'come', 'comes', 'came', 'coming',
        'make', 'makes', 'made', 'making', 'get', 'gets', 'got', 'getting',
        'say', 'says', 'said', 'saying', 'know', 'knows', 'knew', 'knowing',
        'take', 'takes', 'took', 'taken', 'taking', 'see', 'sees', 'saw', 'seen',
        'think', 'thinks', 'thought', 'thinking', 'want', 'wants', 'wanted',
        'give', 'gives', 'gave', 'given', 'giving', 'use', 'uses', 'used', 'using',

        # Adverbs
        'not', 'also', 'just', 'only', 'very', 'really', 'quite', 'still', 'already',
        'now', 'then', 'here', 'there', 'where', 'when', 'how', 'why',
        'always', 'never', 'often', 'sometimes', 'usually', 'rarely', 'seldom',
        'soon', 'later', 'early', 'late', 'today', 'tomorrow', 'yesterday',
        'well', 'badly', 'quickly', 'slowly', 'easily', 'hard', 'fast',
        'probably', 'perhaps', 'maybe', 'certainly', 'definitely', 'possibly',
        'actually', 'basically', 'especially', 'particularly', 'generally',

        # Adjectives
        'good', 'bad', 'big', 'small', 'large', 'little', 'great', 'high', 'low',
        'old', 'new', 'young', 'long', 'short', 'first', 'last', 'next', 'other',
        'same', 'different', 'important', 'possible', 'able', 'available',
        'right', 'wrong', 'true', 'false', 'real', 'sure', 'certain',
        'many', 'much', 'more', 'most', 'few', 'some', 'any', 'all', 'each', 'every',

        # Numbers
        'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten',
        'first', 'second', 'third', 'hundred', 'thousand', 'million', 'billion',
    }

    TOPIC_KEYWORDS = {
        'technology': {
            'computer', 'software', 'hardware', 'program', 'programming', 'code',
            'algorithm', 'data', 'internet', 'network', 'server', 'cloud',
            'artificial', 'intelligence', 'AI', 'machine', 'learning', 'ML',
            'robot', 'automation', 'digital', 'app', 'application', 'system',
            'processor', 'memory', 'database', 'API', 'framework', 'development',
        },
        'science': {
            'research', 'study', 'experiment', 'hypothesis', 'theory', 'proof',
            'science', 'scientist', 'laboratory', 'analysis', 'result', 'method',
            'data', 'statistics', 'measurement', 'observation', 'publication',
        },
        'medicine': {
            'patient', 'doctor', 'hospital', 'clinic', 'treatment', 'therapy',
            'medication', 'diagnosis', 'symptom', 'disease', 'health', 'surgery',
            'nurse', 'care', 'healing', 'prevention', 'vaccine', 'virus',
        },
        'business': {
            'company', 'business', 'market', 'trade', 'investment', 'capital',
            'profit', 'loss', 'revenue', 'cost', 'budget', 'finance', 'bank',
            'management', 'strategy', 'marketing', 'sales', 'product', 'customer',
        },
        'education': {
            'school', 'university', 'college', 'student', 'teacher', 'professor',
            'class', 'lecture', 'course', 'exam', 'test', 'grade', 'degree',
            'education', 'learning', 'knowledge', 'study', 'research',
        },
    }

    PHONETIC_CONFUSIONS = {
        'th': ['t', 'd', 'f', 'v'],
        'ph': ['f', 'v'],
        'gh': ['g', 'f', ''],
        'ght': ['t', 'te'],
        'tion': ['shun', 'sion', 'cion'],
        'sion': ['tion', 'zhun'],
        'ough': ['off', 'ow', 'oo', 'uf'],
        'ould': ['ood', 'ud'],
        'alk': ['awk', 'ock'],
        'ight': ['ite', 'it'],
    }

    GRAMMAR_ERROR_PATTERNS = [
        (r'\b(\w+)\s+\1\b', 'repeated_word', 'Repeated word: "{0}"'),
        (r'\b(I|He|She|It|We|They)\s+(the|a|an)\s+[a-z]+\b(?!\s+(?:is|was|are|were|has|have|had))',
         'missing_verb', 'Possible missing verb'),
        (r'[.!?]{2,}', 'double_punctuation', 'Double punctuation'),
        (r',\s*[.!?]', 'comma_before_end', 'Comma before sentence end'),
    ]


# ============================================================================
# PHONETIC ANALYZER
# ============================================================================

class PhoneticAnalyzer:
    """Analyzes phonetic similarity between words."""

    def __init__(self, language: str = "de"):
        self.language = language
        self._init_phonetic_rules()

    def _init_phonetic_rules(self):
        """Initialize phonetic transformation rules."""
        if self.language == "de":
            self.vowel_map = {
                'ä': 'e', 'ö': 'o', 'ü': 'u', 'ß': 'ss',
                'ei': 'ai', 'ie': 'i', 'eu': 'oi', 'äu': 'oi',
                'au': 'ao', 'ai': 'ai', 'ey': 'ai', 'ay': 'ai',
            }
            self.consonant_map = {
                'sch': 'S', 'ch': 'X', 'ck': 'k', 'ph': 'f',
                'qu': 'kw', 'sp': 'Sp', 'st': 'St', 'tz': 'ts',
                'pf': 'pf', 'dt': 't', 'th': 't', 'v': 'f',
            }
        else:
            self.vowel_map = {
                'ea': 'i', 'ee': 'i', 'oo': 'u', 'ou': 'au',
                'ai': 'e', 'ay': 'e', 'ey': 'e', 'oi': 'oi',
            }
            self.consonant_map = {
                'ph': 'f', 'gh': '', 'ck': 'k', 'wh': 'w',
                'wr': 'r', 'kn': 'n', 'gn': 'n', 'mb': 'm',
                'tion': 'shun', 'sion': 'zhun', 'th': 'th',
            }

    def get_phonetic_key(self, word: str) -> str:
        """Generate a phonetic key for a word."""
        word = word.lower()

        # Apply consonant transformations (longer patterns first)
        for pattern, replacement in sorted(
            self.consonant_map.items(),
            key=lambda x: len(x[0]),
            reverse=True
        ):
            word = word.replace(pattern, replacement)

        # Apply vowel transformations
        for pattern, replacement in sorted(
            self.vowel_map.items(),
            key=lambda x: len(x[0]),
            reverse=True
        ):
            word = word.replace(pattern, replacement)

        # Remove double consonants
        result = []
        prev_char = ''
        for char in word:
            if char != prev_char or char in 'aeiou':
                result.append(char)
            prev_char = char

        return ''.join(result)

    def phonetic_similarity(self, word1: str, word2: str) -> float:
        """Calculate phonetic similarity between two words."""
        key1 = self.get_phonetic_key(word1)
        key2 = self.get_phonetic_key(word2)

        # Use sequence matcher for similarity
        similarity = difflib.SequenceMatcher(None, key1, key2).ratio()

        # Bonus for same starting sound
        if key1 and key2 and key1[0] == key2[0]:
            similarity = min(1.0, similarity + 0.1)

        # Bonus for similar length
        len_diff = abs(len(word1) - len(word2))
        if len_diff <= 1:
            similarity = min(1.0, similarity + 0.05)
        elif len_diff <= 2:
            similarity = min(1.0, similarity + 0.02)

        return similarity

    def find_similar_words(
        self,
        word: str,
        vocabulary: Set[str],
        top_k: int = 5,
        min_similarity: float = 0.5
    ) -> List[Tuple[str, float]]:
        """Find phonetically similar words from a vocabulary."""
        similarities = []

        for vocab_word in vocabulary:
            if vocab_word.lower() == word.lower():
                continue

            sim = self.phonetic_similarity(word, vocab_word)
            if sim >= min_similarity:
                similarities.append((vocab_word, sim))

        # Sort by similarity descending
        similarities.sort(key=lambda x: x[1], reverse=True)

        return similarities[:top_k]


# ============================================================================
# TOPIC ANALYZER
# ============================================================================

class TopicAnalyzer:
    """Analyzes document topics and detects semantic outliers."""

    def __init__(self, language: str = "de"):
        self.language = language
        if language == "de":
            self.lang_data = GermanLanguageData()
        else:
            self.lang_data = EnglishLanguageData()

        self._build_keyword_index()

    def _build_keyword_index(self):
        """Build reverse index from keywords to topics."""
        self.keyword_to_topics = defaultdict(list)

        for topic, keywords in self.lang_data.TOPIC_KEYWORDS.items():
            for keyword in keywords:
                self.keyword_to_topics[keyword.lower()].append(topic)

    def extract_topic_words(self, text: str) -> List[str]:
        """Extract topic-relevant words from text."""
        words = re.findall(r'\b[A-Za-zÄÖÜäöüß]{3,}\b', text)
        topic_words = []

        for word in words:
            word_lower = word.lower()

            # Skip common words
            if word_lower in self.lang_data.COMMON_WORDS:
                continue

            # Check if it's a topic keyword
            if word_lower in self.keyword_to_topics or word in self.keyword_to_topics:
                topic_words.append(word)
                continue

            # Check partial matches for compound words (German)
            if self.language == "de":
                for keyword in self.keyword_to_topics:
                    if keyword in word_lower or word_lower in keyword:
                        topic_words.append(word)
                        break

        return topic_words

    def identify_main_topic(self, text: str) -> Tuple[Optional[str], float]:
        """Identify the main topic of the text."""
        words = re.findall(r'\b[A-Za-zÄÖÜäöüß]{3,}\b', text.lower())

        topic_scores = Counter()

        for word in words:
            topics = self.keyword_to_topics.get(word, [])
            for topic in topics:
                topic_scores[topic] += 1

        if not topic_scores:
            return None, 0.0

        main_topic, count = topic_scores.most_common(1)[0]
        total_topic_words = sum(topic_scores.values())
        confidence = count / total_topic_words if total_topic_words > 0 else 0.0

        return main_topic, confidence

    def get_topic_vocabulary(self, topic: str) -> Set[str]:
        """Get all vocabulary words associated with a topic."""
        vocab = set()

        keywords = self.lang_data.TOPIC_KEYWORDS.get(topic, set())
        vocab.update(keywords)

        # Add common words
        vocab.update(self.lang_data.COMMON_WORDS)

        return vocab

    def is_word_in_context(
        self,
        word: str,
        context_words: List[str],
        main_topic: Optional[str]
    ) -> Tuple[bool, float]:
        """Check if a word fits the context."""
        word_lower = word.lower()

        # Common words are always in context
        if word_lower in self.lang_data.COMMON_WORDS:
            return True, 1.0

        # Check if word is in main topic vocabulary
        if main_topic:
            topic_keywords = self.lang_data.TOPIC_KEYWORDS.get(main_topic, set())
            for keyword in topic_keywords:
                if keyword.lower() == word_lower or keyword.lower() in word_lower:
                    return True, 1.0

        # Check word frequency in context
        context_lower = [w.lower() for w in context_words]
        word_freq = context_lower.count(word_lower)
        if word_freq > 1:
            return True, 0.8

        # Check if word topics match context topics
        word_topics = set(self.keyword_to_topics.get(word_lower, []))
        if word_topics:
            context_topics = set()
            for cw in context_words:
                context_topics.update(self.keyword_to_topics.get(cw.lower(), []))

            if word_topics & context_topics:
                return True, 0.7

        # Word might be an outlier
        return False, 0.3


# ============================================================================
# GRAMMAR ANALYZER
# ============================================================================

class GrammarAnalyzer:
    """Analyzes grammar and logic issues in text."""

    def __init__(self, language: str = "de"):
        self.language = language
        if language == "de":
            self.lang_data = GermanLanguageData()
        else:
            self.lang_data = EnglishLanguageData()

    def analyze_sentence(self, sentence: str) -> List[Dict]:
        """Analyze a sentence for grammar issues."""
        issues = []

        for pattern, issue_type, description in self.lang_data.GRAMMAR_ERROR_PATTERNS:
            matches = re.finditer(pattern, sentence, re.IGNORECASE)
            for match in matches:
                issues.append({
                    'type': issue_type,
                    'description': description.format(match.group(1) if match.groups() else ''),
                    'position': match.start(),
                    'match': match.group(),
                    'severity': self._get_severity(issue_type),
                })

        return issues

    def _get_severity(self, issue_type: str) -> str:
        """Get severity level for an issue type."""
        high_severity = ['missing_verb', 'wrong_article', 'fragment_start']
        medium_severity = ['repeated_word', 'subordinate_missing_comma']

        if issue_type in high_severity:
            return 'high'
        elif issue_type in medium_severity:
            return 'medium'
        return 'low'

    def check_sentence_completeness(self, sentence: str) -> Dict:
        """Check if a sentence is complete."""
        result = {
            'is_complete': True,
            'issues': [],
            'has_subject': False,
            'has_verb': False,
        }

        words = sentence.split()
        if len(words) < 2:
            result['is_complete'] = False
            result['issues'].append('Sentence too short')
            return result

        # Very basic subject detection
        if self.language == "de":
            subjects = {'ich', 'du', 'er', 'sie', 'es', 'wir', 'ihr', 'man'}
            verbs = {'ist', 'sind', 'war', 'hat', 'haben', 'wird', 'werden',
                    'kann', 'muss', 'soll', 'will', 'macht', 'geht', 'kommt'}
        else:
            subjects = {'i', 'you', 'he', 'she', 'it', 'we', 'they'}
            verbs = {'is', 'are', 'was', 'were', 'has', 'have', 'had',
                    'do', 'does', 'did', 'can', 'will', 'would', 'should'}

        words_lower = [w.lower().strip('.,!?;:') for w in words]

        for word in words_lower:
            if word in subjects:
                result['has_subject'] = True
            if word in verbs:
                result['has_verb'] = True

        if not result['has_verb']:
            result['is_complete'] = False
            result['issues'].append('No verb detected')

        return result


# ============================================================================
# SMART WORD REPLACER
# ============================================================================

class SmartWordReplacer:
    """Intelligently replaces words that don't fit the context."""

    def __init__(self, language: str = "de"):
        self.language = language
        self.phonetic = PhoneticAnalyzer(language)
        self.topic_analyzer = TopicAnalyzer(language)

        if language == "de":
            self.lang_data = GermanLanguageData()
        else:
            self.lang_data = EnglishLanguageData()

        self._build_vocabulary()

    def _build_vocabulary(self):
        """Build comprehensive vocabulary from all sources."""
        self.vocabulary = set()

        # Add common words
        self.vocabulary.update(self.lang_data.COMMON_WORDS)

        # Add topic keywords
        for keywords in self.lang_data.TOPIC_KEYWORDS.values():
            self.vocabulary.update(k.lower() for k in keywords)

        # Add extended vocabulary if available
        if EXTENDED_VOCAB_AVAILABLE and self.language == "de":
            # Add Whisper error corrections
            for corrections in WHISPER_ERROR_CORRECTIONS.values():
                self.vocabulary.update(c.lower() for c in corrections)

            # Add semantic cluster words
            for cluster_data in SEMANTIC_CLUSTERS.values():
                self.vocabulary.update(w.lower() for w in cluster_data.get('core', []))
                self.vocabulary.update(w.lower() for w in cluster_data.get('extended', []))

            # Add phonetic word groups
            for words in PHONETIC_WORD_GROUPS.values():
                self.vocabulary.update(w.lower() for w in words)

            # Add academic vocabulary
            for terms in ACADEMIC_VOCABULARY.values():
                for term in terms:
                    self.vocabulary.update(w.lower() for w in term.split())

        # Add known error corrections
        if hasattr(self.lang_data, 'COMMON_WHISPER_ERRORS'):
            for correct_words in self.lang_data.COMMON_WHISPER_ERRORS.values():
                self.vocabulary.update(w.lower() for w in correct_words)

    def find_replacement_candidates(
        self,
        word: str,
        context_words: List[str],
        main_topic: Optional[str] = None
    ) -> List[Tuple[str, float, str]]:
        """
        Find replacement candidates for a word.
        Returns: List of (word, score, reason)
        """
        candidates = []
        word_lower = word.lower()

        # 1. Check extended vocabulary first (highest priority)
        if EXTENDED_VOCAB_AVAILABLE and self.language == "de":
            if word in WHISPER_ERROR_CORRECTIONS:
                for replacement in WHISPER_ERROR_CORRECTIONS[word]:
                    candidates.append((replacement, 0.95, 'extended_vocab_error'))
            elif word_lower in WHISPER_ERROR_CORRECTIONS:
                for replacement in WHISPER_ERROR_CORRECTIONS[word_lower]:
                    candidates.append((replacement, 0.95, 'extended_vocab_error'))

            # Check semantic clusters for context-aware replacement
            cluster = get_semantic_cluster(word) if 'get_semantic_cluster' in dir() else {}
            if cluster:
                # Word is in a known cluster, it's probably correct
                pass
            else:
                # Word not in any cluster - check if similar words exist
                for cluster_name, cluster_data in SEMANTIC_CLUSTERS.items():
                    all_cluster_words = cluster_data.get('core', []) + cluster_data.get('extended', [])
                    for cluster_word in all_cluster_words:
                        sim = self.phonetic.phonetic_similarity(word, cluster_word)
                        if sim >= 0.7:
                            # Check if cluster matches context
                            context_match = any(
                                cw.lower() in [w.lower() for w in all_cluster_words]
                                for cw in context_words
                            )
                            if context_match:
                                candidates.append((cluster_word, sim * 0.9, 'semantic_cluster_match'))

        # 2. Check if it's a known Whisper error (built-in)
        if hasattr(self.lang_data, 'COMMON_WHISPER_ERRORS'):
            if word in self.lang_data.COMMON_WHISPER_ERRORS:
                for replacement in self.lang_data.COMMON_WHISPER_ERRORS[word]:
                    candidates.append((replacement, 0.9, 'known_whisper_error'))

        # 3. Find phonetically similar words
        topic_vocab = set()
        if main_topic:
            topic_vocab = self.topic_analyzer.get_topic_vocabulary(main_topic)

        search_vocab = self.vocabulary | topic_vocab
        phonetic_matches = self.phonetic.find_similar_words(
            word,
            search_vocab,
            top_k=10,
            min_similarity=PHONETIC_SIMILARITY_THRESHOLD
        )

        for match_word, phonetic_score in phonetic_matches:
            # Check if match fits context
            in_context, context_score = self.topic_analyzer.is_word_in_context(
                match_word, context_words, main_topic
            )

            if in_context:
                combined_score = 0.6 * phonetic_score + 0.4 * context_score
                candidates.append((match_word, combined_score, 'phonetic_match'))

        # 4. Remove duplicates, keeping highest score
        seen = {}
        for word_cand, score, reason in candidates:
            key = word_cand.lower()
            if key not in seen or seen[key][1] < score:
                seen[key] = (word_cand, score, reason)

        candidates = list(seen.values())

        # 5. Sort by score
        candidates.sort(key=lambda x: x[1], reverse=True)

        return candidates[:5]

    def attempt_replacement(
        self,
        word: str,
        sentence: str,
        context_words: List[str],
        main_topic: Optional[str],
        attempt: int = 1
    ) -> Tuple[Optional[str], bool, str]:
        """
        Attempt to replace a word.
        Returns: (replacement, success, reason)
        """
        # Be very conservative - only replace if we're very confident
        candidates = self.find_replacement_candidates(word, context_words, main_topic)

        if not candidates:
            return None, False, 'no_candidates_found'

        # Only replace if it's a known Whisper error with high confidence
        for replacement, score, reason in candidates:
            # Only replace known errors with very high confidence
            if reason in ('extended_vocab_error', 'known_whisper_error') and score >= MIN_REPLACEMENT_CONFIDENCE:
                return replacement, True, reason

        # If ONLY_REPLACE_KNOWN_ERRORS is True, don't do phonetic guessing
        if ONLY_REPLACE_KNOWN_ERRORS:
            return None, False, 'only_replacing_known_errors'

        # Otherwise, try phonetic matches but require very high confidence
        for replacement, score, reason in candidates:
            if score >= MIN_REPLACEMENT_CONFIDENCE:
                return replacement, True, reason

        return None, False, 'confidence_too_low'


# ============================================================================
# MAIN SMART POST-PROCESSOR
# ============================================================================

class SmartPostProcessor:
    """
    Main post-processor that orchestrates all analysis and correction.
    """

    def __init__(self, language: str = "de", enable_logging: bool = True):
        self.language = language
        self.enable_logging = enable_logging

        self.topic_analyzer = TopicAnalyzer(language)
        self.grammar_analyzer = GrammarAnalyzer(language)
        self.word_replacer = SmartWordReplacer(language)
        self.phonetic = PhoneticAnalyzer(language)

        if language == "de":
            self.lang_data = GermanLanguageData()
        else:
            self.lang_data = EnglishLanguageData()

        self._processing_lock = threading.Lock()
        self._current_analysis: Optional[DocumentAnalysis] = None

    def process_realtime(self, chunk_text: str, full_context: str = "") -> str:
        """
        Process a chunk of text in real-time (fast, basic corrections).
        Called during transcription.
        """
        if not chunk_text.strip():
            return chunk_text

        # Fast corrections only
        result = chunk_text

        # 1. Remove hesitation fillers
        result = self._remove_hesitation_fillers(result)

        # 2. Fix basic punctuation
        result = self._fix_basic_punctuation(result)

        # 3. Fix obvious repeated words
        result = re.sub(r'\b(\w+)\s+\1\b', r'\1', result, flags=re.IGNORECASE)

        return result

    def process_final(self, full_text: str, subject_hint: Optional[str] = None) -> Tuple[str, DocumentAnalysis]:
        """
        Process the full text after transcription ends.
        Performs comprehensive analysis and correction.
        """
        with self._processing_lock:
            # Initialize analysis
            analysis = DocumentAnalysis(original_text=full_text)
            analysis.processing_log.append(f"Started processing at {datetime.now().isoformat()}")

            # Step 1: Pre-processing
            text = self._preprocess(full_text)
            analysis.processing_log.append("Pre-processing complete")

            # Step 2: Extract topic and keywords
            main_topic, topic_confidence = self.topic_analyzer.identify_main_topic(text)
            if subject_hint:
                # Use subject hint to inform topic detection
                for topic, keywords in self.lang_data.TOPIC_KEYWORDS.items():
                    if any(k.lower() in subject_hint.lower() for k in keywords):
                        main_topic = topic
                        topic_confidence = 0.8
                        break

            analysis.global_topic = main_topic
            analysis.topic_keywords = self.topic_analyzer.extract_topic_words(text)
            analysis.processing_log.append(f"Topic identified: {main_topic} (confidence: {topic_confidence:.2f})")

            # Step 3: Build word frequency
            words = re.findall(r'\b[A-Za-zÄÖÜäöüß]+\b', text.lower())
            analysis.word_frequency = Counter(words)

            # Step 4: Split into sentences and analyze each
            sentences = self._split_sentences(text)

            for i, sentence in enumerate(sentences):
                sent_analysis = self._analyze_sentence(
                    sentence, i, text, main_topic, analysis.word_frequency
                )
                analysis.sentences.append(sent_analysis)

            analysis.processing_log.append(f"Analyzed {len(sentences)} sentences")

            # Step 5: Apply corrections with retry logic
            corrected_sentences = []
            for sent_analysis in analysis.sentences:
                corrected = self._correct_sentence(
                    sent_analysis, main_topic, analysis.word_frequency
                )
                corrected_sentences.append(corrected)

                # Log unresolved issues
                for word_analysis in sent_analysis.word_analyses:
                    if word_analysis.is_outlier and not word_analysis.resolved:
                        analysis.unresolved_issues.append({
                            'type': 'semantic_outlier',
                            'word': word_analysis.word,
                            'sentence_index': sent_analysis.index,
                            'attempts': word_analysis.attempts,
                            'context': ' '.join(word_analysis.context_words[:10]),
                        })

            # Step 6: Reconstruct text
            analysis.corrected_text = ' '.join(corrected_sentences)

            # Step 7: Final polish
            analysis.corrected_text = self._final_polish(analysis.corrected_text)

            # Step 8: Log if enabled
            if self.enable_logging and analysis.unresolved_issues:
                self._write_log(analysis)

            analysis.processing_log.append(f"Finished processing at {datetime.now().isoformat()}")
            analysis.processing_log.append(f"Unresolved issues: {len(analysis.unresolved_issues)}")

            self._current_analysis = analysis

            return analysis.corrected_text, analysis

    def _preprocess(self, text: str) -> str:
        """Pre-process text before analysis."""
        # Normalize whitespace
        text = re.sub(r'\s+', ' ', text).strip()

        # Remove hesitation fillers
        text = self._remove_hesitation_fillers(text)

        # Apply learning-based corrections first (highest priority)
        if LEARNING_CORRECTOR_AVAILABLE:
            text = correct_with_learning(text)

        # Apply phrase-level corrections (multi-word errors)
        if EXTENDED_VOCAB_AVAILABLE:
            text = apply_phrase_corrections(text)

        return text

    def _remove_hesitation_fillers(self, text: str) -> str:
        """Remove hesitation sounds."""
        if self.language == "de":
            patterns = [r'\bähm?\b', r'\böhm?\b', r'\bhmm?\b', r'\bhm\b']
        else:
            patterns = [r'\buh+\b', r'\bum+\b', r'\bhm+\b', r'\ber+\b']

        for pattern in patterns:
            text = re.sub(pattern, '', text, flags=re.IGNORECASE)

        # Clean up extra spaces
        text = re.sub(r'\s+', ' ', text).strip()

        return text

    def _fix_basic_punctuation(self, text: str) -> str:
        """Fix basic punctuation issues."""
        # Space before punctuation
        text = re.sub(r'\s+([.,!?;:])', r'\1', text)

        # Double punctuation
        text = re.sub(r'([.,!?;:])\s*\1+', r'\1', text)

        # Period comma confusion
        text = re.sub(r'\.\s*,', ',', text)
        text = re.sub(r',\s*\.', '.', text)

        return text

    def _split_sentences(self, text: str) -> List[str]:
        """Split text into sentences."""
        # Split on sentence-ending punctuation
        sentences = re.split(r'(?<=[.!?])\s+', text)
        return [s.strip() for s in sentences if s.strip()]

    def _analyze_sentence(
        self,
        sentence: str,
        index: int,
        full_text: str,
        main_topic: Optional[str],
        word_frequency: Counter
    ) -> SentenceAnalysis:
        """Perform comprehensive analysis on a sentence."""
        analysis = SentenceAnalysis(text=sentence, index=index)

        # Extract words
        analysis.words = re.findall(r'\b[A-Za-zÄÖÜäöüß]+\b', sentence)

        # Get context words from surrounding text
        context_start = max(0, full_text.find(sentence) - 200)
        context_end = min(len(full_text), full_text.find(sentence) + len(sentence) + 200)
        context_text = full_text[context_start:context_end]
        context_words = re.findall(r'\b[A-Za-zÄÖÜäöüß]+\b', context_text)

        # Check grammar (only repeated words for now)
        analysis.grammar_issues = self.grammar_analyzer.analyze_sentence(sentence)

        # Analyze each word - ONLY flag known Whisper errors
        for pos, word in enumerate(analysis.words):
            if len(word) < MIN_WORD_LENGTH_FOR_ANALYSIS:
                continue

            # CONSERVATIVE APPROACH: Only flag words that are in our known error database
            is_known_error = False

            # Check extended vocabulary
            if EXTENDED_VOCAB_AVAILABLE and self.language == "de":
                if word in WHISPER_ERROR_CORRECTIONS or word.lower() in WHISPER_ERROR_CORRECTIONS:
                    is_known_error = True

            # Check built-in error list
            if hasattr(self.word_replacer.lang_data, 'COMMON_WHISPER_ERRORS'):
                if word in self.word_replacer.lang_data.COMMON_WHISPER_ERRORS:
                    is_known_error = True

            if is_known_error:
                word_analysis = WordAnalysis(
                    word=word,
                    position=pos,
                    sentence_index=index,
                    context_words=context_words,
                    is_outlier=True,
                    outlier_score=0.9,
                    issue_type='known_whisper_error'
                )
                analysis.word_analyses.append(word_analysis)

        return analysis

    def _correct_sentence(
        self,
        sent_analysis: SentenceAnalysis,
        main_topic: Optional[str],
        word_frequency: Counter
    ) -> str:
        """Correct a sentence based on analysis."""
        corrected = sent_analysis.text

        # Sort word analyses by position (reverse) to replace from end to start
        word_analyses = sorted(
            sent_analysis.word_analyses,
            key=lambda x: x.position,
            reverse=True
        )

        for word_analysis in word_analyses:
            if not word_analysis.is_outlier:
                continue

            # Attempt replacement with retry
            for attempt in range(1, MAX_CORRECTION_ATTEMPTS + 1):
                word_analysis.attempts = attempt

                replacement, success, reason = self.word_replacer.attempt_replacement(
                    word_analysis.word,
                    corrected,
                    word_analysis.context_words,
                    main_topic,
                    attempt
                )

                if success and replacement:
                    # For known errors, trust the replacement; for others, verify
                    should_replace = (
                        reason in ('extended_vocab_error', 'known_whisper_error') or
                        self._verify_replacement(word_analysis.word, replacement, corrected, main_topic)
                    )

                    if should_replace:
                        # Apply replacement
                        corrected = self._replace_word_in_text(
                            corrected, word_analysis.word, replacement
                        )
                        word_analysis.resolved = True
                        word_analysis.replacement_used = replacement
                        break

            if not word_analysis.resolved:
                # Log that we couldn't fix this
                word_analysis.issue_type = f'unresolved_after_{MAX_CORRECTION_ATTEMPTS}_attempts'

        # Apply grammar corrections
        for grammar_issue in sent_analysis.grammar_issues:
            if grammar_issue['type'] == 'repeated_word':
                # Remove repeated words
                corrected = re.sub(
                    r'\b(\w+)\s+\1\b', r'\1', corrected, flags=re.IGNORECASE
                )

        return corrected

    def _verify_replacement(
        self,
        original: str,
        replacement: str,
        sentence: str,
        main_topic: Optional[str]
    ) -> bool:
        """Verify that a replacement is valid."""
        # Don't replace with the same word
        if original.lower() == replacement.lower():
            return False

        # Check that replacement fits context
        context_words = re.findall(r'\b[A-Za-zÄÖÜäöüß]+\b', sentence)
        in_context, score = self.topic_analyzer.is_word_in_context(
            replacement, context_words, main_topic
        )

        return in_context and score >= 0.5

    def _replace_word_in_text(self, text: str, old_word: str, new_word: str) -> str:
        """Replace a word in text, preserving case."""
        # Match the case of the original
        if old_word[0].isupper():
            new_word = new_word[0].upper() + new_word[1:]
        else:
            new_word = new_word.lower()

        # Replace with word boundaries
        pattern = r'\b' + re.escape(old_word) + r'\b'
        return re.sub(pattern, new_word, text, count=1)

    def _final_polish(self, text: str) -> str:
        """Final polish of the corrected text."""
        # Capitalize first letter
        if text and text[0].islower():
            text = text[0].upper() + text[1:]

        # Ensure ending punctuation
        if text and text[-1] not in '.!?':
            text += '.'

        # Capitalize after sentence endings
        text = re.sub(
            r'([.!?]\s+)([a-zäöü])',
            lambda m: m.group(1) + m.group(2).upper(),
            text
        )

        # Clean up whitespace
        text = re.sub(r'\s+', ' ', text).strip()

        # Fix spacing around punctuation
        text = re.sub(r'\s+([.,!?;:])', r'\1', text)
        text = re.sub(r'([.,!?;:])([A-Za-zÄÖÜäöü])', r'\1 \2', text)

        return text

    def _write_log(self, analysis: DocumentAnalysis):
        """Write unresolved issues to log file."""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        log_file = POSTPROCESSOR_LOG_DIR / f"unresolved_{timestamp}.json"

        log_data = {
            'timestamp': datetime.now().isoformat(),
            'original_text': analysis.original_text[:500],
            'corrected_text': analysis.corrected_text[:500] if analysis.corrected_text else None,
            'topic': analysis.global_topic,
            'unresolved_issues': analysis.unresolved_issues,
            'processing_log': analysis.processing_log,
        }

        with open(log_file, 'w', encoding='utf-8') as f:
            json.dump(log_data, f, ensure_ascii=False, indent=2)

    def get_analysis_report(self) -> Optional[Dict]:
        """Get a report of the last analysis."""
        if not self._current_analysis:
            return None

        analysis = self._current_analysis

        return {
            'topic': analysis.global_topic,
            'topic_keywords': analysis.topic_keywords[:10],
            'sentence_count': len(analysis.sentences),
            'total_issues_found': sum(
                len(s.word_analyses) for s in analysis.sentences
            ),
            'issues_resolved': sum(
                1 for s in analysis.sentences
                for w in s.word_analyses
                if w.resolved
            ),
            'unresolved_count': len(analysis.unresolved_issues),
            'processing_log': analysis.processing_log,
        }


# ============================================================================
# SINGLETON INSTANCE & API
# ============================================================================

_postprocessor: Optional[SmartPostProcessor] = None
_postprocessor_lock = threading.Lock()


def get_postprocessor(language: str = "de", enable_logging: bool = True) -> SmartPostProcessor:
    """Get or create the singleton postprocessor instance."""
    global _postprocessor

    with _postprocessor_lock:
        if _postprocessor is None or _postprocessor.language != language:
            _postprocessor = SmartPostProcessor(language, enable_logging)

    return _postprocessor


def process_realtime(chunk_text: str, full_context: str = "", language: str = "de") -> str:
    """Process a text chunk in real-time."""
    return get_postprocessor(language).process_realtime(chunk_text, full_context)


def process_final(
    full_text: str,
    subject_hint: Optional[str] = None,
    language: str = "de"
) -> str:
    """Process the full text after transcription."""
    corrected, _ = get_postprocessor(language).process_final(full_text, subject_hint)
    return corrected


def process_final_with_analysis(
    full_text: str,
    subject_hint: Optional[str] = None,
    language: str = "de"
) -> Tuple[str, Dict]:
    """Process full text and return analysis report."""
    postprocessor = get_postprocessor(language)
    corrected, _ = postprocessor.process_final(full_text, subject_hint)
    report = postprocessor.get_analysis_report()
    return corrected, report or {}


def set_logging_enabled(enabled: bool, language: str = "de"):
    """Enable or disable logging of unresolved issues."""
    get_postprocessor(language).enable_logging = enabled
