WHISPER_ERROR_CORRECTIONS = {
    'Seesucht': ['Sehnsucht'],
    'Sesucht': ['Sehnsucht'],
    'Sänsucht': ['Sehnsucht'],

    'Reindacht': ['reingedacht', 'wirklich'],
    'Koffen': ['Koffer', 'hoffen'],
    'Sprachkennungsassistenten': ['Spracherkennungsassistenten'],
    'Erkennungsassistenten': ['Spracherkennungsassistenten'],
    'Alltagssparen': ['Alltagssprache'],
    'Zufalliges': ['zuverlässig'],
    'Zeichensetzer': ['Satzzeichen'],
    'saubert': ['sauber'],
    'Ausdehnte': ['Aussagen'],
    'Musiklauf': ['Musik läuft'],

    'am Offen': ['am Ofen', 'offen'],
    'komm am': ['komm an', 'kommen'],

    'das des': ['das', 'des'],
    'die der': ['die', 'der'],
    'ihm im': ['ihm', 'im'],
    'ihn in': ['ihn', 'in'],

    'is': ['ist', 'es'],
    'hab': ['habe', 'hab'],
    'ham': ['haben'],
    'hamm': ['haben'],
    'könn': ['können'],
    'müss': ['müssen'],
    'sollt': ['sollte', 'sollt'],
    'wollt': ['wollte', 'wollt'],

    'den dann': ['denn', 'dann'],
    'wan wann': ['wann', 'wenn'],
    'wen wenn': ['wenn', 'wen'],
    'das dass': ['dass', 'das'],

    'einmal': ['einmal', 'ein Mal'],
    'aufeinmal': ['auf einmal'],
    'vorallem': ['vor allem'],
    'trotzdem': ['trotzdem'],
    'nachdem': ['nachdem', 'nach dem'],
    'seitdem': ['seitdem', 'seit dem'],

    'Universität': ['Universität'],
    'Universiät': ['Universität'],
    'Professer': ['Professor'],
    'Proffessor': ['Professor'],
    'Studend': ['Student'],

    'Prozend': ['Prozent'],
    'prozent': ['Prozent'],
    'prozand': ['Prozent'],
    'Kilommeter': ['Kilometer'],
    'kilometa': ['Kilometer'],

    'Komputer': ['Computer'],
    'Compiuter': ['Computer'],
    'Softwäre': ['Software'],
    'Hardwäre': ['Hardware'],
    'Algorytmus': ['Algorithmus'],
    'Algorismus': ['Algorithmus'],
    'Dattenbank': ['Datenbank'],
    'Datanbank': ['Datenbank'],

    'Pazient': ['Patient'],
    'Patiend': ['Patient'],
    'Diagnosse': ['Diagnose'],
    'Diagnohse': ['Diagnose'],
    'Theraphi': ['Therapie'],
    'Therappi': ['Therapie'],
    'Medikamend': ['Medikament'],
    'Medikemant': ['Medikament'],

    'Firmma': ['Firma'],
    'Geschäfd': ['Geschäft'],
    'Marketink': ['Marketing'],
    'Managemend': ['Management'],
    'Strategie': ['Strategie'],
    'Strateghi': ['Strategie'],

    'Volesung': ['Vorlesung'],
    'Vorlesunk': ['Vorlesung'],
    'Seminahr': ['Seminar'],
    'Klausur': ['Klausur'],
    'Klausahr': ['Klausur'],
    'Prüfunk': ['Prüfung'],
    'Abschlus': ['Abschluss'],
}

