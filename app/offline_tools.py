from __future__ import annotations

import ast
import math
import re
from datetime import datetime, timedelta
from typing import Optional

DAY_NAMES_DE = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag']
MONTH_NAMES_DE = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
                  'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember']

_NUMBER_WORDS_DE = {
    'null': 0, 'eins': 1, 'eine': 1, 'einen': 1, 'zwei': 2, 'drei': 3, 'vier': 4,
    'fünf': 5, 'sechs': 6, 'sieben': 7, 'acht': 8, 'neun': 9, 'zehn': 10,
    'elf': 11, 'zwölf': 12, 'zwanzig': 20, 'dreißig': 30, 'hundert': 100, 'tausend': 1000,
}


def _parse_num(s: str) -> Optional[float]:
    s = s.strip().lower().replace(',', '.').replace(' ', '')
    if s in _NUMBER_WORDS_DE:
        return float(_NUMBER_WORDS_DE[s])
    try:
        return float(s)
    except ValueError:
        return None


def _fmt_num(n: float) -> str:
    if abs(n - round(n)) < 1e-9:
        return str(int(round(n)))
    s = f'{n:.6f}'.rstrip('0').rstrip('.')
    return s.replace('.', ',')


# ---- Math ----

_SAFE_MATH = re.compile(r'^[\d\s+\-*/().,%^√πesqrtinlogcosabc\u00d7\u00f7]+$')
_MATH_TRIGGERS = re.compile(
    r'^(?:(?:berechne|was\s+ist|wie\s+viel\s+ist|wieviel\s+ist|rechne|löse)\s+)?'
    r'(.+?)'
    r'(?:\s*=\s*\?)?$',
    re.IGNORECASE,
)


_CALC_PREFIXES = re.compile(
    r'^\s*(?:(?:bitte\s+)?(?:ich\s+)?(?:berechne|rechne|löse|loese|was\s+ist|was\s+ergibt|wie\s*viel\s+(?:ist|sind|ergibt)|wieviel\s+(?:ist|sind|ergibt))\s+)+',
    re.IGNORECASE,
)
_CALC_STRIP_TRAILING = re.compile(r'[^\w\d+\-*/().,%^\s√]', re.UNICODE)

_MAX_POW_EXPONENT = 1000
_MAX_POW_BASE = 10 ** 18


def _safe_eval_arith(expr: str):
    """Evaluate a bare arithmetic expression without eval().

    Supports + - * / % ** and parentheses over numeric literals. Exponentiation
    is bounded so a short input like '9**9**9' cannot trigger a big-integer DoS.
    """
    def _node(n):
        if isinstance(n, ast.Expression):
            return _node(n.body)
        if isinstance(n, ast.Constant) and isinstance(n.value, (int, float)) and not isinstance(n.value, bool):
            return n.value
        if isinstance(n, ast.UnaryOp) and isinstance(n.op, (ast.UAdd, ast.USub)):
            v = _node(n.operand)
            return +v if isinstance(n.op, ast.UAdd) else -v
        if isinstance(n, ast.BinOp):
            left = _node(n.left)
            right = _node(n.right)
            op = n.op
            if isinstance(op, ast.Add):
                return left + right
            if isinstance(op, ast.Sub):
                return left - right
            if isinstance(op, ast.Mult):
                return left * right
            if isinstance(op, ast.Div):
                return left / right
            if isinstance(op, ast.Mod):
                return left % right
            if isinstance(op, ast.Pow):
                if abs(right) > _MAX_POW_EXPONENT or abs(left) > _MAX_POW_BASE:
                    raise ValueError('exponent out of bounds')
                return left ** right
        raise ValueError('unsupported expression')

    return _node(ast.parse(expr, mode='eval'))


