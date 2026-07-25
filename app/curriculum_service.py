from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Optional

_DATA_DIR = Path(__file__).parent / 'curriculum'

_formeln_data = None
_formeln_index: dict = {}
_epochen_data = None
_epochen_index: dict = {}
_werke_index: dict = {}
_topics_data = None
_concepts_data = None
_concepts_index: dict = {}


def _normalize(s: str) -> str:
    if not s:
        return ''
    s = s.lower().strip()
    s = (s.replace('ä', 'ae').replace('ö', 'oe').replace('ü', 'ue')
         .replace('ß', 'ss')
         .replace('–', '-').replace('—', '-')
         .replace('„', '"').replace('“', '"').replace('”', '"'))
    s = re.sub(r'[^a-z0-9\s\-]', ' ', s)
    s = re.sub(r'\s+', ' ', s)
    return s.strip()


def _ensure_loaded():
    global _formeln_data, _epochen_data, _topics_data
    if _formeln_data is None:
        try:
            _formeln_data = json.loads((_DATA_DIR / 'formeln.json').read_text(encoding='utf-8'))
        except (OSError, ValueError):
            _formeln_data = {'formulas': []}
        for entry in _formeln_data.get('formulas', []):
            for name in [entry.get('name', '')] + entry.get('aliases', []):
                key = _normalize(name)
                if key:
                    _formeln_index.setdefault(key, entry)

    if _epochen_data is None:
        try:
            _epochen_data = json.loads((_DATA_DIR / 'epochen.json').read_text(encoding='utf-8'))
        except (OSError, ValueError):
            _epochen_data = {'epochen': [], 'werke': []}
        for entry in _epochen_data.get('epochen', []):
            for name in [entry.get('name', '')] + entry.get('aliases', []):
                key = _normalize(name)
                if key:
                    _epochen_index.setdefault(key, entry)
        for entry in _epochen_data.get('werke', []):
            for name in [entry.get('titel', '')] + entry.get('kurztitel', []):
                key = _normalize(name)
                if key:
                    _werke_index.setdefault(key, entry)

    if _topics_data is None:
        try:
            _topics_data = json.loads((_DATA_DIR / 'topics.json').read_text(encoding='utf-8'))
        except (OSError, ValueError):
            _topics_data = {}

    global _concepts_data
    if _concepts_data is None:
        try:
            _concepts_data = json.loads((_DATA_DIR / 'concepts.json').read_text(encoding='utf-8'))
        except (OSError, ValueError):
            _concepts_data = {'concepts': []}
        for entry in _concepts_data.get('concepts', []):
            for name in [entry.get('name', '')] + entry.get('aliases', []):
                key = _normalize(name)
                if key:
                    _concepts_index.setdefault(key, entry)


def _format_formula(f: dict) -> str:
    lines = [f'**{f["name"]}**']
    lines.append(f'$${f["formula"]}$$')
    if f.get('description'):
        lines.append(f['description'])
    if f.get('example'):
        lines.append(f'*Beispiel:* {f["example"]}')
    return '\n\n'.join(lines)


def _format_epoche(e: dict) -> str:
    lines = [f'**{e["name"]}** ({e.get("zeitraum", "")})']
    if e.get('merkmale'):
        lines.append('**Merkmale:**')
        lines.extend(f'  • {m}' for m in e['merkmale'])
    if e.get('autoren'):
        lines.append('**Wichtige Autoren:** ' + ', '.join(e['autoren']))
    if e.get('werke'):
        lines.append('**Bekannte Werke:**')
        lines.extend(f'  • {w}' for w in e['werke'])
    return '\n'.join(lines)


def _format_werk(w: dict) -> str:
    lines = [f'**{w["titel"]}** — {w.get("autor", "")}']
    meta = []
    if w.get('jahr'):
        meta.append(w['jahr'])
    if w.get('gattung'):
        meta.append(w['gattung'])
    if w.get('epoche'):
        meta.append(w['epoche'])
    if meta:
        lines.append('*' + ' · '.join(meta) + '*')
    if w.get('kurzinfo'):
        lines.append('')
        lines.append(w['kurzinfo'])
    return '\n'.join(lines)


