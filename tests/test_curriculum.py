"""Curriculum lookup tests — formulas, epochs, works, per-grade topics."""
import json
import os
import re
import sys
from pathlib import Path

import pytest

os.environ.setdefault('SECRET_KEY', 'test-secret-for-assistant')
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import curriculum_service as cs
from app.assistant_service import offline_response


# ---------- Data integrity ----------

def test_json_files_valid_and_small():
    base = Path(cs._DATA_DIR)
    total = 0
    for name in ['formeln.json', 'epochen.json', 'topics.json']:
        path = base / name
        assert path.exists(), f'{name} missing'
        data = json.loads(path.read_text(encoding='utf-8'))
        assert data, f'{name} empty'
        total += path.stat().st_size
    assert total < 200_000, f'total size {total} exceeds 200 KB budget'


def test_formeln_schema():
    cs._ensure_loaded()
    seen_ids = set()
    for f in cs._formeln_data['formulas']:
        for field in ('id', 'subject', 'name', 'formula', 'description'):
            assert field in f, f'formula missing {field}: {f.get("name")}'
        assert f['id'] not in seen_ids, f'duplicate id {f["id"]}'
        seen_ids.add(f['id'])
        assert f['subject'] in ('mathe', 'physik', 'chemie')


def test_epochen_schema():
    cs._ensure_loaded()
    names = set()
    for e in cs._epochen_data['epochen']:
        for field in ('name', 'zeitraum', 'merkmale', 'autoren'):
            assert field in e, f'epoch missing {field}: {e.get("name")}'
        assert e['name'] not in names, f'duplicate epoch {e["name"]}'
        names.add(e['name'])


def test_werke_schema():
    cs._ensure_loaded()
    for w in cs._epochen_data['werke']:
        for field in ('titel', 'autor', 'kurzinfo'):
            assert field in w, f'werk missing {field}: {w.get("titel")}'


def test_topics_schema():
    cs._ensure_loaded()
    for grade in range(5, 14):
        key = f'klasse_{grade}'
        assert key in cs._topics_data, f'{key} missing'
        for subject, items in cs._topics_data[key].items():
            assert isinstance(items, list) and items, f'{key}.{subject} empty'


# ---------- Formula lookup ----------

@pytest.mark.parametrize('q,expect_name', [
    ('Mitternachtsformel',                    'Mitternachtsformel'),
    ('abc-Formel',                            'Mitternachtsformel'),
    ('pq-Formel',                             'pq-Formel'),
    ('Was ist die Mitternachtsformel?',       'Mitternachtsformel'),
    ('Formel für Kreisfläche',                'Kreisfläche'),
    ('Formel für Kugelvolumen',               'Kugelvolumen'),
    ('Satz des Pythagoras',                   'Pythagoras'),
    ('Pythagoras',                            'Pythagoras'),
    ('Binomische Formeln',                    'Binomische Formeln'),
    ('Ableitung von sin(x)',                  'sin'),
    ('Ableitung von cos',                     'cos'),
    ('Ableitung von e^x',                     'e^x'),
    ('Ableitung von ln x',                    'ln'),
    ('Produktregel',                          'Produktregel'),
    ('Kettenregel',                           'Kettenregel'),
    ('Ohmsches Gesetz',                       'Ohm'),
    ('Newton 2. Gesetz',                      'Newton'),
    ('Hookesches Gesetz',                     'Hooke'),
    ('Dichte',                                'Dichte'),
    ('Formel für pH-Wert',                    'pH'),
    ('Ideales Gasgesetz',                     'Gas'),
    ('Skalarprodukt',                         'Skalarprodukt'),
    ('Binomialverteilung',                    'Binomialverteilung'),
    ('Logarithmusgesetze',                    'Logarithmus'),
])
def test_formula_lookup(q, expect_name):
    out = cs.try_formula(q)
    assert out is not None, f'no match for {q!r}'
    assert expect_name.lower() in out.lower(), f'{q!r} → {out[:120]!r} missing {expect_name!r}'


def test_formula_returns_latex():
    out = cs.try_formula('Mitternachtsformel')
    assert '$$' in out and '\\frac' in out
    assert 'Beispiel:' in out


@pytest.mark.parametrize('q', [
    'Hallo',
    'Wie geht es dir?',
    'Erkläre mir Faust',
    'Was steht heute an',
    'Irgendwas nicht Formel-artiges',
])
def test_formula_lookup_negative(q):
    assert cs.try_formula(q) is None