def try_calc(message: str) -> Optional[str]:
    raw = message.strip().rstrip('?.!').strip()
    # Drop decorative noise (emoji, arrows, …) that can't belong to arithmetic.
    raw = _CALC_STRIP_TRAILING.sub(' ', raw).strip()
    m = _CALC_PREFIXES.sub('', raw).strip()
    if not m:
        return None

    # Percentage: "15% von 200", "wie viel sind 15 prozent von 200"
    pct = re.match(r'(\d+(?:[.,]\d+)?)\s*(?:%|prozent)\s+von\s+(\d+(?:[.,]\d+)?)', m, re.IGNORECASE)
    if pct:
        a = float(pct.group(1).replace(',', '.'))
        b = float(pct.group(2).replace(',', '.'))
        return f'{_fmt_num(a)} % von {_fmt_num(b)} = **{_fmt_num(a * b / 100)}**'

    # Square root: "wurzel aus 16", "sqrt(144)", "sqrt 25"
    root = re.match(r'(?:die\s+)?wurzel\s+(?:aus\s+)?(\d+(?:[.,]\d+)?)', m, re.IGNORECASE)
    if not root:
        root = re.match(r'sqrt\s*\(?\s*(\d+(?:[.,]\d+)?)\s*\)?', m, re.IGNORECASE)
    if root:
        n = float(root.group(1).replace(',', '.'))
        if n < 0:
            return None
        return f'√{_fmt_num(n)} = **{_fmt_num(math.sqrt(n))}**'

    # "2 mal 8", "7 plus 3", "20 minus 5", "50 durch 4", "3 hoch 4"
    word_op = re.match(r'(\-?\d+(?:[.,]\d+)?)\s+(mal|plus|minus|durch|geteilt durch|hoch)\s+(\-?\d+(?:[.,]\d+)?)', m, re.IGNORECASE)
    if word_op:
        a = float(word_op.group(1).replace(',', '.'))
        b = float(word_op.group(3).replace(',', '.'))
        op = word_op.group(2).lower()
        try:
            if op == 'mal':
                res = a * b
            elif op == 'plus':
                res = a + b
            elif op == 'minus':
                res = a - b
            elif op in ('durch', 'geteilt durch'):
                if b == 0:
                    return 'Teilen durch 0 ist nicht definiert.'
                res = a / b
            elif op == 'hoch':
                res = a ** b
            else:
                return None
            return f'{_fmt_num(a)} {op} {_fmt_num(b)} = **{_fmt_num(res)}**'
        except Exception:
            return None

    # Bare arithmetic expression: "2+2", "3*(4+5)", "2^10"
    expr_match = re.match(r'^([\d\s+\-*/().,%^]+)$', m)
    if expr_match:
        expr = expr_match.group(1).replace(' ', '').replace(',', '.').replace('^', '**')
        if not re.fullmatch(r'[\d+\-*/().%]+', expr.replace('**', '*')):
            return None
        if len(expr) < 2 or '+' not in expr and '-' not in expr and '*' not in expr and '/' not in expr and '%' not in expr and '**' not in expr:
            return None
        try:
            result = _safe_eval_arith(expr)
            if isinstance(result, (int, float)):
                pretty_expr = expr.replace('**', '^').replace('*', '·').replace('/', ' ÷ ').replace('+', ' + ').replace('-', ' − ')
                return f'{pretty_expr.strip()} = **{_fmt_num(float(result))}**'
        except Exception:
            return None
    return None


# ---- Date math ----

_DATE_DE = re.compile(r'(\d{1,2})\.\s*(\d{1,2})\.\s*(\d{2,4})')
_DATE_WORD = re.compile(r'(\d{1,2})\.\s*(' + '|'.join(MONTH_NAMES_DE) + r')(?:\s+(\d{2,4}))?', re.IGNORECASE)


