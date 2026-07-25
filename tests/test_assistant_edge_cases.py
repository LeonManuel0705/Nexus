"""Adversarial / edge-case tests for the assistant's offline surface."""
import json
import os
import sys
import time
from datetime import datetime, timedelta
from pathlib import Path
from unittest.mock import patch

import pytest

os.environ.setdefault('SECRET_KEY', 'test-secret-for-assistant')
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import offline_tools
from app import research_service as rs
from app.assistant_service import (
    extract_ollama_actions,
    is_data_query,
    offline_response,
)


# ---------- Math: security / edge cases ----------

@pytest.mark.parametrize('evil', [
    '__import__("os").system("rm -rf /")',
    'eval("2+2")',
    'exec("print(1)")',
    'open("/etc/passwd").read()',
    'lambda x: x',
    'print(1); 2+2',
    '1/0',
    '1e308 * 1e308',
])
def test_calc_rejects_code_injection(evil):
    r = offline_tools.try_calc(evil)
    assert r is None or 'Fehler' in r or 'nicht' in r.lower(), f'calc accepted evil {evil!r}: {r!r}'


@pytest.mark.parametrize('edge', [
    '',
    ' ',
    '?',
    '!',
    '...',
    '0',
    '-',
    '+',
    '(',
    '++',
    '/',
])
def test_calc_tolerates_garbage(edge):
    offline_tools.try_calc(edge)


def test_calc_division_by_zero():
    r = offline_tools.try_calc('10 durch 0')
    assert r and ('nicht definiert' in r or 'Teilen durch 0' in r)


def test_calc_negative_root():
    r = offline_tools.try_calc('wurzel aus -4')
    assert r is None or 'nicht' in r.lower() or 'error' not in r.lower()


def test_calc_large_numbers():
    r = offline_tools.try_calc('999999 * 888888')
    assert r and '888887111112' in r


def test_calc_decimals():
    r = offline_tools.try_calc('3,14 mal 2')
    assert r and ('6,28' in r or '6.28' in r)


def test_calc_percentage_edge():
    assert '0' in offline_tools.try_calc('0% von 100')
    assert '100' in offline_tools.try_calc('100% von 100')
    assert '50' in offline_tools.try_calc('50% von 100')


# ---------- Dates: boundaries ----------

def test_date_leap_year():
    r = offline_tools.try_date_math('Welcher Wochentag ist der 29.02.2024?')
    assert r and 'Donnerstag' in r


def test_date_invalid_day():
    r = offline_tools.try_date_math('Welcher Wochentag ist der 32.13.2026?')
    assert r is None


def test_date_two_digit_year():
    r = offline_tools.try_date_math('Welcher Wochentag ist der 01.01.26?')
    assert r and ('2026' in r or 'Donnerstag' in r)


def test_date_future_weeks():
    r = offline_tools.try_date_math('Was für ein Tag ist in 52 Wochen?')
    assert r


def test_date_past():
    r = offline_tools.try_date_math('Wie viele Tage bis zum 01.01.2020?')
    assert r and ('zurück' in r or 'Tage' in r)


def test_date_today_zero():
    today = datetime.now().strftime('%d.%m.%Y')
    r = offline_tools.try_date_math(f'Wie viele Tage bis zum {today}?')
    assert r and 'heute' in r.lower()


# ---------- Units: coverage ----------

@pytest.mark.parametrize('msg,expect', [
    ('5 meile in km',                   '8'),      # 5 * 1.609 = 8.05
    ('10 ft in m',                      '3,048'),
    ('2 pfund in kg',                   '0,9'),
    ('3,785 l in gallonen',             '1'),
    ('-40 C in F',                      '-40'),     # famous intersection
    ('-40 F in C',                      '-40'),
    ('0 K in C',                        '-273'),
])
def test_unit_conversion_range(msg, expect):
    r = offline_tools.try_unit_convert(msg)
    assert r and expect in r, f'{msg!r} → {r!r} missing {expect!r}'


def test_unit_conversion_unknown_returns_none():
    assert offline_tools.try_unit_convert('5 banana in apfel') is None


# ---------- Entity extraction: adversarial ----------

@pytest.mark.parametrize('msg,expected', [
    ('Wer ist???',                                         None),
    ('',                                                   None),
    ('a',                                                  None),
    ('x' * 1000,                                           None),
    ('Infos zu \n\n\n',                                    None),
    ('Wer ist Albert Einstein und was hat er für Werke?',  'Albert Einstein'),
    ('Wer ist "Albert Einstein"?',                         'Albert Einstein'),
    ('Wer ist  Albert   Einstein  ?',                      'Albert Einstein'),
])
def test_entity_extraction_edge(msg, expected):
    got = rs.extract_entity(msg)
    if expected is None:
        assert got is None, f'{msg!r} → {got!r}, expected None'
    else:
        assert expected in (got or ''), f'{msg!r} → {got!r}, expected contains {expected!r}'