def test_formula_lookup_tolerates_case_and_punct():
    for q in ['MITTERNACHTSFORMEL', 'mitternachtsformel!!', '  pq-formel  ', 'pq formel']:
        assert cs.try_formula(q) is not None, q


# ---------- Epoch lookup ----------

@pytest.mark.parametrize('q,expect_name', [
    ('Was ist die Aufklärung?',           'Aufklärung'),
    ('Merkmale Sturm und Drang',          'Sturm und Drang'),
    ('Merkmale der Romantik',             'Romantik'),
    ('Wann war die Weimarer Klassik?',    'Klassik'),
    ('Epoche Realismus',                  'Realismus'),
    ('Expressionismus',                   'Expressionismus'),
    ('Erkläre mir den Barock',            'Barock'),
    ('Autoren Naturalismus',              'Naturalismus'),
])
def test_epoche_lookup(q, expect_name):
    out = cs.try_epoche(q)
    assert out is not None, f'no epoch match for {q!r}'
    assert expect_name.lower() in out.lower()
    assert 'Merkmale' in out or 'Autoren' in out


def test_epoche_lookup_negative():
    assert cs.try_epoche('Mitternachtsformel') is None
    assert cs.try_epoche('Hallo') is None
    assert cs.try_epoche('2+2') is None


# ---------- Work lookup ----------

@pytest.mark.parametrize('q,expect_author', [
    ('Wer schrieb Faust?',                     'Goethe'),
    ('Wer hat Die Verwandlung geschrieben?',   'Kafka'),
    ('Autor von Der Prozess',                  'Kafka'),
    ('Worum geht es in Effi Briest?',          'Fontane'),
    ('Wer schrieb Kabale und Liebe?',          'Schiller'),
    ('Wer schrieb Wilhelm Tell?',              'Schiller'),
    ('Handlung von Woyzeck',                   'Büchner'),
    ('Wer schrieb Homo faber?',                'Frisch'),
    ('Wer verfasste Der Vorleser?',            'Schlink'),
])
def test_werk_lookup(q, expect_author):
    out = cs.try_werk(q)
    assert out is not None, f'no werk match for {q!r}'
    assert expect_author in out


def test_werk_lookup_negative():
    assert cs.try_werk('Mitternachtsformel') is None
    assert cs.try_werk('Was steht heute an?') is None
    assert cs.try_werk('Faust') is None  # needs question intent


# ---------- Topic lookup ----------

def test_topic_single_subject():
    out = cs.try_topics('Welche Themen behandelt man in Klasse 11 Mathe?')
    assert out and 'Klasse 11' in out and 'Analysis' in out


def test_topic_full_grade():
    out = cs.try_topics('Welche Themen lernen wir in Klasse 9?')
    assert out and 'Klasse 9' in out
    assert 'Mathe' in out and 'Deutsch' in out


def test_topic_invalid_grade():
    assert cs.try_topics('Themen in Klasse 99') is None
    assert cs.try_topics('Themen in Klasse 0') is None
    assert cs.try_topics('Themen in Klasse 14') is None


@pytest.mark.parametrize('grade', list(range(1, 14)))
def test_every_grade_has_data(grade):
    out = cs.try_topics(f'Welche Themen lernen wir in Klasse {grade}?')
    assert out is not None, f'Klasse {grade}: no data'
    assert f'Klasse {grade}' in out


@pytest.mark.parametrize('q,must_contain', [
    ('Was ist Photosynthese?',                'Chloroplast'),
    ('Erkläre mir die Mitose',                'Tochterzellen'),
    ('Was bedeutet DNA?',                     'Erbinformation'),
    ('Was ist eine Metapher?',                'Sprachliches Bild'),
    ('Was ist eine Anapher?',                 'Wiederholung'),
    ('Erkläre die Französische Revolution',   '1789'),
    ('Was war der Erste Weltkrieg?',          '1914'),
    ('Was ist der Holocaust?',                'sechs Millionen'),
    ('Was ist Stetigkeit?',                   'lim'),
    ('Was ist eine Kurvendiskussion?',        'Definitionsbereich'),
    ('Was ist ein Wendepunkt?',               'Krümmung'),
    ('Was ist ein Atom?',                     'Atomkern'),
    ('Was ist eine Säure?',                   'Protonen'),
    ('Was ist Subjonctif?',                   'Modus'),
    ('Was ist AcI?',                          'Akkusativ'),
    ('Was ist Demokratie?',                   'Volkssouveränität'),
    ('Was ist das Grundgesetz?',              '1949'),
    ('Was ist Theodizee?',                    'Leid'),
    ('Was ist Plattentektonik?',              'Lithosphären'),
    ('Was ist Klimawandel?',                  'CO'),
    ('Was ist Energie?',                      'Joule'),
    ('Was ist eine Synapse?',                 'Neurotransmitter'),
    ('Was ist Wahrscheinlichkeit?',           'Laplace'),
    ('Was ist Bruchrechnung?',                'Zähler'),
    ('Was ist eine Inhaltsangabe?',           'Präsens'),
])
def test_concept_lookup(q, must_contain):
    out = cs.try_concept(q)
    assert out is not None, f'no match: {q!r}'
    assert must_contain in out, f'{q!r}: missing {must_contain!r} in {out[:200]!r}'


