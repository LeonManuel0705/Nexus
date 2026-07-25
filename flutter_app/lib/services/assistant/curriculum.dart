import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Offline curriculum lookup — formulas, literary epochs, works, and per-grade topics.
///
/// Data lives in three JSON files under `assets/curriculum/` and is loaded once
/// from the Flutter bundle on first use.
class CurriculumService {
  CurriculumService._();
  static final CurriculumService instance = CurriculumService._();

  bool _loaded = false;
  final Map<String, Map<String, dynamic>> _formelnIndex = {};
  final Map<String, Map<String, dynamic>> _epochenIndex = {};
  final Map<String, Map<String, dynamic>> _werkeIndex = {};
  final Map<String, Map<String, dynamic>> _conceptsIndex = {};
  Map<String, dynamic> _topicsData = {};

  static final _neg = RegExp(r'(?<!\w)(?:nicht|kein(?:e|er|en|em|es)?|niemals|ohne)(?!\w)', caseSensitive: false);
  static final _questionStarter = RegExp(r'^\s*(?:wer|was|wann|wo|wie|warum|welch|gib|zeig|nenne|sage)\b', caseSensitive: false);
  static final _articleStrip = RegExp(r'^(?:der|die|das|dem|den|des|ein|eine|einen|einem|einer|eines)\s+', caseSensitive: false);

  Future<void> ensureLoaded() async {
    if (_loaded) return;

    Future<dynamic> load(String path) async {
      final txt = await rootBundle.loadString(path);
      return jsonDecode(txt);
    }

    try {
      final formeln = await load('assets/curriculum/formeln.json') as Map<String, dynamic>;
      for (final raw in (formeln['formulas'] as List)) {
        final e = Map<String, dynamic>.from(raw as Map);
        final names = [e['name'] as String, ...((e['aliases'] as List?) ?? []).cast<String>()];
        for (final n in names) {
          final k = _normalize(n);
          if (k.isNotEmpty) _formelnIndex.putIfAbsent(k, () => e);
        }
      }
    } catch (_) {}

    try {
      final epo = await load('assets/curriculum/epochen.json') as Map<String, dynamic>;
      for (final raw in (epo['epochen'] as List)) {
        final e = Map<String, dynamic>.from(raw as Map);
        final names = [e['name'] as String, ...((e['aliases'] as List?) ?? []).cast<String>()];
        for (final n in names) {
          final k = _normalize(n);
          if (k.isNotEmpty) _epochenIndex.putIfAbsent(k, () => e);
        }
      }
      for (final raw in (epo['werke'] as List)) {
        final w = Map<String, dynamic>.from(raw as Map);
        final titles = [w['titel'] as String, ...((w['kurztitel'] as List?) ?? []).cast<String>()];
        for (final t in titles) {
          final k = _normalize(t);
          if (k.isNotEmpty) _werkeIndex.putIfAbsent(k, () => w);
        }
      }
    } catch (_) {}

    try {
      _topicsData = await load('assets/curriculum/topics.json') as Map<String, dynamic>;
    } catch (_) {}

    try {
      final concepts = await load('assets/curriculum/concepts.json') as Map<String, dynamic>;
      for (final raw in (concepts['concepts'] as List)) {
        final c = Map<String, dynamic>.from(raw as Map);
        final names = [c['name'] as String, ...((c['aliases'] as List?) ?? []).cast<String>()];
        for (final n in names) {
          final k = _normalize(n);
          if (k.isNotEmpty) _conceptsIndex.putIfAbsent(k, () => c);
        }
      }
    } catch (_) {}

    _loaded = true;
  }