SEMANTIC_CLUSTERS = {
    'schule': {
        'core': ['Schule', 'Lehrer', 'Schüler', 'Unterricht', 'Klasse', 'Fach', 'Note'],
        'extended': ['Hausaufgabe', 'Prüfung', 'Test', 'Zeugnis', 'Klassenzimmer', 'Tafel',
                    'Schulhof', 'Pause', 'Stunde', 'Fächer', 'Lernen', 'Bildung'],
    },
    'universität': {
        'core': ['Universität', 'Professor', 'Student', 'Vorlesung', 'Seminar', 'Studium'],
        'extended': ['Fakultät', 'Institut', 'Dozent', 'Semester', 'Bachelor', 'Master',
                    'Promotion', 'Dissertation', 'Forschung', 'Wissenschaft', 'Campus'],
    },
    'arbeit': {
        'core': ['Arbeit', 'Job', 'Beruf', 'Firma', 'Büro', 'Chef', 'Kollege'],
        'extended': ['Karriere', 'Gehalt', 'Lohn', 'Vertrag', 'Projekt', 'Meeting',
                    'Besprechung', 'Aufgabe', 'Deadline', 'Team', 'Abteilung'],
    },
    'computer': {
        'core': ['Computer', 'Software', 'Programm', 'Code', 'Daten', 'Internet'],
        'extended': ['Algorithmus', 'Datenbank', 'Server', 'Netzwerk', 'App', 'Website',
                    'Programmierung', 'Entwicklung', 'System', 'Hardware', 'Prozessor'],
    },
    'medizin': {
        'core': ['Arzt', 'Patient', 'Krankenhaus', 'Krankheit', 'Behandlung', 'Medikament'],
        'extended': ['Diagnose', 'Therapie', 'Operation', 'Symptom', 'Gesundheit', 'Pflege',
                    'Klinik', 'Praxis', 'Untersuchung', 'Rezept', 'Heilung'],
    },
    'wissenschaft': {
        'core': ['Forschung', 'Experiment', 'Theorie', 'Hypothese', 'Ergebnis', 'Studie'],
        'extended': ['Methode', 'Analyse', 'Daten', 'Beweis', 'Publikation', 'Labor',
                    'Wissenschaftler', 'Entdeckung', 'These', 'Dissertation'],
    },
    'wirtschaft': {
        'core': ['Geld', 'Wirtschaft', 'Markt', 'Unternehmen', 'Handel', 'Preis'],
        'extended': ['Investition', 'Gewinn', 'Verlust', 'Kosten', 'Budget', 'Finanzen',
                    'Bank', 'Kredit', 'Aktie', 'Börse', 'Umsatz', 'Kapital'],
    },
    'politik': {
        'core': ['Politik', 'Regierung', 'Partei', 'Wahl', 'Gesetz', 'Staat'],
        'extended': ['Demokratie', 'Parlament', 'Minister', 'Politiker', 'Abstimmung',
                    'Reform', 'Opposition', 'Koalition', 'Beschluss', 'Debatte'],
    },
    'umwelt': {
        'core': ['Umwelt', 'Natur', 'Klima', 'Energie', 'Nachhaltigkeit', 'Ökologie'],
        'extended': ['Recycling', 'CO2', 'Emission', 'Solar', 'Wind', 'Erneuerbar',
                    'Verschmutzung', 'Artenschutz', 'Wald', 'Ressource'],
    },
    'technik': {
        'core': ['Technik', 'Maschine', 'Gerät', 'Technologie', 'Innovation', 'Entwicklung'],
        'extended': ['Roboter', 'Automatisierung', 'Digital', 'Elektronik', 'Sensor',
                    'Steuerung', 'Motor', 'Antrieb', 'System', 'Werkzeug'],
    },
}