def test_concept_negation_blocked():
    assert cs.try_concept('Ich habe keine Lust auf Photosynthese') is None
    assert cs.try_concept('Mathe ist nicht meine Stärke') is None


def test_concept_question_with_ignorance_passes():
    # User asks but admits not knowing — must still answer.
    out = cs.try_concept('Was ist Photosynthese? Ich weiß es nicht mehr.')
    assert out is not None and 'Chloroplast' in out


@pytest.mark.parametrize('q,subject_keyword', [
    ('Themen Klasse 1 Deutsch',           'Buchstaben'),
    ('Themen Klasse 2 Mathe',             'Einmaleins'),
    ('Themen Klasse 3 Sachunterricht',    'Bundesland'),
    ('Themen Klasse 4 Englisch',          'Past'),
    ('Themen Klasse 5 Biologie',          'Wirbel'),
    ('Themen Klasse 6 Französisch',       'Présent'),
    ('Themen Klasse 6 Latein',            'Deklination'),
    ('Themen Klasse 7 Politik',           'Demokratie'),
    ('Themen Klasse 8 Informatik',        'Python'),
    ('Themen Klasse 9 Religion',          'Theodizee'),
    ('Themen Klasse 10 Ethik',            'Verantwortung'),
    ('Themen Klasse 11 Philosophie',      'Erkenntnis'),
    ('Themen Klasse 11 Psychologie',      'Wahrnehmung'),
    ('Themen Klasse 11 Wirtschaft',       'Markt'),
    ('Themen Klasse 12 Pädagogik',        'Erziehung'),
    ('Themen Klasse 12 Kunst',            'Bauhaus'),
    ('Themen Klasse 13 Sport',            'Bewegungslehre'),
    ('Inhalte Klasse 11 Spanisch',        'Lateinamerika'),
    ('Themen Klasse 5 Sport',             'Leichtathletik'),
    ('Themen Klasse 8 Musik',             'Klassik'),
])
def test_every_subject_has_data(q, subject_keyword):
    out = cs.try_topics(q)
    assert out is not None, f'{q!r}: no match'
    assert subject_keyword in out, f'{q!r}: missing {subject_keyword!r} in: {out[:200]!r}'


def test_topic_requires_intent():
    assert cs.try_topics('Klasse 11 ist anstrengend') is None


@pytest.mark.parametrize('q,grade_in_out,subject_match', [
    ('Was sind die Themen in der 11. Klasse am Gymnasium im Physik Grundkurs?', 'Klasse 11', 'Feld'),
    ('11. Klasse Physik Themen',                                                 'Klasse 11', 'Feld'),
    ('Inhalte Klasse 12 Chemie',                                                 'Klasse 12', 'Gleichgewicht'),
    ('Welche Inhalte hat der Grundkurs Biologie in der 12. Klasse?',            'Klasse 12', 'Molekular'),
    ('Themen in der 9. Klasse Mathe',                                            'Klasse 9',  'Mitternachtsformel'),
    ('Lehrplan 10. Klasse Geschichte',                                           'Klasse 10', 'Holocaust'),
    ('Was lernt man in der 7. Klasse Physik?',                                   'Klasse 7',  'Stromkreis'),
    ('Leistungskurs Mathe 13. Klasse Themen',                                    'Klasse 13', 'Analysis'),
])
def test_topic_phrasing_variants(q, grade_in_out, subject_match):
    out = cs.try_topics(q)
    assert out is not None, f'no topic match for {q!r}'
    assert grade_in_out in out
    assert subject_match in out, f'{q!r} → expected {subject_match!r} in output, got {out[:200]!r}'


# ---------- Router try_curriculum ----------

def test_router_prefers_formula():
    out = cs.try_curriculum('Was ist die pq-Formel?')
    assert out and 'pq-Formel' in out and '$$' in out


