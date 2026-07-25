import 'dart:math' as math;

const _dayNamesDe = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];
const _monthNamesDe = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];

String _fmtNum(double n) {
  if ((n - n.roundToDouble()).abs() < 1e-9) return n.round().toString();
  var s = n.toStringAsFixed(6);
  while (s.endsWith('0')) {
    s = s.substring(0, s.length - 1);
  }
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  return s.replaceAll('.', ',');
}

final _calcPrefixes = RegExp(
  r'^\s*(?:(?:bitte\s+)?(?:ich\s+)?(?:berechne|rechne|löse|loese|was\s+ist|was\s+ergibt|wie\s*viel\s+(?:ist|sind|ergibt)|wieviel\s+(?:ist|sind|ergibt))\s+)+',
  caseSensitive: false,
);
final _calcStripDecor = RegExp(r'[^\w\d+\-*/().,%^\s√]', unicode: true);

String? _evalArith(String expr) {
  expr = expr.replaceAll(' ', '').replaceAll(',', '.').replaceAll('^', '**');
  if (!RegExp(r'^[\d+\-*/().%]+$').hasMatch(expr.replaceAll('**', '*'))) return null;
  if (expr.length < 2) return null;
  try {
    return _evalSafe(expr).toString();
  } catch (_) {
    return null;
  }
}

// Tiny shunting-yard evaluator — supports + - * / ** ( ) and a single leading minus.
double _evalSafe(String expr) {
  final tokens = <String>[];
  var i = 0;
  while (i < expr.length) {
    final c = expr[i];
    if (RegExp(r'[\d.]').hasMatch(c)) {
      final start = i;
      while (i < expr.length && RegExp(r'[\d.]').hasMatch(expr[i])) {
        i++;
      }
      tokens.add(expr.substring(start, i));
      continue;
    }
    if (c == '*' && i + 1 < expr.length && expr[i + 1] == '*') {
      tokens.add('**');
      i += 2;
      continue;
    }
    if ('+-*/()'.contains(c)) {
      // Handle leading unary minus / after open paren
      if (c == '-' && (tokens.isEmpty || tokens.last == '(' || RegExp(r'^[-+*/]$|^\*\*$').hasMatch(tokens.last))) {
        tokens.add('0');
      }
      tokens.add(c);
      i++;
      continue;
    }
    throw const FormatException('bad char');
  }
  // Convert to RPN (shunting-yard)
  const prec = {'+': 1, '-': 1, '*': 2, '/': 2, '**': 3};
  final output = <String>[];
  final opStack = <String>[];
  for (final t in tokens) {
    if (RegExp(r'^\d').hasMatch(t)) {
      output.add(t);
    } else if (t == '(') {
      opStack.add(t);
    } else if (t == ')') {
      while (opStack.isNotEmpty && opStack.last != '(') {
        output.add(opStack.removeLast());
      }
      if (opStack.isEmpty) throw const FormatException('mismatched paren');
      opStack.removeLast();
    } else {
      while (opStack.isNotEmpty && opStack.last != '(' &&
             ((prec[opStack.last] ?? 0) > (prec[t] ?? 0) ||
              ((prec[opStack.last] ?? 0) == (prec[t] ?? 0) && t != '**'))) {
        output.add(opStack.removeLast());
      }
      opStack.add(t);
    }
  }
  while (opStack.isNotEmpty) {
    final op = opStack.removeLast();
    if (op == '(') throw const FormatException('mismatched paren');
    output.add(op);
  }
  // Eval RPN
  final stack = <double>[];
  for (final t in output) {
    if (RegExp(r'^\d').hasMatch(t)) {
      stack.add(double.parse(t));
    } else {
      if (stack.length < 2) throw const FormatException('underflow');
      final b = stack.removeLast();
      final a = stack.removeLast();
      switch (t) {
        case '+': stack.add(a + b); break;
        case '-': stack.add(a - b); break;
        case '*': stack.add(a * b); break;
        case '/':
          if (b == 0) throw const FormatException('div0');
          stack.add(a / b);
          break;
        case '**': stack.add(math.pow(a, b).toDouble()); break;
        default: throw const FormatException('unknown op');
      }
    }
  }
  if (stack.length != 1) throw const FormatException('incomplete');
  return stack.single;
}