_ARTICLE_STRIP = re.compile(r'^(?:der|die|das|dem|den|des|ein|eine|einen|einem|einer|eines)\s+', re.IGNORECASE)


def _find_formel(query_norm: str) -> Optional[dict]:
    if not query_norm:
        return None
    # Strip leading articles so "den kreis" → "kreis" finds Kreisfläche/-umfang.
    q = _ARTICLE_STRIP.sub('', query_norm).strip()
    if q in _formeln_index:
        return _formeln_index[q]
    best = None
    best_len = 0
    for key, entry in _formeln_index.items():
        if len(key) < 4:
            continue
        if key == q or key in q or q in key:
            if len(key) > best_len:
                best = entry
                best_len = len(key)
    return best


_NEG_MARKERS = re.compile(r'(?<!\w)(?:nicht|kein(?:e|er|en|em|es)?|niemals|ohne)(?!\w)', re.IGNORECASE)
_QUESTION_STARTERS = re.compile(r'^\s*(?:wer|was|wann|wo|wie|warum|welch|gib|zeig|nenne|sage)\b', re.IGNORECASE)


def _is_negated(norm: str) -> bool:
    # If the sentence is a direct question ("wer schrieb…", "was ist…"), a later
    # "nicht/kein" is usually the user admitting ignorance — don't skip the lookup.
    if _QUESTION_STARTERS.match(norm):
        return False
    return bool(_NEG_MARKERS.search(norm))


def try_formula(message: str) -> Optional[str]:
    _ensure_loaded()
    raw = message.strip()
    if not raw:
        return None
    if len(raw) > 400:
        raw = raw[:400]

    norm = _normalize(raw)
    if _is_negated(norm):
        return None

    patterns = [
        r'(?:was\s+ist\s+die\s+)?formel\s+(?:fuer|von|zu|des|der)\s+(.+?)\s*[?.!]*$',
        r'(?:wie\s+lautet\s+)(?:die\s+|das\s+)?(.+?)\s*[?.!]*$',
        r'(?:wie\s+ist\s+|was\s+ist\s+)?die\s+ableitung\s+von\s+(.+?)\s*[?.!]*$',
        r'ableitung\s+(?:von\s+)?(.+?)\s*[?.!]*$',
        r'wie\s+leitet\s+man\s+(.+?)\s+ab\b',
        r'(?:stammfunktion|integral)\s+(?:von\s+)?(.+?)\s*[?.!]*$',
        r'wie\s+berechnet\s+man\s+(?:den|die|das)?\s*(.+?)\s*[?.!]*$',
        r'mit\s+welcher\s+formel\s+(?:berechnet|berechne|bestimmt)\s+(?:man\s+)?(?:den|die|das)?\s*(.+?)\s*[?.!]*$',
        r'wie\s+geht\s+(?:die\s+)?(.+?)\s*[?.!]*$',
        r'(.+?)[\s-]formel\s*[?.!]*$',
    ]
    for pat in patterns:
        m = re.search(pat, norm)
        if m:
            entry = _find_formel(_normalize(m.group(1)))
            if entry:
                return _format_formula(entry)

    entry = _find_formel(norm)
    return _format_formula(entry) if entry else None


def try_epoche(message: str) -> Optional[str]:
    _ensure_loaded()
    raw = message.strip()
    if not raw or len(raw) > 400:
        return None
    norm = _normalize(raw)
    if _is_negated(norm):
        return None

    if not re.search(r'\b(?:epoche|literatur|merkmale|zeitraum|autoren|wann war|was ist|erklaere?|erkläre?)\b', norm) \
            and not any(k in norm for k in _epochen_index):
        return None

    patterns = [
        r'(?:merkmale|zeitraum|autoren)\s+(?:der\s+|des\s+|von\s+|vom\s+)?(.+?)\s*[?.!]*$',
        r'(?:wann\s+war|wann\s+ist)\s+(?:die\s+)?(.+?)\s*[?.!]*$',
        r'(?:was\s+ist|was\s+war|erklaere?|erkläre?)\s+(?:die\s+|der\s+|das\s+)?(.+?)\s*[?.!]*$',
        r'epoche\s+(.+?)\s*[?.!]*$',
    ]
    for pat in patterns:
        m = re.search(pat, norm)
        if m:
            q = _normalize(m.group(1))
            if q in _epochen_index:
                return _format_epoche(_epochen_index[q])

    best = None
    best_len = 0
    for key, entry in _epochen_index.items():
        if re.search(r'(?<!\w)' + re.escape(key) + r'(?!\w)', norm) and len(key) > best_len:
            best = entry
            best_len = len(key)
    return _format_epoche(best) if best else None