def test_router_falls_through_to_werk():
    out = cs.try_curriculum('Wer schrieb Faust?')
    assert out and 'Goethe' in out


def test_router_epoch():
    out = cs.try_curriculum('Merkmale der Romantik')
    assert out and 'Romantik' in out


def test_router_topics():
    out = cs.try_curriculum('Themen in Klasse 12 Deutsch')
    assert out and 'Klasse 12' in out


def test_router_returns_none_for_unrelated():
    for q in ['Hallo, wie geht es dir?', '2+2', 'Bitte Tagesübersicht', 'Foo bar baz quux']:
        assert cs.try_curriculum(q) is None, f'unexpected match for {q!r}'


# ---------- Integration with offline_response ----------

def test_offline_response_routes_formula():
    r = offline_response('Was ist die Mitternachtsformel?')
    assert 'Mitternachtsformel' in r and '$$' in r


def test_offline_response_routes_werk():
    r = offline_response('Wer schrieb Die Verwandlung?')
    assert 'Kafka' in r


def test_offline_response_routes_epoche():
    r = offline_response('Merkmale Sturm und Drang')
    assert 'Sturm und Drang' in r


def test_offline_response_routes_topics():
    r = offline_response('Welche Themen lernt man in Klasse 11 Physik?')
    assert 'Klasse 11' in r and 'Feld' in r


def test_offline_response_math_still_wins():
    # Math tool is earlier in chain than curriculum — make sure routing order is right.
    r = offline_response('2+2')
    assert '4' in r
    r = offline_response('wurzel aus 16')
    assert '4' in r


def test_offline_response_no_false_match_on_casual():
    for q in ['Das Wetter ist schön heute', 'Ich habe Hunger',
              'Mein Bruder ist 12 Jahre alt']:
        r = offline_response(q)
        # Should NOT route to curriculum (no formulas/epochs/works/topics in plain chitchat).
        assert '$$' not in r, f'false formula match on {q!r}: {r!r}'
        assert 'Epoche' not in r or 'konnte' in r.lower()


# ---------- Normalize helper ----------

from app.assistant_service import _validate_due_date, _validate_due_time, _days_suffix, _in_days
from datetime import date, timedelta


@pytest.mark.parametrize('raw,today,expected', [
    ('2030-06-15',                 date(2026, 4, 23), '2030-06-15'),
    ('2024-01-01',                 date(2026, 4, 23), None),            # past — reject
    ('YYYY-MM-DD',                 date(2026, 4, 23), None),            # placeholder
    ('TBD',                        date(2026, 4, 23), None),
    ('null',                       date(2026, 4, 23), None),
    ('',                           date(2026, 4, 23), None),
    (None,                         date(2026, 4, 23), None),
    ('2026-13-40',                 date(2026, 4, 23), None),            # malformed
    ('15.06.2030',                 date(2026, 4, 23), '2030-06-15'),    # German format
    ('01.01.24',                   date(2026, 4, 23), None),            # past, 2-digit year
    ('01.01.30',                   date(2026, 4, 23), '2030-01-01'),    # 2-digit year works
    ('   2027-03-12  ',            date(2026, 4, 23), '2027-03-12'),    # whitespace tolerated
])
def test_validate_due_date(raw, today, expected, monkeypatch):
    from app import assistant_service
    class FakeDatetime:
        @staticmethod
        def now():
            class X:
                @staticmethod
                def date(): return today
            return X()
    monkeypatch.setattr(assistant_service, 'datetime', type('D', (), {
        'now': staticmethod(lambda: type('T', (), {'date': staticmethod(lambda: today)})()),
        'strptime': assistant_service.datetime.strptime,
        '__call__': assistant_service.datetime.__call__,
    })) if False else None
    assert _validate_due_date(raw, today=today) == expected


@pytest.mark.parametrize('raw,expected', [
    ('14:30', '14:30'),
    ('9:05', '09:05'),
    ('25:00', None),
    ('12:70', None),
    ('HH:MM', None),
    ('', None),
    (None, None),
    ('not a time', None),
])
def test_validate_due_time(raw, expected):
    assert _validate_due_time(raw) == expected


@pytest.mark.parametrize('days,expected', [
    (-3, ' (vor 3 Tagen)'),
    (-1, ''),
    (0, ''),
    (1, ''),
    (3, ''),
    (6, ''),
    (7, ' (in 7 Tagen)'),
    (30, ' (in 30 Tagen)'),
])
def test_days_suffix(days, expected):
    assert _days_suffix(days) == expected


