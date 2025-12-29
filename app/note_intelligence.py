import re
import threading
from typing import Optional, List, Dict, Tuple

TOPICS = {
    "de": {
        "Mathematik": ["gleichung", "formel", "berechnung", "algebra", "geometrie", "integral", "differential", "funktion", "variable", "zahlen", "prozent", "bruch", "wurzel", "potenz", "logarithmus", "statistik", "wahrscheinlichkeit", "matrix", "vektor", "sinus", "cosinus", "tangens", "pi", "radius", "durchmesser", "fläche", "volumen", "winkel", "dreieck", "kreis", "quadrat", "rechteck", "pythagoras", "primzahl", "fakultät", "summe", "produkt", "quotient", "differenz", "ableitung", "grenzwert", "reihe", "menge", "teilmenge"],
        "Physik": ["kraft", "energie", "geschwindigkeit", "beschleunigung", "masse", "newton", "elektrizität", "magnetismus", "welle", "frequenz", "schwingung", "atom", "elektron", "proton", "neutron", "photon", "quanten", "relativität", "gravitation", "impuls", "arbeit", "leistung", "spannung", "strom", "widerstand", "induktion", "kapazität", "thermodynamik", "entropie", "temperatur", "druck", "dichte", "optik", "licht", "spektrum", "schall", "akustik", "kernphysik", "radioaktivität", "fusion", "fission"],
        "Chemie": ["molekül", "atom", "reaktion", "element", "verbindung", "säure", "base", "ph-wert", "oxidation", "reduktion", "elektrolyse", "katalysator", "polymer", "organisch", "anorganisch", "kohlenstoff", "wasserstoff", "sauerstoff", "stickstoff", "metall", "nichtmetall", "ion", "bindung", "kovalent", "periodensystem", "isotop", "lösung", "konzentration", "mol", "masse", "volumen", "gas", "flüssig", "fest", "aggregatzustand", "endotherm", "exotherm", "gleichgewicht"],
        "Biologie": ["zelle", "dna", "rna", "protein", "gen", "evolution", "ökosystem", "organismus", "pflanze", "tier", "bakterie", "virus", "fotosynthese", "zellteilung", "mitose", "meiose", "chromosom", "mutation", "vererbung", "stoffwechsel", "enzym", "hormon", "nervensystem", "immunsystem", "kreislauf", "atmung", "verdauung", "gewebe", "organ", "population", "art", "gattung", "taxonomie", "ökologie", "biodiversität", "habitat", "nahrungskette"],
        "Geschichte": ["krieg", "revolution", "kaiser", "könig", "reich", "dynastie", "epoche", "jahrhundert", "antike", "mittelalter", "neuzeit", "weltkrieg", "demokratie", "monarchie", "republik", "kolonialismus", "imperialismus", "nationalismus", "reformation", "renaissance", "aufklärung", "industrialisierung", "verfassung", "parlament", "diktatur", "widerstand", "holocaust", "nachkrieg", "kalter krieg", "wiedervereinigung", "europäische union"],
        "Geographie": ["kontinent", "land", "stadt", "fluss", "berg", "ozean", "klima", "wetter", "vegetation", "bevölkerung", "migration", "wirtschaft", "landwirtschaft", "industrie", "ressourcen", "umwelt", "naturkatastrophe", "erdbeben", "vulkan", "tsunami", "überschwemmung", "dürre", "globalisierung", "entwicklung", "infrastruktur", "urbanisierung", "ländlich", "kartographie", "koordinaten", "längengrad", "breitengrad", "relief", "plateau", "tal", "delta", "küste"],
        "Informatik": ["algorithmus", "programmierung", "code", "software", "hardware", "datenbank", "netzwerk", "internet", "server", "client", "protokoll", "verschlüsselung", "sicherheit", "künstliche intelligenz", "maschinelles lernen", "datenstruktur", "variable", "funktion", "schleife", "bedingung", "objekt", "klasse", "vererbung", "api", "framework", "bibliothek", "compiler", "debugging", "testing", "version", "repository", "cloud", "virtualisierung", "container", "microservice"],
        "Wirtschaft": ["markt", "angebot", "nachfrage", "preis", "kosten", "gewinn", "verlust", "umsatz", "investition", "aktie", "börse", "inflation", "deflation", "rezession", "konjunktur", "bruttoinlandsprodukt", "export", "import", "handel", "währung", "zinsen", "kredit", "bank", "unternehmen", "konzern", "startup", "management", "marketing", "buchhaltung", "bilanz", "steuern", "arbeitslosigkeit", "gehalt", "lohn"],
        "Sprache": ["grammatik", "syntax", "semantik", "wortschatz", "vokabel", "konjugation", "deklination", "substantiv", "verb", "adjektiv", "adverb", "pronomen", "artikel", "präposition", "konjunktion", "satz", "absatz", "text", "aufsatz", "interpretation", "analyse", "metapher", "stilmittel", "rhetorik", "literatur", "autor", "dichter", "roman", "gedicht", "drama", "lyrik", "prosa", "epik"],
        "Kunst": ["malerei", "skulptur", "zeichnung", "fotografie", "architektur", "design", "künstler", "kunstwerk", "stil", "epoche", "impressionismus", "expressionismus", "surrealismus", "abstrakt", "modern", "zeitgenössisch", "museum", "galerie", "ausstellung", "komposition", "perspektive", "farbe", "form", "licht", "schatten", "kontrast", "harmonie"],
        "Musik": ["melodie", "harmonie", "rhythmus", "takt", "tempo", "note", "tonleiter", "akkord", "instrument", "orchester", "chor", "sänger", "komponist", "symphonie", "konzert", "oper", "klassik", "jazz", "rock", "pop", "elektronisch", "dirigent", "partitur", "interpretation"],
        "Sport": ["training", "wettkampf", "mannschaft", "spieler", "trainer", "taktik", "technik", "ausdauer", "kraft", "schnelligkeit", "koordination", "fitness", "gesundheit", "ernährung", "regeneration", "verletzung", "meisterschaft", "olympiade", "rekord", "liga", "pokal", "turnier"],
        "Medizin": ["diagnose", "therapie", "symptom", "krankheit", "patient", "arzt", "krankenhaus", "medikament", "operation", "heilung", "prävention", "impfung", "infektion", "entzündung", "krebs", "herz", "lunge", "leber", "niere", "gehirn", "blut", "organ", "gewebe", "anatomie", "physiologie"],
        "Recht": ["gesetz", "paragraph", "urteil", "gericht", "richter", "anwalt", "kläger", "beklagter", "vertrag", "haftung", "strafe", "verfahren", "klage", "berufung", "verfassung", "grundrecht", "strafrecht", "zivilrecht", "verwaltungsrecht", "arbeitsrecht", "familienrecht", "erbrecht"],
        "Psychologie": ["verhalten", "emotion", "kognition", "wahrnehmung", "gedächtnis", "lernen", "motivation", "persönlichkeit", "entwicklung", "sozial", "therapie", "störung", "depression", "angst", "stress", "bewusstsein", "unbewusst", "freud", "jung", "piaget", "experiment", "studie"],
        "Philosophie": ["ethik", "moral", "logik", "erkenntnistheorie", "metaphysik", "ontologie", "ästhetik", "existenz", "wahrheit", "realität", "bewusstsein", "freier wille", "determinismus", "rationalismus", "empirismus", "idealismus", "materialismus", "sokrates", "platon", "aristoteles", "kant", "nietzsche", "hegel"]
    },
    "en": {
        "Mathematics": ["equation", "formula", "calculation", "algebra", "geometry", "integral", "differential", "function", "variable", "numbers", "percent", "fraction", "root", "power", "logarithm", "statistics", "probability", "matrix", "vector", "sine", "cosine", "tangent", "pi", "radius", "diameter", "area", "volume", "angle", "triangle", "circle", "square", "rectangle", "pythagoras", "prime", "factorial", "sum", "product", "quotient", "difference", "derivative", "limit", "series", "set", "subset"],
        "Physics": ["force", "energy", "velocity", "acceleration", "mass", "newton", "electricity", "magnetism", "wave", "frequency", "oscillation", "atom", "electron", "proton", "neutron", "photon", "quantum", "relativity", "gravity", "momentum", "work", "power", "voltage", "current", "resistance", "induction", "capacitance", "thermodynamics", "entropy", "temperature", "pressure", "density", "optics", "light", "spectrum", "sound", "acoustics", "nuclear", "radioactivity", "fusion", "fission"],
        "Chemistry": ["molecule", "atom", "reaction", "element", "compound", "acid", "base", "ph", "oxidation", "reduction", "electrolysis", "catalyst", "polymer", "organic", "inorganic", "carbon", "hydrogen", "oxygen", "nitrogen", "metal", "nonmetal", "ion", "bond", "covalent", "periodic table", "isotope", "solution", "concentration", "mole", "mass", "volume", "gas", "liquid", "solid", "state", "endothermic", "exothermic", "equilibrium"],
        "Biology": ["cell", "dna", "rna", "protein", "gene", "evolution", "ecosystem", "organism", "plant", "animal", "bacteria", "virus", "photosynthesis", "cell division", "mitosis", "meiosis", "chromosome", "mutation", "heredity", "metabolism", "enzyme", "hormone", "nervous system", "immune system", "circulation", "respiration", "digestion", "tissue", "organ", "population", "species", "genus", "taxonomy", "ecology", "biodiversity", "habitat", "food chain"],
        "History": ["war", "revolution", "emperor", "king", "empire", "dynasty", "era", "century", "ancient", "medieval", "modern", "world war", "democracy", "monarchy", "republic", "colonialism", "imperialism", "nationalism", "reformation", "renaissance", "enlightenment", "industrialization", "constitution", "parliament", "dictatorship", "resistance", "holocaust", "postwar", "cold war", "reunification", "european union"],
        "Geography": ["continent", "country", "city", "river", "mountain", "ocean", "climate", "weather", "vegetation", "population", "migration", "economy", "agriculture", "industry", "resources", "environment", "natural disaster", "earthquake", "volcano", "tsunami", "flood", "drought", "globalization", "development", "infrastructure", "urbanization", "rural", "cartography", "coordinates", "longitude", "latitude", "relief", "plateau", "valley", "delta", "coast"],
        "Computer Science": ["algorithm", "programming", "code", "software", "hardware", "database", "network", "internet", "server", "client", "protocol", "encryption", "security", "artificial intelligence", "machine learning", "data structure", "variable", "function", "loop", "condition", "object", "class", "inheritance", "api", "framework", "library", "compiler", "debugging", "testing", "version", "repository", "cloud", "virtualization", "container", "microservice"],
        "Economics": ["market", "supply", "demand", "price", "cost", "profit", "loss", "revenue", "investment", "stock", "exchange", "inflation", "deflation", "recession", "cycle", "gdp", "export", "import", "trade", "currency", "interest", "credit", "bank", "company", "corporation", "startup", "management", "marketing", "accounting", "balance", "taxes", "unemployment", "salary", "wage"],
        "Language": ["grammar", "syntax", "semantics", "vocabulary", "conjugation", "declension", "noun", "verb", "adjective", "adverb", "pronoun", "article", "preposition", "conjunction", "sentence", "paragraph", "text", "essay", "interpretation", "analysis", "metaphor", "stylistic", "rhetoric", "literature", "author", "poet", "novel", "poem", "drama", "lyric", "prose", "epic"],
        "Art": ["painting", "sculpture", "drawing", "photography", "architecture", "design", "artist", "artwork", "style", "era", "impressionism", "expressionism", "surrealism", "abstract", "modern", "contemporary", "museum", "gallery", "exhibition", "composition", "perspective", "color", "form", "light", "shadow", "contrast", "harmony"],
        "Music": ["melody", "harmony", "rhythm", "beat", "tempo", "note", "scale", "chord", "instrument", "orchestra", "choir", "singer", "composer", "symphony", "concert", "opera", "classical", "jazz", "rock", "pop", "electronic", "conductor", "score", "interpretation"],
        "Sports": ["training", "competition", "team", "player", "coach", "tactics", "technique", "endurance", "strength", "speed", "coordination", "fitness", "health", "nutrition", "recovery", "injury", "championship", "olympics", "record", "league", "cup", "tournament"],
        "Medicine": ["diagnosis", "therapy", "symptom", "disease", "patient", "doctor", "hospital", "medication", "surgery", "healing", "prevention", "vaccination", "infection", "inflammation", "cancer", "heart", "lung", "liver", "kidney", "brain", "blood", "organ", "tissue", "anatomy", "physiology"],
        "Law": ["law", "paragraph", "judgment", "court", "judge", "lawyer", "plaintiff", "defendant", "contract", "liability", "penalty", "procedure", "lawsuit", "appeal", "constitution", "fundamental right", "criminal law", "civil law", "administrative law", "labor law", "family law", "inheritance law"],
        "Psychology": ["behavior", "emotion", "cognition", "perception", "memory", "learning", "motivation", "personality", "development", "social", "therapy", "disorder", "depression", "anxiety", "stress", "consciousness", "unconscious", "freud", "jung", "piaget", "experiment", "study"],
        "Philosophy": ["ethics", "morality", "logic", "epistemology", "metaphysics", "ontology", "aesthetics", "existence", "truth", "reality", "consciousness", "free will", "determinism", "rationalism", "empiricism", "idealism", "materialism", "socrates", "plato", "aristotle", "kant", "nietzsche", "hegel"]
    }
}