def test_wants_research_ignores_code():
    assert not rs.wants_research('$$\\int_0^1 x^2 dx$$')
    assert not rs.wants_research('\\frac{1}{2} + \\frac{1}{3}')


def test_wants_research_short_circuits_on_length():
    assert not rs.wants_research('x' * 500)


# ---------- Action extraction: adversarial JSON ----------

def test_extract_nested_json():
    txt = 'ok [ACTION]{"type":"x","data":{"nested":{"deep":true}}}[/ACTION] done'
    cleaned, actions = extract_ollama_actions(txt)
    assert len(actions) == 1
    assert actions[0]['data']['nested']['deep'] is True
    assert 'ACTION' not in cleaned


def test_extract_string_with_braces():
    txt = '[ACTION]{"type":"note","text":"Der Code: {foo}"}[/ACTION]'
    _, actions = extract_ollama_actions(txt)
    assert actions and actions[0]['text'] == 'Der Code: {foo}'


def test_extract_invalid_json_safe():
    txt = '[ACTION]{"type": broken}[/ACTION] and more text'
    cleaned, actions = extract_ollama_actions(txt)
    assert '[ACTION]' not in cleaned
    assert actions == []


def test_extract_multiple_actions():
    txt = 'A [ACTION]{"type":"a"}[/ACTION] B [ACTION]{"type":"b"}[/ACTION] C'
    cleaned, actions = extract_ollama_actions(txt)
    assert len(actions) == 2
    assert actions[0]['type'] == 'a'
    assert actions[1]['type'] == 'b'
    assert '[ACTION]' not in cleaned


def test_extract_empty_string():
    cleaned, actions = extract_ollama_actions('')
    assert cleaned == ''
    assert actions == []


def test_extract_just_action_marker():
    cleaned, actions = extract_ollama_actions('[ACTION]')
    assert '[ACTION]' not in cleaned
    assert actions == []


def test_extract_orphan_nested_json():
    txt = 'Hi.\n\n---\n{"type":"x","meta":{"k":1,"v":[1,2,3]}}'
    cleaned, actions = extract_ollama_actions(txt)
    assert '{"type"' not in cleaned
    assert '---' not in cleaned
    assert len(actions) == 1
    assert actions[0]['meta']['v'] == [1, 2, 3]


# ---------- offline_response priority / dispatch ----------

def test_math_beats_other_branches():
    # "3+5" shouldn't be interpreted as a greeting or day query.
    r = offline_response('3+5')
    assert '8' in r


def test_date_beats_greeting():
    r = offline_response('Welcher Tag ist heute?')
    assert 'Heute ist' in r


def test_unit_beats_default():
    r = offline_response('100 km in meilen')
    assert '62' in r


def test_greeting_with_question():
    r = offline_response('Hallo, wie geht es dir?')
    assert 'Guten' in r or 'Hallo' in r


def test_unknown_query_honest():
    r = offline_response('foobarbaz zxcv plplpl')
    assert any(p in r.lower() for p in ['konnte', 'nicht', 'versuch'])


# ---------- Wikipedia cache ----------

def test_cache_roundtrip(tmp_path, monkeypatch):
    fake_cache = tmp_path / 'cache.json'
    monkeypatch.setattr(rs, '_CACHE_PATH', fake_cache)
    data = {'title': 'Test', 'extract': 'Hello', 'url': 'u', 'lang': 'de', 'disambiguation': False}
    rs._cache_put('de:test', data)
    got = rs._cache_get('de:test')
    assert got == data


def test_cache_expiry(tmp_path, monkeypatch):
    fake_cache = tmp_path / 'cache.json'
    monkeypatch.setattr(rs, '_CACHE_PATH', fake_cache)
    monkeypatch.setattr(rs, '_CACHE_TTL_SECONDS', 60)
    now = [1_000_000]
    monkeypatch.setattr(rs.time, 'time', lambda: now[0])
    rs._cache_put('de:x', {'title': 'X', 'extract': 'x', 'url': '', 'lang': 'de', 'disambiguation': False})
    assert rs._cache_get('de:x') is not None
    now[0] += 61
    assert rs._cache_get('de:x') is None


