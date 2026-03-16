class OfflineAIService {
  static final OfflineAIService _instance = OfflineAIService._internal();
  factory OfflineAIService() => _instance;
  OfflineAIService._internal();

  Future<String> processQuery(String query, {Map<String, dynamic>? context}) async {
    final lowercaseQuery = query.toLowerCase();

    if (_isMathQuery(lowercaseQuery)) {
      return _handleMathQuery(query);
    }

    if (_isEssayQuery(lowercaseQuery)) {
      return _handleEssayQuery(query);
    }

    if (_isSummarizeQuery(lowercaseQuery)) {
      return _handleSummarizeQuery(query);
    }

    if (_isScheduleQuery(lowercaseQuery)) {
      return _handleScheduleQuery(query, context);
    }

    return '''Ich bin dein Offline-Assistent und kann dir bei folgenden Aufgaben helfen:

📐 **Mathematik**
- Gleichungen lösen (z.B. "Löse 2x + 5 = 15")
- Grundrechenarten

📝 **Schreiben**
- Aufsatz-Gliederungen erstellen
- Texte zusammenfassen

📅 **Organisation**
- Informationen zu deinem Stundenplan
- Aufgaben und Termine

Stelle mir eine Frage zu einem dieser Themen!''';
  }

  bool _isMathQuery(String query) {
    return query.contains('löse') ||
           query.contains('berechne') ||
           query.contains('rechne') ||
           query.contains('+') ||
           query.contains('-') ||
           query.contains('*') ||
           query.contains('/') ||
           query.contains('=') ||
           query.contains('gleichung');
  }

  bool _isEssayQuery(String query) {
    return query.contains('aufsatz') ||
           query.contains('essay') ||
           query.contains('gliederung') ||
           query.contains('schreib') ||
           query.contains('text') && query.contains('hilf');
  }

  bool _isSummarizeQuery(String query) {
    return query.contains('zusammenfass') ||
           query.contains('fass zusammen') ||
           query.contains('kürz') ||
           query.contains('summarize');
  }

  bool _isScheduleQuery(String query) {
    return query.contains('stundenplan') ||
           query.contains('unterricht') ||
           query.contains('was habe ich') ||
           query.contains('wann') && query.contains('schule');
  }

  String _handleMathQuery(String query) {
    try {

      if (query.contains('x') && query.contains('=')) {
        return _solveLinearEquation(query);
      }

      final result = _evaluateExpression(query);
      if (result != null) {
        return '**Ergebnis:** $result';
      }

      return '''Ich kann einfache Berechnungen durchführen:

• Grundrechenarten: "Was ist 125 * 8?"
• Lineare Gleichungen: "Löse 2x + 5 = 15"

Bitte formuliere deine Frage entsprechend.''';
    } catch (e) {
      return 'Ich konnte diese Berechnung leider nicht lösen. Bitte überprüfe die Eingabe.';
    }
  }

  String _solveLinearEquation(String query) {

    final regex = RegExp(r'(-?\d*\.?\d*)\s*x\s*([+-])\s*(\d+\.?\d*)\s*=\s*(-?\d+\.?\d*)');
    final match = regex.firstMatch(query);

    if (match == null) {
      return 'Konnte die Gleichung nicht erkennen. Bitte im Format "ax + b = c" eingeben.';
    }

    double a = match.group(1)!.isEmpty ? 1 : double.parse(match.group(1)!);
    final operator = match.group(2)!;
    double b = double.parse(match.group(3)!);
    final c = double.parse(match.group(4)!);

    if (operator == '-') b = -b;

    if (a == 0) {
      return 'Die Gleichung hat keine Lösung (a = 0).';
    }

    final x = (c - b) / a;

    return '''**Lösung der Gleichung**

Gegeben: ${a == 1 ? '' : a}x $operator ${match.group(3)} = $c

**Lösungsweg:**
1. ${a}x = $c ${operator == '+' ? '-' : '+'} ${match.group(3)}
2. ${a}x = ${c - b}
3. x = ${c - b} / $a

**x = ${x.toStringAsFixed(x == x.roundToDouble() ? 0 : 2)}**''';
  }

  String? _evaluateExpression(String query) {

    final regex = RegExp(r'(\d+\.?\d*)\s*([+\-*/])\s*(\d+\.?\d*)');
    final match = regex.firstMatch(query);

    if (match == null) return null;

    final a = double.parse(match.group(1)!);
    final op = match.group(2)!;
    final b = double.parse(match.group(3)!);

    double result;
    switch (op) {
      case '+':
        result = a + b;
        break;
      case '-':
        result = a - b;
        break;
      case '*':
        result = a * b;
        break;
      case '/':
        if (b == 0) return 'Division durch 0 ist nicht möglich.';
        result = a / b;
        break;
      default:
        return null;
    }

    return result == result.roundToDouble()
        ? result.toInt().toString()
        : result.toStringAsFixed(2);
  }

  String _handleEssayQuery(String query) {

    final topicRegex = RegExp(r'(?:über|zu|zum|thema)\s+(.+)', caseSensitive: false);
    final topicMatch = topicRegex.firstMatch(query);
    final topic = topicMatch?.group(1)?.trim() ?? 'dein Thema';

    return '''**Aufsatz-Gliederung: $topic**

📌 **1. Einleitung**
- Einführung ins Thema
- Relevanz und Aktualität
- These/Fragestellung formulieren

📌 **2. Hauptteil**

*2.1 Erster Aspekt*
- Argument/These
- Beispiel/Beleg
- Erläuterung

*2.2 Zweiter Aspekt*
- Argument/These
- Beispiel/Beleg
- Erläuterung

*2.3 Dritter Aspekt (optional)*
- Gegenposition/Kritik
- Abwägung

📌 **3. Schluss**
- Zusammenfassung der Ergebnisse
- Beantwortung der Fragestellung
- Ausblick/eigene Meinung

---
**Tipps:**
• Jeder Absatz: These → Begründung → Beispiel
• Vermeide "Ich denke..." in wissenschaftlichen Texten
• Achte auf Übergänge zwischen Absätzen''';
  }

  String _handleSummarizeQuery(String query) {
    return '''**Text zusammenfassen - Anleitung**

Da ich offline arbeite, kann ich deinen Text nicht direkt analysieren. Hier ist eine Methode, wie du selbst zusammenfassen kannst:

**1. Kernaussagen identifizieren**
- Lies jeden Absatz
- Markiere den wichtigsten Satz

**2. W-Fragen beantworten**
- Wer? Was? Wann? Wo? Warum? Wie?

**3. Eigene Formulierung**
- Schreibe die Kernaussagen in eigenen Worten
- Ziel: ~1/3 der Originallänge

**4. Struktur prüfen**
- Einleitung: Thema/Kontext
- Hauptteil: Kernaussagen
- Schluss: Fazit/Ergebnis

---
💡 **Tipp:** Füge deinen Text hier ein, damit ich dir die Schlüsselwörter markieren kann (wenn eine Internetverbindung verfügbar ist).''';
  }

  String _handleScheduleQuery(String query, Map<String, dynamic>? context) {

    final now = DateTime.now();
    final dayNames = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];
    final dayName = dayNames[now.weekday - 1];

    if (now.weekday > 5) {
      return '''Heute ist $dayName - am Wochenende hast du keinen Unterricht! 🎉

Öffne die **Schule**-Seite, um deinen Stundenplan für die nächste Woche zu sehen.''';
    }

    return '''Heute ist $dayName.

Öffne die **Schule**-Seite, um deinen aktuellen Stundenplan zu sehen.

Du kannst dort:
• Deinen Stundenplan verwalten
• Hausaufgaben tracken
• Klausuren und Tests eintragen''';
  }

  String solveMath(String equation) {
    return _handleMathQuery(equation);
  }

  String generateEssayOutline(String topic) {
    return _handleEssayQuery('Gliederung zum Thema $topic');
  }

  String getSummarizeHelp() {
    return _handleSummarizeQuery('zusammenfassen');
  }
}