def try_werk(message: str) -> Optional[str]:
    _ensure_loaded()
    raw = message.strip()
    if not raw or len(raw) > 400:
        return None
    norm = _normalize(raw)
    if _is_negated(norm):
        return None

    lookup_intent = re.search(r'\b(wer\s+(?:schrieb|verfasste|hat\s+geschrieben|geschrieben\s+hat)|autor\s+(?:von|des|der|vom)|wann\s+(?:entstand|erschien|wurde|kam)|worum\s+geht\s+es|handlung\s+von|inhalt\s+von|um\s+was\s+geht\s+es\s+in|geschrieben\s+hat|verfasst\s+hat)\b', norm)

    patterns = [
        r'(?:wer\s+schrieb|wer\s+verfasste|wer\s+hat|autor\s+(?:von|des|der|vom))\s+(?:den\s+|die\s+|das\s+|dem\s+)?(.+?)(?:\s+(?:geschrieben|verfasst))?\s*[?.!]*$',
        r'\bwer\s+(?:den\s+|die\s+|das\s+|dem\s+)?(.+?)\s+(?:geschrieben|verfasst)\s+hat\b',
        r'wann\s+(?:entstand|erschien|wurde|kam)\s+(?:der\s+|die\s+|das\s+)?(.+?)(?:\s+(?:geschrieben|veroeffentlicht|heraus))?\s*[?.!]*$',
        r'(?:worum\s+geht\s+es|handlung\s+von|um\s+was\s+geht\s+es\s+in|inhalt\s+von)\s+(?:in\s+)?(?:der\s+|die\s+|das\s+|dem\s+)?(.+?)\s*[?.!]*$',
    ]
    for pat in patterns:
        m = re.search(pat, norm)
        if m:
            q = _normalize(m.group(1))
            if q in _werke_index:
                return _format_werk(_werke_index[q])
            for key, entry in _werke_index.items():
                if key == q or (len(key) >= 5 and key in q):
                    return _format_werk(entry)

    if not lookup_intent:
        return None

    best = None
    best_len = 0
    for key, entry in _werke_index.items():
        if len(key) >= 5 and re.search(r'(?<!\w)' + re.escape(key) + r'(?!\w)', norm) and len(key) > best_len:
            best = entry
            best_len = len(key)
    return _format_werk(best) if best else None