  static String _normalize(String s) {
    var t = s.trim().toLowerCase()
        .replaceAll('ä', 'ae').replaceAll('ö', 'oe').replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss')
        .replaceAll('–', '-').replaceAll('—', '-')
        .replaceAll('„', '"').replaceAll('"', '"').replaceAll('"', '"');
    t = t.replaceAll(RegExp(r'[^a-z0-9\s\-]'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  bool _isNegated(String norm) {
    if (_questionStarter.hasMatch(norm)) return false;
    return _neg.hasMatch(norm);
  }

  Map<String, dynamic>? _findFormel(String queryNorm) {
    if (queryNorm.isEmpty) return null;
    var q = queryNorm.replaceFirst(_articleStrip, '').trim();
    if (_formelnIndex.containsKey(q)) return _formelnIndex[q];
    Map<String, dynamic>? best;
    var bestLen = 0;
    for (final entry in _formelnIndex.entries) {
      final k = entry.key;
      if (k.length < 4) continue;
      if (k == q || k.contains(q) || q.contains(k)) {
        if (k.length > bestLen) {
          best = entry.value;
          bestLen = k.length;
        }
      }
    }
    return best;
  }

  String _formatFormula(Map<String, dynamic> f) {
    final lines = <String>['**${f["name"]}**', '\$\$${f["formula"]}\$\$'];
    if ((f['description'] ?? '').toString().isNotEmpty) lines.add(f['description']);
    if ((f['example'] ?? '').toString().isNotEmpty) lines.add('*Beispiel:* ${f["example"]}');
    return lines.join('\n\n');
  }

  String _formatEpoche(Map<String, dynamic> e) {
    final buf = StringBuffer('**${e["name"]}** (${e["zeitraum"] ?? ""})\n');
    final merkmale = (e['merkmale'] as List?)?.cast<String>() ?? const [];
    if (merkmale.isNotEmpty) {
      buf.writeln('**Merkmale:**');
      for (final m in merkmale) {
        buf.writeln('  • $m');
      }
    }
    final autoren = (e['autoren'] as List?)?.cast<String>() ?? const [];
    if (autoren.isNotEmpty) buf.writeln('**Wichtige Autoren:** ${autoren.join(", ")}');
    final werke = (e['werke'] as List?)?.cast<String>() ?? const [];
    if (werke.isNotEmpty) {
      buf.writeln('**Bekannte Werke:**');
      for (final w in werke) {
        buf.writeln('  • $w');
      }
    }
    return buf.toString().trimRight();
  }

  String _formatWerk(Map<String, dynamic> w) {
    final buf = StringBuffer('**${w["titel"]}** — ${w["autor"] ?? ""}\n');
    final meta = <String>[
      if ((w['jahr'] ?? '').toString().isNotEmpty) w['jahr'],
      if ((w['gattung'] ?? '').toString().isNotEmpty) w['gattung'],
      if ((w['epoche'] ?? '').toString().isNotEmpty) w['epoche'],
    ];
    if (meta.isNotEmpty) buf.writeln('*${meta.join(" · ")}*');
    if ((w['kurzinfo'] ?? '').toString().isNotEmpty) {
      buf.writeln();
      buf.writeln(w['kurzinfo']);
    }
    return buf.toString().trimRight();
  }

  String? tryFormula(String message) {
    var raw = message.trim();
    if (raw.isEmpty) return null;
    if (raw.length > 400) raw = raw.substring(0, 400);
    final norm = _normalize(raw);
    if (_isNegated(norm)) return null;

    const patterns = [
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
    ];
    for (final pat in patterns) {
      final m = RegExp(pat, caseSensitive: false).firstMatch(norm);
      if (m != null) {
        final entry = _findFormel(_normalize(m.group(1)!));
        if (entry != null) return _formatFormula(entry);
      }
    }
    final entry = _findFormel(norm);
    return entry != null ? _formatFormula(entry) : null;
  }

  String? tryEpoche(String message) {
    final raw = message.trim();
    if (raw.isEmpty || raw.length > 400) return null;
    final norm = _normalize(raw);
    if (_isNegated(norm)) return null;

    const intentWords = [
      'epoche', 'literatur', 'merkmale', 'zeitraum', 'autoren',
      'wann war', 'was ist', 'erklaere', 'erklare',
    ];
    final hasIntent = intentWords.any((w) => norm.contains(w)) || _epochenIndex.keys.any(norm.contains);
    if (!hasIntent) return null;

    const patterns = [
      r'(?:merkmale|zeitraum|autoren)\s+(?:der\s+|des\s+|von\s+|vom\s+)?(.+?)\s*[?.!]*$',
      r'(?:wann\s+war|wann\s+ist)\s+(?:die\s+)?(.+?)\s*[?.!]*$',
      r'(?:was\s+ist|was\s+war|erklaere?|erkläre?)\s+(?:die\s+|der\s+|das\s+)?(.+?)\s*[?.!]*$',
      r'epoche\s+(.+?)\s*[?.!]*$',
    ];
    for (final pat in patterns) {
      final m = RegExp(pat, caseSensitive: false).firstMatch(norm);
      if (m != null) {
        final q = _normalize(m.group(1)!);
        if (_epochenIndex.containsKey(q)) return _formatEpoche(_epochenIndex[q]!);
      }
    }
    Map<String, dynamic>? best;
    var bestLen = 0;
    for (final entry in _epochenIndex.entries) {
      final k = entry.key;
      if (RegExp(r'(?<!\w)' + RegExp.escape(k) + r'(?!\w)').hasMatch(norm) && k.length > bestLen) {
        best = entry.value;
        bestLen = k.length;
      }
    }
    return best != null ? _formatEpoche(best) : null;
  }

  String? tryWerk(String message) {
    final raw = message.trim();
    if (raw.isEmpty || raw.length > 400) return null;
    final norm = _normalize(raw);
    if (_isNegated(norm)) return null;

    final lookupIntent = RegExp(
      r'\b(wer\s+(?:schrieb|verfasste|hat\s+geschrieben|geschrieben\s+hat)|autor\s+(?:von|des|der|vom)|wann\s+(?:entstand|erschien|wurde|kam)|worum\s+geht\s+es|handlung\s+von|inhalt\s+von|um\s+was\s+geht\s+es\s+in|geschrieben\s+hat|verfasst\s+hat)\b',
    ).hasMatch(norm);

    const patterns = [
      r'(?:wer\s+schrieb|wer\s+verfasste|wer\s+hat|autor\s+(?:von|des|der|vom))\s+(?:den\s+|die\s+|das\s+|dem\s+)?(.+?)(?:\s+(?:geschrieben|verfasst))?\s*[?.!]*$',
      r'\bwer\s+(?:den\s+|die\s+|das\s+|dem\s+)?(.+?)\s+(?:geschrieben|verfasst)\s+hat\b',
      r'wann\s+(?:entstand|erschien|wurde|kam)\s+(?:der\s+|die\s+|das\s+)?(.+?)(?:\s+(?:geschrieben|veroeffentlicht|heraus))?\s*[?.!]*$',
      r'(?:worum\s+geht\s+es|handlung\s+von|um\s+was\s+geht\s+es\s+in|inhalt\s+von)\s+(?:in\s+)?(?:der\s+|die\s+|das\s+|dem\s+)?(.+?)\s*[?.!]*$',
    ];
    for (final pat in patterns) {
      final m = RegExp(pat, caseSensitive: false).firstMatch(norm);
      if (m != null) {
        final q = _normalize(m.group(1)!);
        if (_werkeIndex.containsKey(q)) return _formatWerk(_werkeIndex[q]!);
        for (final entry in _werkeIndex.entries) {
          final k = entry.key;
          if (k == q || (k.length >= 5 && q.contains(k))) return _formatWerk(entry.value);
        }
      }
    }
    if (!lookupIntent) return null;

    Map<String, dynamic>? best;
    var bestLen = 0;
    for (final entry in _werkeIndex.entries) {
      final k = entry.key;
      if (k.length >= 5 &&
          RegExp(r'(?<!\w)' + RegExp.escape(k) + r'(?!\w)').hasMatch(norm) &&
          k.length > bestLen) {
        best = entry.value;
        bestLen = k.length;
      }
    }
    return best != null ? _formatWerk(best) : null;
  }

  String? tryTopics(String message) {
    if (message.isEmpty || message.length > 400) return null;
    final norm = _normalize(message);

    final mGrade = RegExp(r'(?:klasse\s*(\d{1,2})|(\d{1,2})\.?\s*klasse)').firstMatch(norm);
    if (mGrade == null) return null;
    final grade = int.parse(mGrade.group(1) ?? mGrade.group(2)!);
    if (grade < 1 || grade > 13) return null;
    if (!RegExp(r'\b(themen|lern|behandel|durch|stoff|lehrplan|themenuebersicht|themenübersicht|inhalte|inhalt|kurs|grundkurs|leistungskurs)').hasMatch(norm)) {
      return null;
    }

    const subjectMap = {
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
    };
    String? wantedSubject;
    for (final entry in subjectMap.entries) {
      for (final v in entry.value) {
        if (RegExp(r'(?<!\w)' + RegExp.escape(v) + r'(?!\w)').hasMatch(norm)) {
          wantedSubject = entry.key;
          break;
        }
      }
      if (wantedSubject != null) break;
    }

    if (_topicsData.isEmpty) return null;
    final topics = (_topicsData['klasse_$grade'] as Map?)?.cast<String, dynamic>();
    if (topics == null || topics.isEmpty) {
      return 'Für Klasse $grade sind leider keine Themen hinterlegt.';
    }

    if (wantedSubject != null && topics.containsKey(wantedSubject)) {
      final items = (topics[wantedSubject] as List).cast<String>();
      final buf = StringBuffer('**Klasse $grade — ${wantedSubject[0].toUpperCase()}${wantedSubject.substring(1)}:**\n');
      for (final t in items) {
        buf.writeln('  • $t');
      }
      return buf.toString().trimRight();
    }
    final buf = StringBuffer('**Klasse $grade — typische Themen:**\n');
    topics.forEach((subj, items) {
      final cap = '${subj[0].toUpperCase()}${subj.substring(1)}';
      final first = (items as List).cast<String>().take(4).join('; ');
      buf.writeln('*$cap:* $first');
    });
    return buf.toString().trimRight();
  }

  String _formatConcept(Map<String, dynamic> c) {
    final summary = (c['summary'] ?? '').toString();
    return '**${c["name"]}**\n\n$summary';
  }

  String? tryConcept(String message) {
    final raw = message.trim();
    if (raw.isEmpty || raw.length > 400) return null;
    final norm = _normalize(raw);
    if (_isNegated(norm)) return null;

    const patterns = [
      r'(?:was\s+(?:ist|sind|war|waren|bedeutet|versteht\s+man\s+unter))\s+(?:der\s+|die\s+|das\s+|den\s+|dem\s+|ein\s+|eine\s+)?(.+?)\s*[?.!]*$',
      r'erkl(?:ä|ae)re?\s+(?:mir\s+)?(?:der\s+|die\s+|das\s+|den\s+|dem\s+|ein\s+|eine\s+)?(.+?)\s*[?.!]*$',
      r'definition\s+(?:von|für)\s+(.+?)\s*[?.!]*$',
      r'(.+?)\s+(?:einfach\s+)?(?:erkl(?:ä|ae)rt|erkl(?:ä|ae)ren)\s*[?.!]*$',
    ];
    for (final pat in patterns) {
      final m = RegExp(pat, caseSensitive: false).firstMatch(norm);
      if (m != null) {
        final q = _normalize(m.group(1)!);
        final qStrip = q.replaceFirst(_articleStrip, '').trim();
        for (final v in [q, qStrip]) {
          if (_conceptsIndex.containsKey(v)) {
            return _formatConcept(_conceptsIndex[v]!);
          }
        }
        for (final entry in _conceptsIndex.entries) {
          final k = entry.key;
          if (k.length >= 4 && (k.contains(qStrip) || qStrip.contains(k))) {
            return _formatConcept(entry.value);
          }
        }
      }
    }
    if (_conceptsIndex.containsKey(norm)) return _formatConcept(_conceptsIndex[norm]!);

    Map<String, dynamic>? best;
    var bestLen = 0;
    for (final entry in _conceptsIndex.entries) {
      final k = entry.key;
      if (k.length >= 5 &&
          RegExp(r'(?<!\w)' + RegExp.escape(k) + r'(?!\w)').hasMatch(norm) &&
          k.length > bestLen) {
        best = entry.value;
        bestLen = k.length;
      }
    }
    return best != null ? _formatConcept(best) : null;
  }

  String? tryCurriculum(String message) {
    if (!_loaded) return null;
    for (final fn in <String? Function(String)>[tryFormula, tryWerk, tryEpoche, tryConcept, tryTopics]) {
      try {
        final out = fn(message);
        if (out != null) return out;
      } catch (_) {}
    }
    return null;
  }
}