String? tryCalc(String message) {
  var raw = message.trim().replaceAll(RegExp(r'[?.!]+$'), '').trim();
  raw = raw.replaceAll(_calcStripDecor, ' ').trim();
  final m = _calcPrefixes.allMatches(raw).isEmpty ? raw : raw.replaceFirst(_calcPrefixes, '').trim();
  if (m.isEmpty) return null;

  // Percentage
  final pct = RegExp(r'^(\d+(?:[.,]\d+)?)\s*(?:%|prozent)\s+von\s+(\d+(?:[.,]\d+)?)', caseSensitive: false).firstMatch(m);
  if (pct != null) {
    final a = double.parse(pct.group(1)!.replaceAll(',', '.'));
    final b = double.parse(pct.group(2)!.replaceAll(',', '.'));
    return '${_fmtNum(a)} % von ${_fmtNum(b)} = **${_fmtNum(a * b / 100)}**';
  }

  // sqrt
  var root = RegExp(r'^(?:die\s+)?wurzel\s+(?:aus\s+)?(\d+(?:[.,]\d+)?)', caseSensitive: false).firstMatch(m);
  root ??= RegExp(r'^sqrt\s*\(?\s*(\d+(?:[.,]\d+)?)\s*\)?', caseSensitive: false).firstMatch(m);
  if (root != null) {
    final n = double.parse(root.group(1)!.replaceAll(',', '.'));
    if (n < 0) return null;
    return '√${_fmtNum(n)} = **${_fmtNum(math.sqrt(n))}**';
  }

  // Word operators
  final word = RegExp(r'^(\-?\d+(?:[.,]\d+)?)\s+(mal|plus|minus|durch|geteilt durch|hoch)\s+(\-?\d+(?:[.,]\d+)?)', caseSensitive: false).firstMatch(m);
  if (word != null) {
    final a = double.parse(word.group(1)!.replaceAll(',', '.'));
    final b = double.parse(word.group(3)!.replaceAll(',', '.'));
    final op = word.group(2)!.toLowerCase();
    double res;
    switch (op) {
      case 'mal': res = a * b; break;
      case 'plus': res = a + b; break;
      case 'minus': res = a - b; break;
      case 'durch':
      case 'geteilt durch':
        if (b == 0) return 'Teilen durch 0 ist nicht definiert.';
        res = a / b;
        break;
      case 'hoch': res = math.pow(a, b).toDouble(); break;
      default: return null;
    }
    return '${_fmtNum(a)} $op ${_fmtNum(b)} = **${_fmtNum(res)}**';
  }

  // Bare arithmetic expression
  if (RegExp(r'^[\d\s+\-*/().,%^]+$').hasMatch(m)) {
    final hasOp = RegExp(r'[+\-*/^%]').hasMatch(m);
    if (hasOp && m.length >= 2) {
      final result = _evalArith(m);
      if (result != null) {
        final val = double.tryParse(result);
        if (val != null) {
          final pretty = m.replaceAll('**', '^').replaceAll('*', '·').replaceAll('/', ' ÷ ');
          return '$pretty = **${_fmtNum(val)}**';
        }
      }
    }
  }
  return null;
}

// ---- Date math ----