@pytest.mark.parametrize('days,expected', [
    (0, 'heute'),
    (1, 'morgen'),
    (-1, 'gestern'),
    (2, 'in 2 Tagen'),
    (5, 'in 5 Tagen'),
    (-3, 'vor 3 Tagen'),
])
def test_in_days_singular_plural(days, expected):
    assert _in_days(days) == expected


def test_no_1_tage_bug_in_exam_output():
    """Regression: 'in 1 Tagen' / '1 Tage' must never appear in exam output."""
    from app.assistant_service import _build_exams_response
    from unittest.mock import patch
    # Build fake data: one exam in exactly 1 day.
    tomorrow = (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d')
    in_five = (datetime.now() + timedelta(days=5)).strftime('%Y-%m-%d')
    in_twenty = (datetime.now() + timedelta(days=20)).strftime('%Y-%m-%d')
    def fake_load():
        return (
            [{'id': 's1', 'name': 'Physik'}],
            [],
            [
                {'title': 'Klausur A', 'subject_id': 's1', 'date': tomorrow},
                {'title': 'Klausur B', 'subject_id': 's1', 'date': in_five},
                {'title': 'Klausur C', 'subject_id': 's1', 'date': in_twenty},
            ],
            [],
            [],
        )
    from datetime import datetime as dt
    out = _build_exams_response(fake_load, dt.now().strftime('%Y-%m-%d'))
    assert '1 Tage)' not in out, f'singular bug: {out!r}'
    assert 'in 1 Tagen' not in out, f'singular bug: {out!r}'
    # "morgen" alone with no "(1 Tage)" trailing
    assert 'morgen ❗' in out or 'morgen\n' in out or out.rstrip().endswith('morgen') or 'morgen ' in out
    # Duplicate day count eliminated
    assert 'Tagen) (5 Tage)' not in out
    # Farther-out exams still get a "in N Tagen" suffix (grammatically correct)
    assert 'in 20 Tagen' in out


from datetime import datetime


def test_normalize_umlauts():
    assert cs._normalize('Aufklärung') == 'aufklaerung'
    assert cs._normalize('Große Öse ÄUSSERST') == 'grosse oese aeusserst'


def test_normalize_strips_punctuation():
    assert cs._normalize('Pythagoras!!!!') == 'pythagoras'
    assert cs._normalize('  Faust???  ') == 'faust'


# ---------- Performance ----------

def test_curriculum_lookup_fast():
    import time
    queries = [
        'Was ist die Mitternachtsformel?',
        'Wer schrieb Faust?',
        'Merkmale der Romantik',
        'Themen Klasse 11 Mathe',
        'Ableitung von sin(x)',
        'Nichts davon',
    ]
    t0 = time.perf_counter()
    N = 500
    for _ in range(N):
        for q in queries:
            cs.try_curriculum(q)
    elapsed = time.perf_counter() - t0
    avg_us = (elapsed / (N * len(queries))) * 1_000_000
    assert avg_us < 3000, f'too slow: {avg_us:.0f}µs per query'


# ---------- Safety: malformed / giant inputs ----------

@pytest.mark.parametrize('edge', [
    '',
    '   ',
    '?' * 500,
    'x' * 300,
    '🎉🎉🎉',
    '\n\n\n',
])
def test_malformed_input(edge):
    cs.try_formula(edge)
    cs.try_epoche(edge)
    cs.try_werk(edge)
    cs.try_topics(edge)
    cs.try_curriculum(edge)


def test_corrupt_json_tolerated(tmp_path, monkeypatch):
    (tmp_path / 'formeln.json').write_text('{{{ not json', encoding='utf-8')
    (tmp_path / 'epochen.json').write_text('not json', encoding='utf-8')
    (tmp_path / 'topics.json').write_text('[] broken', encoding='utf-8')
    monkeypatch.setattr(cs, '_DATA_DIR', tmp_path)
    monkeypatch.setattr(cs, '_formeln_data', None)
    monkeypatch.setattr(cs, '_epochen_data', None)
    monkeypatch.setattr(cs, '_topics_data', None)
    monkeypatch.setattr(cs, '_formeln_index', {})
    monkeypatch.setattr(cs, '_epochen_index', {})
    monkeypatch.setattr(cs, '_werke_index', {})
    assert cs.try_formula('Mitternachtsformel') is None
    assert cs.try_epoche('Romantik') is None
    assert cs.try_werk('Wer schrieb Faust?') is None
    assert cs.try_topics('Themen Klasse 11 Mathe') is None