class NoteIntelligence:
    def __init__(self):
        self._model = None
        self._tokenizer = None
        self._model_lock = threading.Lock()
        self._model_loaded = False
        self._mlx_available = False

    def _check_mlx_available(self) -> bool:
        try:
            import platform
            if platform.processor() != 'arm':
                return False
            import mlx
            import mlx_lm
            return True
        except ImportError:
            return False

    def _load_model(self) -> bool:
        if self._model_loaded:
            return self._mlx_available

        with self._model_lock:
            if self._model_loaded:
                return self._mlx_available

            self._mlx_available = self._check_mlx_available()

            if self._mlx_available:
                try:
                    from mlx_lm import load
                    self._model, self._tokenizer = load("mlx-community/Qwen2.5-1.5B-Instruct-4bit")
                except Exception as e:
                    print(f"MLX model load failed for intelligence: {e}")
                    self._mlx_available = False

            self._model_loaded = True
            return self._mlx_available

    def detect_topics(self, text: str, language: str = "de", max_topics: int = 3) -> List[str]:
        if not text or len(text.strip()) < 20:
            return []

        text_lower = text.lower()
        topic_dict = TOPICS.get(language, TOPICS["de"])
        topic_scores: Dict[str, int] = {}

        for topic, keywords in topic_dict.items():
            score = 0
            for keyword in keywords:
                count = len(re.findall(r'\b' + re.escape(keyword) + r'\b', text_lower))
                score += count
            if score > 0:
                topic_scores[topic] = score

        sorted_topics = sorted(topic_scores.items(), key=lambda x: x[1], reverse=True)
        return [topic for topic, score in sorted_topics[:max_topics] if score >= 2]

    def generate_summary(self, text: str, language: str = "de", max_length: int = 100) -> str:
        if not text or len(text.strip()) < 50:
            return text

        if self._load_model() and self._mlx_available:
            return self._generate_summary_mlx(text, language, max_length)
        else:
            return self._generate_summary_extractive(text, language, max_length)

    def _generate_summary_mlx(self, text: str, language: str, max_length: int) -> str:
        try:
            from mlx_lm import generate

            if len(text) > 2000:
                text = text[:2000]

            if language == "de":
                prompt = f"""<|im_start|>system
Du erstellst kurze Zusammenfassungen. Antworte NUR mit der Zusammenfassung, ohne Einleitung.<|im_end|>
<|im_start|>user
Fasse zusammen (max. 2-3 Sätze): {text}<|im_end|>
<|im_start|>assistant
"""
            else:
                prompt = f"""<|im_start|>system
You create short summaries. Reply ONLY with the summary, no introduction.<|im_end|>
<|im_start|>user
Summarize (max. 2-3 sentences): {text}<|im_end|>
<|im_start|>assistant
"""

            response = generate(
                model=self._model,
                tokenizer=self._tokenizer,
                prompt=prompt,
                max_tokens=150,
                verbose=False
            )

            response = self._clean_summary_response(response)
            return response if response else self._generate_summary_extractive(text, language, max_length)

        except Exception as e:
            print(f"MLX summary generation error: {e}")
            return self._generate_summary_extractive(text, language, max_length)

    def _clean_summary_response(self, response: str) -> str:
        if not response:
            return ""

        response = response.strip()

        skip_patterns = [
            'here is', 'here\'s', 'summary:', 'zusammenfassung:',
            'the text', 'der text', 'this text', 'dieser text',
            'in summary', 'zusammenfassend', 'to summarize',
        ]

        lines = response.split('\n')
        clean_lines = []
        for line in lines:
            line = line.strip()
            if any(p in line.lower() for p in skip_patterns):
                continue
            if line.startswith(('-', '*', '#', '>', '•', '1.', '2.', '3.')):
                continue
            if line:
                clean_lines.append(line)

        response = ' '.join(clean_lines)
        response = re.sub(r'\s+', ' ', response).strip()

        return response

    def _generate_summary_extractive(self, text: str, language: str, max_length: int) -> str:
        sentences = re.split(r'(?<=[.!?])\s+', text)
        sentences = [s.strip() for s in sentences if s.strip() and len(s.strip()) > 10]

        if not sentences:
            return text[:max_length] + "..." if len(text) > max_length else text

        if len(sentences) <= 2:
            return text

        word_freq: Dict[str, int] = {}
        stop_words = self._get_stop_words(language)

        for sentence in sentences:
            words = re.findall(r'\b\w+\b', sentence.lower())
            for word in words:
                if word not in stop_words and len(word) > 2:
                    word_freq[word] = word_freq.get(word, 0) + 1

        sentence_scores: List[Tuple[int, float, str]] = []
        for idx, sentence in enumerate(sentences):
            words = re.findall(r'\b\w+\b', sentence.lower())
            score = sum(word_freq.get(word, 0) for word in words)
            if len(words) > 0:
                score = score / len(words)
            if idx == 0:
                score *= 1.5
            sentence_scores.append((idx, score, sentence))

        sentence_scores.sort(key=lambda x: x[1], reverse=True)

        num_sentences = max(1, min(3, len(sentences) // 3))
        top_sentences = sorted(sentence_scores[:num_sentences], key=lambda x: x[0])

        summary = ' '.join(s[2] for s in top_sentences)
        return summary

    def _get_stop_words(self, language: str) -> set:
        stop_words = {
            "de": {"der", "die", "das", "den", "dem", "des", "ein", "eine", "einer", "einem", "einen", "und", "oder", "aber", "ist", "sind", "war", "waren", "hat", "haben", "wird", "werden", "kann", "können", "muss", "müssen", "soll", "sollen", "mit", "von", "zu", "für", "auf", "in", "an", "bei", "nach", "vor", "über", "unter", "durch", "als", "wie", "wenn", "weil", "dass", "ob", "nicht", "auch", "noch", "schon", "nur", "sehr", "mehr", "so", "es", "sich", "er", "sie", "wir", "ihr", "du", "ich", "man", "was", "wer", "wo", "wann", "warum", "wie"},
            "en": {"the", "a", "an", "and", "or", "but", "is", "are", "was", "were", "has", "have", "had", "will", "would", "can", "could", "must", "should", "with", "of", "to", "for", "on", "in", "at", "by", "after", "before", "about", "over", "under", "through", "as", "like", "if", "because", "that", "whether", "not", "also", "still", "already", "only", "very", "more", "so", "it", "he", "she", "we", "you", "they", "i", "what", "who", "where", "when", "why", "how"}
        }
        return stop_words.get(language, stop_words["de"])

    def generate_key_points(self, text: str, language: str = "de", max_points: int = 5) -> List[str]:
        if not text or len(text.strip()) < 50:
            return []

        if self._load_model() and self._mlx_available:
            return self._generate_key_points_mlx(text, language, max_points)
        else:
            return self._generate_key_points_extractive(text, language, max_points)

    def _generate_key_points_mlx(self, text: str, language: str, max_points: int) -> List[str]:
        try:
            from mlx_lm import generate

            if len(text) > 2000:
                text = text[:2000]

            if language == "de":
                prompt = f"""<|im_start|>system
Extrahiere die wichtigsten Punkte als kurze Stichpunkte. Antworte NUR mit den Stichpunkten, ein Punkt pro Zeile.<|im_end|>
<|im_start|>user
Extrahiere {max_points} Kernpunkte: {text}<|im_end|>
<|im_start|>assistant
"""
            else:
                prompt = f"""<|im_start|>system
Extract key points as short bullet points. Reply ONLY with the points, one per line.<|im_end|>
<|im_start|>user
Extract {max_points} key points: {text}<|im_end|>
<|im_start|>assistant
"""

            response = generate(
                model=self._model,
                tokenizer=self._tokenizer,
                prompt=prompt,
                max_tokens=200,
                verbose=False
            )

            points = []
            for line in response.split('\n'):
                line = line.strip()
                line = re.sub(r'^[-•*\d.)\]]+\s*', '', line)
                if line and len(line) > 5 and len(line) < 200:
                    points.append(line)
                if len(points) >= max_points:
                    break

            return points if points else self._generate_key_points_extractive(text, language, max_points)

        except Exception as e:
            print(f"MLX key points generation error: {e}")
            return self._generate_key_points_extractive(text, language, max_points)

    def _generate_key_points_extractive(self, text: str, language: str, max_points: int) -> List[str]:
        sentences = re.split(r'(?<=[.!?])\s+', text)
        sentences = [s.strip() for s in sentences if s.strip() and len(s.strip()) > 20]

        if len(sentences) <= max_points:
            return sentences

        word_freq: Dict[str, int] = {}
        stop_words = self._get_stop_words(language)

        for sentence in sentences:
            words = re.findall(r'\b\w+\b', sentence.lower())
            for word in words:
                if word not in stop_words and len(word) > 2:
                    word_freq[word] = word_freq.get(word, 0) + 1

        sentence_scores: List[Tuple[int, float, str]] = []
        for idx, sentence in enumerate(sentences):
            words = re.findall(r'\b\w+\b', sentence.lower())
            score = sum(word_freq.get(word, 0) for word in words)
            if len(words) > 0:
                score = score / len(words)
            sentence_scores.append((idx, score, sentence))

        sentence_scores.sort(key=lambda x: x[1], reverse=True)
        top_sentences = sorted(sentence_scores[:max_points], key=lambda x: x[0])

        return [s[2] for s in top_sentences]


_intelligence: Optional[NoteIntelligence] = None


def get_intelligence() -> NoteIntelligence:
    global _intelligence
    if _intelligence is None:
        _intelligence = NoteIntelligence()
    return _intelligence


def detect_topics(text: str, language: str = "de", max_topics: int = 3) -> List[str]:
    return get_intelligence().detect_topics(text, language, max_topics)


def generate_summary(text: str, language: str = "de", max_length: int = 100) -> str:
    return get_intelligence().generate_summary(text, language, max_length)


def generate_key_points(text: str, language: str = "de", max_points: int = 5) -> List[str]:
    return get_intelligence().generate_key_points(text, language, max_points)