def test_cache_lru_cap(tmp_path, monkeypatch):
    fake_cache = tmp_path / 'cache.json'
    monkeypatch.setattr(rs, '_CACHE_PATH', fake_cache)
    monkeypatch.setattr(rs, '_CACHE_MAX', 3)
    for i in range(10):
        rs._cache_put(f'de:item{i}', {'title': str(i), 'extract': 'x', 'url': '', 'lang': 'de', 'disambiguation': False})
    loaded = json.loads(fake_cache.read_text())
    assert len(loaded) <= 3


def test_cache_corrupt_file_recovers(tmp_path, monkeypatch):
    fake_cache = tmp_path / 'cache.json'
    fake_cache.write_text('not valid json {{{')
    monkeypatch.setattr(rs, '_CACHE_PATH', fake_cache)
    assert rs._cache_get('any') is None
    rs._cache_put('de:fresh', {'title': 'Fresh', 'extract': 'ok', 'url': '', 'lang': 'de', 'disambiguation': False})
    assert rs._cache_get('de:fresh') is not None


def test_cache_missing_dir(tmp_path, monkeypatch):
    deep = tmp_path / 'nested' / 'nope' / 'cache.json'
    monkeypatch.setattr(rs, '_CACHE_PATH', deep)
    rs._cache_put('de:x', {'title': 't', 'extract': 'x', 'url': '', 'lang': 'de', 'disambiguation': False})
    assert deep.exists()


def test_wikipedia_uses_cache_when_network_down(tmp_path, monkeypatch):
    fake_cache = tmp_path / 'cache.json'
    monkeypatch.setattr(rs, '_CACHE_PATH', fake_cache)
    cached_result = {'title': 'Cached', 'extract': 'from cache', 'url': 'u', 'lang': 'de', 'disambiguation': False}
    rs._cache_put('de:offline-test', cached_result)

    def blow_up(*a, **kw):
        raise Exception('network down')
    monkeypatch.setattr(rs.requests, 'get', blow_up)

    got = rs.wikipedia_summary('offline-test')
    assert got == cached_result


def test_wikipedia_network_failure_returns_none(tmp_path, monkeypatch):
    fake_cache = tmp_path / 'cache.json'
    monkeypatch.setattr(rs, '_CACHE_PATH', fake_cache)

    def blow_up(*a, **kw):
        raise rs.requests.ConnectionError('down')
    monkeypatch.setattr(rs.requests, 'get', blow_up)

    assert rs.wikipedia_summary('NeverCachedEntity') is None


# ---------- Performance ----------

def test_offline_tools_are_fast():
    queries = ['2+2', 'wurzel aus 144', '15% von 200',
               'Welcher Wochentag ist heute?', '100 km in meilen']
    N = 200
    t0 = time.perf_counter()
    for _ in range(N):
        for q in queries:
            offline_tools.try_offline_tool(q)
    elapsed = time.perf_counter() - t0
    avg_us = (elapsed / (N * len(queries))) * 1_000_000
    assert avg_us < 2000, f'too slow: {avg_us:.0f}µs per query'


def test_is_data_query_fast():
    N = 1000
    t0 = time.perf_counter()
    for _ in range(N):
        is_data_query('Was steht heute an?')
        is_data_query('Wer ist Einstein?')
        is_data_query('3+5')
    elapsed = time.perf_counter() - t0
    avg_us = (elapsed / (N * 3)) * 1_000_000
    assert avg_us < 500, f'too slow: {avg_us:.0f}µs'


def test_entity_extraction_fast():
    msg = 'Gib mir Infos zu der Person Albert Einstein und was er gemacht hat'
    N = 1000
    t0 = time.perf_counter()
    for _ in range(N):
        rs.extract_entity(msg)
    elapsed = time.perf_counter() - t0
    avg_us = (elapsed / N) * 1_000_000
    assert avg_us < 1000, f'too slow: {avg_us:.0f}µs'


# ---------- Integration: no false positive under real school-life content ----------

@pytest.mark.parametrize('msg', [
    'Mein Lieblingsbuch ist "Der Steppenwolf" von Hermann Hesse.',
    'Heute war Sport, Mathe und Deutsch.',
    'Ich habe Hunger.',
    'Das Buch war langweilig, aber die Figur interessant.',
    'Morgen regnet es wahrscheinlich.',
])
def test_casual_chat_not_misrouted(msg):
    # Shouldn't trigger math/date/unit/research false positives.
    assert offline_tools.try_offline_tool(msg) is None, f'casual chat matched offline tool: {msg!r}'
    assert not rs.wants_research(msg), f'casual chat matched research: {msg!r}'