DateTime? _parseDateDe(String s, DateTime now) {
  var m = RegExp(r'(\d{1,2})\.\s*(\d{1,2})\.\s*(\d{2,4})').firstMatch(s);
  if (m != null) {
    var d = int.parse(m.group(1)!);
    var mo = int.parse(m.group(2)!);
    var y = int.parse(m.group(3)!);
    if (y < 100) y += 2000;
    try {
      final dt = DateTime(y, mo, d);
      if (dt.month != mo || dt.day != d) return null;
      return dt;
    } catch (_) {
      return null;
    }
  }
  final words = _monthNamesDe.map((n) => n.toLowerCase()).join('|');
  m = RegExp(r'(\d{1,2})\.\s*(' + words + r')(?:\s+(\d{2,4}))?', caseSensitive: false).firstMatch(s);
  if (m != null) {
    final d = int.parse(m.group(1)!);
    final mo = _monthNamesDe.indexWhere((n) => n.toLowerCase() == m!.group(2)!.toLowerCase()) + 1;
    var y = m.group(3) != null ? int.parse(m.group(3)!) : now.year;
    if (y < 100) y += 2000;
    try {
      var dt = DateTime(y, mo, d);
      if (dt.month != mo || dt.day != d) return null;
      if (m.group(3) == null && dt.isBefore(DateTime(now.year, now.month, now.day))) {
        dt = DateTime(y + 1, mo, d);
      }
      return dt;
    } catch (_) {
      return null;
    }
  }
  return null;
}

String _dayName(DateTime dt) => _dayNamesDe[dt.weekday - 1];