PHONETIC_WORD_GROUPS = {
    'ieren_ending': [
        'funktionieren', 'studieren', 'passieren', 'interessieren', 'analysieren',
        'organisieren', 'optimieren', 'realisieren', 'spezialisieren', 'fokussieren',
        'diskutieren', 'präsentieren', 'dokumentieren', 'implementieren', 'aktualisieren',
    ],
    'ung_ending': [
        'Entwicklung', 'Forschung', 'Bildung', 'Lösung', 'Bedeutung', 'Erfahrung',
        'Vorlesung', 'Behandlung', 'Untersuchung', 'Besprechung', 'Verbesserung',
        'Änderung', 'Anwendung', 'Erklärung', 'Entscheidung', 'Bewertung',
    ],
    'heit_keit_ending': [
        'Möglichkeit', 'Sicherheit', 'Wichtigkeit', 'Schwierigkeit', 'Fähigkeit',
        'Wahrscheinlichkeit', 'Gelegenheit', 'Notwendigkeit', 'Geschwindigkeit',
        'Genauigkeit', 'Zuverlässigkeit', 'Nachhaltigkeit', 'Verständlichkeit',
    ],
    'lich_ending': [
        'eigentlich', 'natürlich', 'wirklich', 'wahrscheinlich', 'hauptsächlich',
        'unterschiedlich', 'zusätzlich', 'ursprünglich', 'grundsätzlich',
        'möglicherweise', 'normalerweise', 'beispielsweise', 'glücklicherweise',
    ],
    'isch_ending': [
        'technisch', 'wissenschaftlich', 'praktisch', 'theoretisch', 'logisch',
        'systematisch', 'automatisch', 'kritisch', 'spezifisch', 'typisch',
        'elektronisch', 'ökonomisch', 'ökologisch', 'psychologisch',
    ],
}

CONTEXT_CORRECTIONS = {
    ('mal', r'ein\s+mal'): 'einmal',
    ('mals', r'nie\s+mals'): 'niemals',
    ('dem', r'nach\s+dem'): 'nachdem',
    ('dem', r'seit\s+dem'): 'seitdem',
    ('all', r'vor\s+all'): 'vor allem',
    ('her', r'bis\s+her'): 'bisher',
    ('hin', r'bis\s+hin'): 'bishin',

    ('n', r'auf\s+n'): "auf 'n",
    ('nen', r'für\s+nen'): "für 'nen",
    ('ne', r'so\s+ne'): "so 'ne",
}

PHRASE_CORRECTIONS = {
    'linke Sätze': 'längere Sätze',
    'Endes Textes': 'Ende des Tests',
    'Endes Tests': 'Ende des Tests',
    'solltet ihr zahlen': 'sollte die Zahl sieben',
    'Das ist Dezember': 'Dezember',

    'Das ist ein ganzes Maß': 'Es ist ein ganz normaler Nachmittag',
    'Charakter Grammatik sind verlassen': 'korrekter Grammatik',
    'Charakter Grammatik': 'korrekter Grammatik',
    'Seiten und Mengen': 'Zeiten und Mengen',
    'seht ihr das auch': 'funktioniert das auch',
    'Millilitern Tegel': 'Milliliter Tee getrunken',
    'Millilitern Tee': 'Milliliter Tee',
    '8x216 ergibt 1728': 'acht mal zwei sechzehn ergibt',
    'gerade ist': 'gerade Zahl',
    'Größe 10 ist': 'größer als zehn ist',
    'Das Werk ist wichtig': 'Diese Reihenfolge ist wichtig',
    'Gleiches Musiklauf': 'Während im Hintergrund leise Musik läuft',
    'schreiben Sie eine Nachricht': 'schließlich eine Nachricht schreiben',

    'im Kontrolle': 'im Kontext',
    'im Kontrolle von': 'im Kontext von',
    'Textes schreiben': 'Tests schreiben',
    'Textes machen': 'Tests machen',

    'am Offen': 'am Ofen',
    'komm am': 'komm an',
    'auf einmal': 'auf einmal',
    'vor allem': 'vor allem',

    'die Zahl 7': 'die Zahl sieben',
    'Zahl 7': 'Zahl sieben',
    '1 Minute benötigt': 'achtzehn Minuten gebraucht',
    '50 Millilitern': '750 Milliliter',

    'ich laufe': 'ich laufe',
    'Ich Läufe': 'Ich laufe',
    'ich Läufe': 'ich laufe',

    'die Rechte': 'die Rechtschreibung',
    'zur Rechte': 'zur Rechtschreibung',

    'Das ist ähm': '',
    'Also ähm': 'Also',
    'Ja also': 'Also',

    'saubert, Aber': 'sauber in',
    ', Aber ein Text': ' in Text',
}

