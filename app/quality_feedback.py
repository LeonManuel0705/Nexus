"""
Quality Feedback System for Voice Notes
Collects user feedback, detects errors, and creates improvement reports.
"""

import os
import json
import re
from datetime import datetime
from typing import Optional, List, Dict, Tuple
from pathlib import Path

FEEDBACK_DIR = Path(__file__).parent.parent / "feedback_logs"
REPORTS_DIR = Path(__file__).parent.parent / "error_reports"

# Ensure directories exist
FEEDBACK_DIR.mkdir(parents=True, exist_ok=True)
REPORTS_DIR.mkdir(parents=True, exist_ok=True)


class TranscriptionAnalyzer:
    """Analyzes transcriptions for logical and grammatical issues."""

    def __init__(self, language: str = "de"):
        self.language = language
        self._init_patterns()

    def _init_patterns(self):
        """Initialize error detection patterns."""
        # Patterns that indicate logical/structural problems
        self.logical_error_patterns = {
            "de": [
                # Sentence fragments after periods
                (r'\.\s+[a-zäöü]', 'lowercase_after_period', 'Kleinbuchstabe nach Punkt'),
                # Repeated words
                (r'\b(\w+)\s+\1\b', 'repeated_word', 'Wort wiederholt'),
                # Very short sentences that don't make sense
                (r'(?:^|\.)\s*[A-ZÄÖÜ][a-zäöü]{0,2}\.', 'very_short_sentence', 'Sehr kurzer Satz'),
                # Missing verb indicators (common transcription errors)
                (r'\b(Ich|Du|Er|Sie|Wir|Ihr)\s+[A-ZÄÖÜ]', 'missing_verb', 'Mögliches fehlendes Verb'),
                # Broken sentence patterns
                (r'[,\.]\s*(und|oder|aber|denn|weil)\s*[,\.]', 'broken_conjunction', 'Abgebrochene Konjunktion'),
                # Random punctuation
                (r'\s+[,\.]\s+[,\.]', 'double_punctuation', 'Doppelte Satzzeichen'),
                # Incomplete thoughts
                (r'\b(dass|wenn|weil|obwohl)\s*[,\.]', 'incomplete_subordinate', 'Unvollständiger Nebensatz'),
            ],
            "en": [
                (r'\.\s+[a-z]', 'lowercase_after_period', 'Lowercase after period'),
                (r'\b(\w+)\s+\1\b', 'repeated_word', 'Repeated word'),
                (r'(?:^|\.)\s*[A-Z][a-z]{0,2}\.', 'very_short_sentence', 'Very short sentence'),
                (r'\b(I|You|He|She|We|They)\s+[A-Z]', 'missing_verb', 'Possible missing verb'),
                (r'[,\.]\s*(and|or|but|because)\s*[,\.]', 'broken_conjunction', 'Broken conjunction'),
                (r'\s+[,\.]\s+[,\.]', 'double_punctuation', 'Double punctuation'),
                (r'\b(that|if|because|although)\s*[,\.]', 'incomplete_subordinate', 'Incomplete clause'),
            ]
        }

        # Common transcription errors (phonetic confusions)
        self.phonetic_errors = {
            "de": {
                'ihre': ['ire', 'ihe'],
                'nicht': ['nich', 'ncht'],
                'haben': ['ham', 'habn'],
                'werden': ['wern', 'werdn'],
                'können': ['könn', 'könen'],
                'müssen': ['müssn', 'müsn'],
                'eigentlich': ['eigentich', 'eigntlich'],
                'natürlich': ['natürlich', 'natürlic'],
                'wahrscheinlich': ['wahrscheinich', 'warscheinlich'],
            },
            "en": {
                'probably': ['probly', 'prolly'],
                'definitely': ['definately', 'definitly'],
                'actually': ['actualy', 'actally'],
                'basically': ['basicly', 'basicky'],
            }
        }

    def analyze(self, text: str) -> Dict:
        """
        Analyze transcription for issues.
        Returns dict with issues found and quality score.
        """
        issues = []
        patterns = self.logical_error_patterns.get(self.language, self.logical_error_patterns["de"])

        # Check logical patterns
        for pattern, error_type, description in patterns:
            matches = re.finditer(pattern, text, re.IGNORECASE)
            for match in matches:
                # Get context around the error
                start = max(0, match.start() - 30)
                end = min(len(text), match.end() + 30)
                context = text[start:end]

                issues.append({
                    'type': error_type,
                    'description': description,
                    'position': match.start(),
                    'match': match.group(),
                    'context': f"...{context}...",
                    'severity': self._get_severity(error_type)
                })

        # Check for phonetic errors
        phonetic = self.phonetic_errors.get(self.language, {})
        for correct, wrongs in phonetic.items():
            for wrong in wrongs:
                if wrong.lower() in text.lower():
                    idx = text.lower().find(wrong.lower())
                    issues.append({
                        'type': 'phonetic_error',
                        'description': f'Möglicher Tippfehler: "{wrong}" → "{correct}"',
                        'position': idx,
                        'match': wrong,
                        'context': text[max(0, idx-20):min(len(text), idx+20)],
                        'severity': 'low',
                        'suggestion': correct
                    })

        # Calculate quality score (0-100)
        quality_score = self._calculate_quality_score(text, issues)

        return {
            'issues': issues,
            'issue_count': len(issues),
            'quality_score': quality_score,
            'text_length': len(text),
            'word_count': len(text.split()),
            'analyzed_at': datetime.now().isoformat()
        }

    def _get_severity(self, error_type: str) -> str:
        """Determine severity of error type."""
        high_severity = ['missing_verb', 'incomplete_subordinate', 'broken_conjunction']
        medium_severity = ['lowercase_after_period', 'very_short_sentence']

        if error_type in high_severity:
            return 'high'
        elif error_type in medium_severity:
            return 'medium'
        return 'low'

    def _calculate_quality_score(self, text: str, issues: List[Dict]) -> int:
        """Calculate quality score from 0-100."""
        if not text:
            return 0

        word_count = len(text.split())
        if word_count == 0:
            return 0

        # Start with 100, deduct for issues
        score = 100

        for issue in issues:
            severity = issue.get('severity', 'low')
            if severity == 'high':
                score -= 15
            elif severity == 'medium':
                score -= 8
            else:
                score -= 3

        # Normalize by text length (longer texts may have more issues naturally)
        if word_count > 100:
            score += min(10, word_count // 50)

        return max(0, min(100, score))


class FeedbackCollector:
    """Collects and stores user feedback on transcriptions."""

    def __init__(self):
        self.analyzer = TranscriptionAnalyzer()

    def save_feedback(
        self,
        note_id: str,
        transcription: str,
        rating: int,  # 1-5 stars
        folder_id: Optional[str] = None,
        teacher_name: Optional[str] = None,
        subject: Optional[str] = None,
        user_comments: Optional[str] = None,
        language: str = "de"
    ) -> Dict:
        """
        Save user feedback about a transcription.
        """
        self.analyzer.language = language

        # Analyze transcription
        analysis = self.analyzer.analyze(transcription)

        feedback_data = {
            'feedback_id': f"fb_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{str(note_id)[:8]}",
            'note_id': note_id,
            'rating': rating,
            'folder_id': folder_id,
            'teacher_name': teacher_name,
            'subject': subject,
            'user_comments': user_comments,
            'language': language,
            'transcription_preview': transcription[:500] if len(transcription) > 500 else transcription,
            'word_count': len(transcription.split()),
            'analysis': analysis,
            'timestamp': datetime.now().isoformat(),
            'needs_review': rating <= 2 or analysis['quality_score'] < 60
        }

        # Save to file
        feedback_file = FEEDBACK_DIR / f"{feedback_data['feedback_id']}.json"
        with open(feedback_file, 'w', encoding='utf-8') as f:
            json.dump(feedback_data, f, ensure_ascii=False, indent=2)

        # If quality is bad, create error report
        if feedback_data['needs_review']:
            self._create_error_report(feedback_data, transcription)

        return feedback_data

    def _create_error_report(self, feedback: Dict, full_transcription: str) -> str:
        """Create detailed error report for admin review."""
        report_id = f"report_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

        report_content = f"""Voice Notes - Error Report
{'=' * 50}
Report ID: {report_id}
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

USER FEEDBACK
-------------
Rating: {feedback['rating']}/5 stars
User Comments: {feedback.get('user_comments', 'None')}

METADATA
--------
Note ID: {feedback['note_id']}
Folder: {feedback.get('folder_id', 'None')}
Teacher: {feedback.get('teacher_name', 'None')}
Subject: {feedback.get('subject', 'None')}
Language: {feedback['language']}
Word Count: {feedback['word_count']}

QUALITY ANALYSIS
----------------
Quality Score: {feedback['analysis']['quality_score']}/100
Issues Found: {feedback['analysis']['issue_count']}

DETECTED ISSUES
---------------
"""
        for i, issue in enumerate(feedback['analysis']['issues'], 1):
            report_content += f"""
Issue #{i}:
  Type: {issue['type']}
  Description: {issue['description']}
  Severity: {issue['severity']}
  Context: {issue['context']}
"""
            if 'suggestion' in issue:
                report_content += f"  Suggestion: {issue['suggestion']}\n"

        report_content += f"""

FULL TRANSCRIPTION
------------------
{full_transcription}

{'=' * 50}
End of Report
"""

        # Save report
        report_file = REPORTS_DIR / f"{report_id}.txt"
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write(report_content)

        return str(report_file)

    def get_feedback_stats(self) -> Dict:
        """Get statistics from collected feedback."""
        feedbacks = []

        for file in FEEDBACK_DIR.glob("*.json"):
            try:
                with open(file, 'r', encoding='utf-8') as f:
                    feedbacks.append(json.load(f))
            except:
                continue

        if not feedbacks:
            return {
                'total_feedbacks': 0,
                'average_rating': 0,
                'average_quality_score': 0,
                'needs_review_count': 0
            }

        ratings = [f['rating'] for f in feedbacks if 'rating' in f]
        quality_scores = [f['analysis']['quality_score'] for f in feedbacks if 'analysis' in f]
        needs_review = [f for f in feedbacks if f.get('needs_review', False)]

        return {
            'total_feedbacks': len(feedbacks),
            'average_rating': sum(ratings) / len(ratings) if ratings else 0,
            'average_quality_score': sum(quality_scores) / len(quality_scores) if quality_scores else 0,
            'needs_review_count': len(needs_review),
            'by_rating': {i: len([f for f in feedbacks if f.get('rating') == i]) for i in range(1, 6)}
        }

    def get_pending_reports(self) -> List[Dict]:
        """Get list of error reports pending review."""
        reports = []

        for file in REPORTS_DIR.glob("*.txt"):
            reports.append({
                'filename': file.name,
                'path': str(file),
                'created': datetime.fromtimestamp(file.stat().st_mtime).isoformat(),
                'size': file.stat().st_size
            })

        return sorted(reports, key=lambda x: x['created'], reverse=True)


class LogicCorrector:
    """Advanced logic and grammar correction."""

    def __init__(self, language: str = "de"):
        self.language = language
        self._init_rules()

    def _init_rules(self):
        """Initialize correction rules."""
        self.sentence_rules = {
            "de": [
                # Fix lowercase after period
                (r'\.(\s+)([a-zäöü])', lambda m: f'.{m.group(1)}{m.group(2).upper()}'),
                # Remove double periods
                (r'\.\.+', '.'),
                # Fix space before punctuation
                (r'\s+([,\.!?;:])', r'\1'),
                # Fix missing space after punctuation
                (r'([,\.!?;:])([A-Za-zÄÖÜäöü])', r'\1 \2'),
                # Remove repeated words
                (r'\b(\w+)(\s+\1)+\b', r'\1'),
                # Fix broken conjunctions
                (r',\s*(und|oder|aber)\s*\.', r' \1'),
                (r'\.\s*(und|oder|aber)\s*,', r', \1'),
            ],
            "en": [
                (r'\.(\s+)([a-z])', lambda m: f'.{m.group(1)}{m.group(2).upper()}'),
                (r'\.\.+', '.'),
                (r'\s+([,\.!?;:])', r'\1'),
                (r'([,\.!?;:])([A-Za-z])', r'\1 \2'),
                (r'\b(\w+)(\s+\1)+\b', r'\1'),
                (r',\s*(and|or|but)\s*\.', r' \1'),
                (r'\.\s*(and|or|but)\s*,', r', \1'),
            ]
        }

    def correct(self, text: str) -> Tuple[str, List[str]]:
        """
        Apply logic corrections to text.
        Returns (corrected_text, list_of_changes).
        """
        if not text:
            return text, []

        rules = self.sentence_rules.get(self.language, self.sentence_rules["de"])
        changes = []
        result = text

        for pattern, replacement in rules:
            original = result
            if callable(replacement):
                result = re.sub(pattern, replacement, result)
            else:
                result = re.sub(pattern, replacement, result, flags=re.IGNORECASE)

            if result != original:
                changes.append(f"Applied rule: {pattern[:30]}...")

        # Ensure text starts with capital
        if result and result[0].islower():
            result = result[0].upper() + result[1:]
            changes.append("Capitalized first letter")

        # Ensure text ends with punctuation
        if result and result[-1] not in '.!?':
            result += '.'
            changes.append("Added final period")

        return result, changes


# Singleton instances
_feedback_collector: Optional[FeedbackCollector] = None
_logic_corrector: Optional[LogicCorrector] = None
_analyzer: Optional[TranscriptionAnalyzer] = None


def get_feedback_collector() -> FeedbackCollector:
    global _feedback_collector
    if _feedback_collector is None:
        _feedback_collector = FeedbackCollector()
    return _feedback_collector


def get_logic_corrector(language: str = "de") -> LogicCorrector:
    global _logic_corrector
    if _logic_corrector is None or _logic_corrector.language != language:
        _logic_corrector = LogicCorrector(language)
    return _logic_corrector


def get_analyzer(language: str = "de") -> TranscriptionAnalyzer:
    global _analyzer
    if _analyzer is None or _analyzer.language != language:
        _analyzer = TranscriptionAnalyzer(language)
    return _analyzer


def analyze_transcription(text: str, language: str = "de") -> Dict:
    """Analyze a transcription for quality issues."""
    return get_analyzer(language).analyze(text)


def save_feedback(
    note_id: str,
    transcription: str,
    rating: int,
    **kwargs
) -> Dict:
    """Save user feedback for a transcription."""
    return get_feedback_collector().save_feedback(note_id, transcription, rating, **kwargs)


def apply_logic_correction(text: str, language: str = "de") -> Tuple[str, List[str]]:
    """Apply logic corrections to text."""
    return get_logic_corrector(language).correct(text)