String _fmtDateDe(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

String? tryDateMath(String message, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final m = message.trim().toLowerCase().replaceAll(RegExp(r'[?.!]+$'), '').trim();

  if (RegExp(r'^(?:welcher|was für ein)\s+(wochen)?tag\s+ist\s+heute').hasMatch(m)) {
    return 'Heute ist **${_dayName(today)}**, der ${_fmtDateDe(today)}.';
  }
  if (RegExp(r'^(?:welcher|was für ein)\s+(wochen)?tag\s+ist\s+morgen').hasMatch(m)) {
    final t = today.add(const Duration(days: 1));
    return 'Morgen ist **${_dayName(t)}**, der ${_fmtDateDe(t)}.';
  }
  final wt = RegExp(r'welcher\s+(?:wochen)?tag(?:\s+der\s+woche)?\s+ist\s+(?:der|am)?\s*(.+)').firstMatch(m);
  if (wt != null) {
    final dt = _parseDateDe(wt.group(1)!, n);
    if (dt != null) return 'Der ${_fmtDateDe(dt)} ist ein **${_dayName(dt)}**.';
  }
  final bis = RegExp(r'wie\s*viele\s+tage\s+(?:bis|noch\s+bis|bis\s+zum?)\s+(.+)').firstMatch(m);
  if (bis != null) {
    final dt = _parseDateDe(bis.group(1)!, n);
    if (dt != null) {
      final diff = dt.difference(today).inDays;
      if (diff == 0) return 'Das ist heute.';
      if (diff < 0) return 'Das Datum (${_fmtDateDe(dt)}) liegt **${-diff} Tage** zurück.';
      return 'Bis zum ${_fmtDateDe(dt)} sind es noch **$diff Tage**.';
    }
  }
  final inX = RegExp(r'(?:was für ein|welcher)\s+(?:wochen)?tag\s+ist\s+in\s+(\d+)\s+(tag|tage|woche|wochen|monat|monate)').firstMatch(m);
  if (inX != null) {
    final count = int.parse(inX.group(1)!);
    final unit = inX.group(2)!;
    DateTime dt;
    if (unit.contains('tag')) {
      dt = today.add(Duration(days: count));
    } else if (unit.contains('woche')) {
      dt = today.add(Duration(days: count * 7));
    } else {
      final totalMonths = today.month + count;
      final y = today.year + ((totalMonths - 1) ~/ 12);
      final mo = ((totalMonths - 1) % 12) + 1;
      dt = DateTime(y, mo, today.day);
    }
    return 'In $count $unit ist **${_dayName(dt)}**, der ${_fmtDateDe(dt)}.';
  }
  if (RegExp(r'wie\s+sp[äa]t(\s+ist(\s+es)?)?|(?:was\s+ist\s+die|welche)\s+uhrzeit|^uhrzeit$|uhrzeit\s+bitte|sag\s+mir\s+die\s+uhrzeit').hasMatch(m)) {
    return 'Es ist **${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}** Uhr.';
  }
  return null;
}

// ---- Unit conversion ----

const _unitAliases = {
  'km': 'km',
  'kilometer': 'km', 'kilometers': 'km',
  'meile': 'mi', 'meilen': 'mi', 'mi': 'mi', 'mile': 'mi', 'miles': 'mi',
  'm': 'm', 'meter': 'm', 'meters': 'm',
  'ft': 'ft', 'fuß': 'ft', 'fuss': 'ft', 'foot': 'ft', 'feet': 'ft',
  'kg': 'kg', 'kilogramm': 'kg', 'kilogram': 'kg', 'kilograms': 'kg',
  'pfund': 'lb', 'lb': 'lb', 'lbs': 'lb', 'pound': 'lb', 'pounds': 'lb',
  'l': 'l', 'liter': 'l', 'litre': 'l', 'litres': 'l', 'liters': 'l',
  'gallon': 'gal', 'gallonen': 'gal', 'gallons': 'gal', 'gal': 'gal',
};

const _unitConversions = {
  'km>mi': [1 / 1.609344, 'Meilen'],
  'mi>km': [1.609344, 'km'],
  'm>ft':  [3.28084, 'Fuß'],
  'ft>m':  [0.3048, 'm'],
  'm>km':  [0.001, 'km'],
  'km>m':  [1000.0, 'm'],
  'kg>lb': [2.20462, 'Pfund'],
  'lb>kg': [0.453592, 'kg'],
  'l>gal': [0.264172, 'Gallonen'],
  'gal>l': [3.78541, 'l'],
};

String? tryUnitConvert(String message) {
  final m = message.trim().toLowerCase().replaceAll(RegExp(r'[?.!]+$'), '').trim();

  final temp = RegExp(
    r'^(\-?\d+(?:[.,]\d+)?)\s*(?:grad\s+)?(celsius|c|fahrenheit|f|kelvin|k)\s+(?:in|nach|zu|to)\s+(?:grad\s+)?(celsius|c|fahrenheit|f|kelvin|k)',
    caseSensitive: false,
  ).firstMatch(m);
  if (temp != null) {
    final val = double.parse(temp.group(1)!.replaceAll(',', '.'));
    final src = temp.group(2)!.toLowerCase()[0];
    final dst = temp.group(3)!.toLowerCase()[0];
    double res;
    if (src == 'c' && dst == 'f') {
      res = val * 9 / 5 + 32;
    } else if (src == 'f' && dst == 'c') {
      res = (val - 32) * 5 / 9;
    } else if (src == 'c' && dst == 'k') {
      res = val + 273.15;
    } else if (src == 'k' && dst == 'c') {
      res = val - 273.15;
    } else if (src == 'f' && dst == 'k') {
      res = (val - 32) * 5 / 9 + 273.15;
    } else if (src == 'k' && dst == 'f') {
      res = (val - 273.15) * 9 / 5 + 32;
    } else {
      res = val;
    }
    const labels = {'c': '°C', 'f': '°F', 'k': 'K'};
    return '${_fmtNum(val)} ${labels[src]} = **${_fmtNum(res)} ${labels[dst]}**';
  }

  final conv = RegExp(
    r'^(\-?\d+(?:[.,]\d+)?)\s*([a-zäöüß]+)\s+(?:in|nach|zu|to)\s+([a-zäöüß]+)',
    caseSensitive: false,
  ).firstMatch(m);
  if (conv != null) {
    final val = double.parse(conv.group(1)!.replaceAll(',', '.'));
    final srcRaw = conv.group(2)!.toLowerCase();
    final dstRaw = conv.group(3)!.toLowerCase();
    final src = _unitAliases[srcRaw];
    final dst = _unitAliases[dstRaw];
    if (src != null && dst != null) {
      final entry = _unitConversions['$src>$dst'];
      if (entry != null) {
        final factor = entry[0] as double;
        final label = entry[1] as String;
        return '${_fmtNum(val)} $srcRaw = **${_fmtNum(val * factor)} $label**';
      }
    }
  }
  return null;
}

String? tryOfflineTool(String message) {
  if (message.isEmpty || message.length > 300) return null;
  for (final fn in <String? Function(String)>[tryDateMath, tryUnitConvert, tryCalc]) {
    try {
      final out = fn(message);
      if (out != null) return out;
    } catch (_) {
      continue;
    }
  }
  return null;
}