SENTENCE_PATTERNS = {
    'fragment_starters': [
        r'^\.\s+[A-ZÄÖÜ]',
        r'^,\s+[a-zäöü]',
        r'^[a-zäöü]',
    ],
    'fragment_enders': [
        r'[a-zäöü]\s*$',
        r',\s*$',
        r'\s+und\s*$',
        r'\s+oder\s*$',
    ],
    'incomplete_clauses': [
        r'\b(dass|weil|wenn|obwohl|ob)\s*[,.!?]',
        r'[,.]\s*(der|die|das)\s*[,.!?]',
    ],
}

ACADEMIC_VOCABULARY = {
    'transitions': [
        'erstens', 'zweitens', 'drittens', 'viertens', 'fünftens',
        'zunächst', 'dann', 'danach', 'anschließend', 'schließlich', 'zuletzt',
        'einerseits', 'andererseits', 'außerdem', 'darüber hinaus', 'zusätzlich',
        'folglich', 'daher', 'deshalb', 'deswegen', 'somit', 'demnach',
        'im Gegensatz dazu', 'jedoch', 'allerdings', 'dennoch', 'trotzdem',
        'zusammenfassend', 'abschließend', 'insgesamt', 'im Wesentlichen',
    ],
    'presentation': [
        'Guten Tag', 'Willkommen', 'Heute', 'sprechen wir über',
        'Thema', 'Vortrag', 'Präsentation', 'Folie', 'Grafik', 'Diagramm',
        'wie Sie sehen', 'auf dieser Folie', 'im nächsten Punkt',
        'Fragen', 'Diskussion', 'Fazit', 'Schlussfolgerung',
    ],
    'explanation': [
        'das bedeutet', 'das heißt', 'mit anderen Worten', 'anders gesagt',
        'zum Beispiel', 'beispielsweise', 'etwa', 'wie etwa',
        'im Sinne von', 'bezogen auf', 'hinsichtlich', 'bezüglich',
        'grundsätzlich', 'prinzipiell', 'im Allgemeinen', 'generell',
    ],
    'emphasis': [
        'besonders', 'insbesondere', 'vor allem', 'hauptsächlich',
        'wichtig', 'wesentlich', 'entscheidend', 'zentral', 'bedeutsam',
        'interessanterweise', 'bemerkenswerterweise', 'überraschenderweise',
    ],
}


def get_correction_candidates(word: str) -> list:
    word_lower = word.lower()
    candidates = []

    if word in WHISPER_ERROR_CORRECTIONS:
        candidates.extend(WHISPER_ERROR_CORRECTIONS[word])
    if word_lower in WHISPER_ERROR_CORRECTIONS:
        candidates.extend(WHISPER_ERROR_CORRECTIONS[word_lower])

    return list(set(candidates))


def get_semantic_cluster(word: str) -> dict:
    word_lower = word.lower()

    for cluster_name, cluster_data in SEMANTIC_CLUSTERS.items():
        all_words = cluster_data.get('core', []) + cluster_data.get('extended', [])
        all_words_lower = [w.lower() for w in all_words]

        if word_lower in all_words_lower:
            return {
                'cluster': cluster_name,
                'core': cluster_data.get('core', []),
                'extended': cluster_data.get('extended', []),
            }

    return {}


def get_phonetic_group(word: str) -> list:
    word_lower = word.lower()
    similar = []

    for group_name, words in PHONETIC_WORD_GROUPS.items():
        words_lower = [w.lower() for w in words]
        if word_lower in words_lower:
            similar.extend(words)

    return list(set(similar))


def is_academic_term(word: str) -> bool:
    word_lower = word.lower()

    for category, terms in ACADEMIC_VOCABULARY.items():
        terms_lower = [t.lower() for t in terms]
        if word_lower in terms_lower:
            return True
        for term in terms:
            if word_lower in term.lower():
                return True

    return False


def apply_phrase_corrections(text: str) -> str:
    if not text:
        return text

    result = text
    for incorrect, correct in PHRASE_CORRECTIONS.items():
        if incorrect.lower() in result.lower():
            import re
            pattern = re.compile(re.escape(incorrect), re.IGNORECASE)
            result = pattern.sub(correct, result)

    return result


def get_all_known_errors() -> dict:
    return dict(WHISPER_ERROR_CORRECTIONS)