def try_topics(message: str) -> Optional[str]:
    _ensure_loaded()
    if not message or len(message) > 200:
        return None
    norm = _normalize(message)

    m_grade = re.search(r'(?:klasse\s*(\d{1,2})|(\d{1,2})\.?\s*klasse)', norm)
    if not m_grade:
        return None
    grade = int(m_grade.group(1) or m_grade.group(2))
    if not (1 <= grade <= 13):
        return None

    if not re.search(r'\b(themen|lern|behandel|durch|stoff|lehrplan|themenuebersicht|themenübersicht|inhalte|inhalt|kurs|grundkurs|leistungskurs)', norm):
        return None

    subject_map = {
        'mathe': ['mathe', 'mathematik'],
        'deutsch': ['deutsch'],
        'englisch': ['englisch', 'english'],
        'franzoesisch': ['franzoesisch', 'französisch', 'francais'],
        'latein': ['latein', 'lateinisch'],
        'spanisch': ['spanisch', 'espanol'],
        'physik': ['physik'],
        'chemie': ['chemie'],
        'biologie': ['biologie', 'bio'],
        'geschichte': ['geschichte', 'history'],
        'erdkunde': ['erdkunde', 'geographie', 'geografie'],
        'politik': ['politik', 'sozialkunde', 'gemeinschaftskunde'],
        'religion': ['religion', 'reli'],
        'ethik': ['ethik', 'lebenskunde', 'ler'],
        'philosophie': ['philosophie', 'philo'],
        'psychologie': ['psychologie', 'psycho'],
        'paedagogik': ['paedagogik', 'pädagogik'],
        'kunst': ['kunst'],
        'musik': ['musik'],
        'sport': ['sport', 'sportunterricht'],
        'informatik': ['informatik', 'computer', 'it'],
        'wirtschaft': ['wirtschaft', 'wat'],
        'sachunterricht': ['sachunterricht', 'sachkunde', 'heimatkunde'],
    }
    wanted_subject = None
    for key, variants in subject_map.items():
        if any(re.search(r'(?<!\w)' + re.escape(v) + r'(?!\w)', norm) for v in variants):
            wanted_subject = key
            break

    if not _topics_data:
        return None
    topics = _topics_data.get(f'klasse_{grade}', {})
    if not topics:
        return f'Für Klasse {grade} sind leider keine Themen hinterlegt.'

    if wanted_subject and wanted_subject in topics:
        items = topics[wanted_subject]
        lines = [f'**Klasse {grade} — {wanted_subject.capitalize()}:**']
        lines.extend(f'  • {t}' for t in items)
        return '\n'.join(lines)

    lines = [f'**Klasse {grade} — typische Themen:**']
    for subj, items in topics.items():
        lines.append(f'*{subj.capitalize()}:* ' + '; '.join(items[:4]))
    return '\n'.join(lines)


def _format_concept(c: dict) -> str:
    parts = [f'**{c["name"]}**']
    summary = c.get('summary', '')
    if summary:
        parts.append(summary)
    return '\n\n'.join(parts)


def try_concept(message: str) -> Optional[str]:
    _ensure_loaded()
    raw = message.strip()
    if not raw or len(raw) > 400:
        return None
    norm = _normalize(raw)
    if _is_negated(norm):
        return None

    patterns = [
        r'(?:was\s+(?:ist|sind|war|waren|bedeutet|versteht\s+man\s+unter))\s+(?:der\s+|die\s+|das\s+|den\s+|dem\s+|ein\s+|eine\s+)?(.+?)\s*[?.!]*$',
        r'erkl(?:ä|ae)re?\s+(?:mir\s+)?(?:der\s+|die\s+|das\s+|den\s+|dem\s+|ein\s+|eine\s+)?(.+?)\s*[?.!]*$',
        r'definition\s+(?:von|für)\s+(.+?)\s*[?.!]*$',
        r'(.+?)\s+(?:einfach\s+)?(?:erkl(?:ä|ae)rt|erkl(?:ä|ae)ren)\s*[?.!]*$',
    ]
    for pat in patterns:
        m = re.search(pat, norm)
        if m:
            q = _normalize(m.group(1))
            q_strip = re.sub(r'^(?:der|die|das|dem|den|ein|eine|einen|einem|einer|eines)\s+', '', q).strip()
            for variant in (q, q_strip):
                if variant in _concepts_index:
                    return _format_concept(_concepts_index[variant])
            for key, entry in _concepts_index.items():
                if len(key) >= 4 and (key in q_strip or q_strip in key):
                    return _format_concept(entry)

    if norm in _concepts_index:
        return _format_concept(_concepts_index[norm])
    best = None
    best_len = 0
    for key, entry in _concepts_index.items():
        if len(key) < 5:
            continue
        if re.search(r'(?<!\w)' + re.escape(key) + r'(?!\w)', norm) and len(key) > best_len:
            best = entry
            best_len = len(key)
    return _format_concept(best) if best else None


def try_curriculum(message: str) -> Optional[str]:
    for fn in (try_formula, try_werk, try_epoche, try_concept, try_topics):
        try:
            out = fn(message)
            if out:
                return out
        except Exception:
            continue
    return None