def _parse_date_de(s: str, now: Optional[datetime] = None) -> Optional[datetime]:
    now = now or datetime.now()
    m = _DATE_DE.search(s)
    if m:
        d, mo, y = int(m.group(1)), int(m.group(2)), int(m.group(3))
        if y < 100:
            y += 2000
        try:
            return datetime(y, mo, d)
        except ValueError:
            return None
    m = _DATE_WORD.search(s)
    if m:
        d = int(m.group(1))
        mo = MONTH_NAMES_DE.index(m.group(2).capitalize()) + 1
        y = int(m.group(3)) if m.group(3) else now.year
        if y < 100:
            y += 2000
        try:
            dt = datetime(y, mo, d)
            if not m.group(3) and dt < now:
                dt = dt.replace(year=y + 1)
            return dt
        except ValueError:
            return None
    return None


def try_date_math(message: str) -> Optional[str]:
    m = message.strip().lower().rstrip('?.!').strip()
    now = datetime.now()

    if re.match(r'^(?:welcher|was für ein)\s+(wochen)?tag\s+ist\s+heute\b', m):
        return f'Heute ist **{DAY_NAMES_DE[now.weekday()]}**, der {now.strftime("%d.%m.%Y")}.'
    if re.match(r'^(?:welcher|was für ein)\s+(wochen)?tag\s+ist\s+morgen\b', m):
        t = now + timedelta(days=1)
        return f'Morgen ist **{DAY_NAMES_DE[t.weekday()]}**, der {t.strftime("%d.%m.%Y")}.'

    # "welcher wochentag / tag der woche ist der 24.12.2026?"
    wt = re.search(r'welcher\s+(?:wochen)?tag(?:\s+der\s+woche)?\s+ist\s+(?:der|am)?\s*(.+)', m)
    if wt:
        dt = _parse_date_de(wt.group(1), now)
        if dt:
            return f'Der {dt.strftime("%d.%m.%Y")} ist ein **{DAY_NAMES_DE[dt.weekday()]}**.'

    # "wie viele tage bis zum 01.06.2026"
    days_to = re.search(r'wie\s*viele\s+tage\s+(?:bis|noch\s+bis|bis\s+zum?)\s+(.+)', m)
    if days_to:
        dt = _parse_date_de(days_to.group(1), now)
        if dt:
            diff = (dt.date() - now.date()).days
            if diff == 0:
                return 'Das ist heute.'
            if diff < 0:
                return f'Das Datum ({dt.strftime("%d.%m.%Y")}) liegt **{-diff} Tage** zurück.'
            return f'Bis zum {dt.strftime("%d.%m.%Y")} sind es noch **{diff} Tage**.'

    # "in 3 wochen", "in 10 tagen"
    in_x = re.search(r'(?:was für ein|welcher)\s+(?:wochen)?tag\s+ist\s+in\s+(\d+)\s+(tag|tage|woche|wochen|monat|monate)', m)
    if in_x:
        n = int(in_x.group(1))
        unit = in_x.group(2)
        if 'tag' in unit:
            dt = now + timedelta(days=n)
        elif 'woche' in unit:
            dt = now + timedelta(weeks=n)
        else:
            mo = now.month + n
            y = now.year + (mo - 1) // 12
            mo = ((mo - 1) % 12) + 1
            try:
                dt = now.replace(year=y, month=mo)
            except ValueError:
                dt = now.replace(year=y, month=mo, day=1)
        return f'In {n} {unit} ist **{DAY_NAMES_DE[dt.weekday()]}**, der {dt.strftime("%d.%m.%Y")}.'

    # "wie spät", "Uhrzeit?", "welche uhrzeit haben wir", "sag mir die uhrzeit"
    if re.search(r'wie\s+sp[äa]t(\s+ist(\s+es)?)?|(?:was\s+ist\s+die|welche)\s+uhrzeit|^uhrzeit$|uhrzeit\s+bitte|sag\s+mir\s+die\s+uhrzeit', m):
        return f'Es ist **{now.strftime("%H:%M")}** Uhr.'

    return None


# ---- Unit conversion ----

_UNIT_ALIASES = {
    'km': 'km',
    'kilometer': 'km', 'kilometers': 'km',
    'meile': 'mi', 'meilen': 'mi', 'mi': 'mi', 'mile': 'mi', 'miles': 'mi',
    'm': 'm', 'meter': 'm', 'meters': 'm',
    'ft': 'ft', 'fuß': 'ft', 'fuss': 'ft', 'foot': 'ft', 'feet': 'ft',
    'kg': 'kg', 'kilogramm': 'kg', 'kilogram': 'kg', 'kilograms': 'kg',
    'pfund': 'lb', 'lb': 'lb', 'lbs': 'lb', 'pound': 'lb', 'pounds': 'lb',
    'l': 'l', 'liter': 'l', 'litre': 'l', 'litres': 'l', 'liters': 'l',
    'gallon': 'gal', 'gallonen': 'gal', 'gallons': 'gal', 'gal': 'gal',
}

_UNIT_CONVERSIONS = {
    ('km', 'mi'): (1 / 1.609344, 'Meilen'),
    ('mi', 'km'): (1.609344, 'km'),
    ('m',  'ft'): (3.28084, 'Fuß'),
    ('ft', 'm'):  (0.3048, 'm'),
    ('m',  'km'): (0.001, 'km'),
    ('km', 'm'):  (1000.0, 'm'),
    ('kg', 'lb'): (2.20462, 'Pfund'),
    ('lb', 'kg'): (0.453592, 'kg'),
    ('l',  'gal'): (0.264172, 'Gallonen'),
    ('gal', 'l'):  (3.78541, 'l'),
}


def try_unit_convert(message: str) -> Optional[str]:
    m = message.strip().lower().rstrip('?.!').strip()

    temp = re.match(r'(\-?\d+(?:[.,]\d+)?)\s*(?:grad\s+)?(celsius|c|fahrenheit|f|kelvin|k)\s+(?:in|nach|zu|to)\s+(?:grad\s+)?(celsius|c|fahrenheit|f|kelvin|k)', m, re.IGNORECASE)
    if temp:
        val = float(temp.group(1).replace(',', '.'))
        src = temp.group(2).lower()[0]
        dst = temp.group(3).lower()[0]
        if src == 'c' and dst == 'f':
            res = val * 9 / 5 + 32
        elif src == 'f' and dst == 'c':
            res = (val - 32) * 5 / 9
        elif src == 'c' and dst == 'k':
            res = val + 273.15
        elif src == 'k' and dst == 'c':
            res = val - 273.15
        elif src == 'f' and dst == 'k':
            res = (val - 32) * 5 / 9 + 273.15
        elif src == 'k' and dst == 'f':
            res = (val - 273.15) * 9 / 5 + 32
        else:
            res = val
        unit_long = {'c': '°C', 'f': '°F', 'k': 'K'}
        return f'{_fmt_num(val)} {unit_long[src]} = **{_fmt_num(res)} {unit_long[dst]}**'

    conv = re.match(r'(\-?\d+(?:[.,]\d+)?)\s*([a-zäöüß]+)\s+(?:in|nach|zu|to)\s+([a-zäöüß]+)', m, re.IGNORECASE)
    if conv:
        val = float(conv.group(1).replace(',', '.'))
        src_raw = conv.group(2).lower()
        dst_raw = conv.group(3).lower()
        src = _UNIT_ALIASES.get(src_raw)
        dst = _UNIT_ALIASES.get(dst_raw)
        if src and dst:
            key = (src, dst)
            if key in _UNIT_CONVERSIONS:
                factor, label = _UNIT_CONVERSIONS[key]
                return f'{_fmt_num(val)} {src_raw} = **{_fmt_num(val * factor)} {label}**'

    return None


# ---- Top-level dispatcher ----

def try_offline_tool(message: str) -> Optional[str]:
    if not message or len(message) > 200:
        return None
    for fn in (try_date_math, try_unit_convert, try_calc):
        try:
            result = fn(message)
            if result:
                return result
        except Exception:
            continue
    return None
