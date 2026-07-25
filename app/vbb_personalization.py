import logging
from datetime import datetime
from typing import Optional

from .crypto_utils import encrypt_file, decrypt_file
from .paths import DATA_DIR

PREFERENCES_FILE = DATA_DIR / 'vbb_user_preferences.json'

MIN_SORT_USES = 15
SORT_DOMINANCE_THRESHOLD = 0.50
MIN_WEIGHT_ADAPTATION_USES = 20
COMMUTE_MIN_TRIPS = 8


def _default_preferences() -> dict:
    return {
        'version': 1,
        'last_modified': datetime.now().isoformat(),
        'sort_usage': {
            'recommended': 0,
            'next_departure': 0,
            'fastest': 0,
            'cheapest': 0,
            'fewest_transfers': 0,
        },
        'default_sort': 'recommended',
        'route_sort_prefs': {},
        'route_searches': [],
        'station_usage': {},
        'last_search': None,
        'detected_commutes': [],
        'feature_flags': {
            'adaptive_sort': True,
            'adaptive_weights': True,
            'last_search_restore': True,
            'smart_autocomplete': True,
            'commute_suggestions': True,
            'frequent_routes': True,
        },
    }


class VBBPersonalization:
    def __init__(self):
        self.prefs = self._load()

    def _load(self) -> dict:
        try:
            data = decrypt_file(PREFERENCES_FILE)
            if data and isinstance(data, dict) and data.get('version'):
                return data
        except Exception as e:
            logging.warning(f"Error loading VBB preferences: {e}")
        return _default_preferences()

    def _save(self):
        self.prefs['last_modified'] = datetime.now().isoformat()
        try:
            encrypt_file(self.prefs, PREFERENCES_FILE)
        except Exception as e:
            logging.error(f"Error saving VBB preferences: {e}")


    def track_sort(self, sort_type: str, from_id: str = None, to_id: str = None):
        VALID_SORTS = {'recommended', 'next_departure', 'fastest', 'cheapest', 'fewest_transfers'}
        if sort_type not in VALID_SORTS:
            return

        usage = self.prefs['sort_usage']
        usage[sort_type] = usage.get(sort_type, 0) + 1

        if from_id and to_id:
            key = f"{from_id}_{to_id}"
            self.prefs['route_sort_prefs'][key] = sort_type
            if len(self.prefs['route_sort_prefs']) > 100:
                keys = list(self.prefs['route_sort_prefs'].keys())
                for old_key in keys[:-100]:
                    del self.prefs['route_sort_prefs'][old_key]

        if self.prefs['feature_flags'].get('adaptive_sort'):
            self._maybe_adapt_default_sort()

        self._save()

    def track_search(self, from_loc: dict, to_loc: dict, departure: str = None):
        from_id = from_loc.get('id', '')
        to_id = to_loc.get('id', '')
        from_name = from_loc.get('name', '')
        to_name = to_loc.get('name', '')

        searches = self.prefs['route_searches']
        existing = next(
            (s for s in searches if s['from_id'] == from_id and s['to_id'] == to_id),
            None,
        )

        dep_hour = None
        if departure:
            try:
                dep_hour = datetime.fromisoformat(departure.replace('Z', '+00:00')).hour
            except Exception:
                dep_hour = datetime.now().hour
        else:
            dep_hour = datetime.now().hour

        if existing:
            existing['count'] += 1
            existing['last_search'] = datetime.now().isoformat()
            old_avg = existing.get('avg_departure_hour', dep_hour)
            existing['avg_departure_hour'] = round(
                (old_avg * (existing['count'] - 1) + dep_hour) / existing['count'], 1
            )
        else:
            searches.append({
                'from_id': from_id,
                'from_name': from_name,
                'from_latitude': from_loc.get('latitude'),
                'from_longitude': from_loc.get('longitude'),
                'to_id': to_id,
                'to_name': to_name,
                'to_latitude': to_loc.get('latitude'),
                'to_longitude': to_loc.get('longitude'),
                'count': 1,
                'last_search': datetime.now().isoformat(),
                'avg_departure_hour': dep_hour,
            })

        for loc, _ctx in [(from_loc, 'from'), (to_loc, 'to')]:
            lid = loc.get('id', '')
            if not lid:
                continue
            su = self.prefs['station_usage']
            if lid in su:
                su[lid]['count'] += 1
                su[lid]['last_used'] = datetime.now().isoformat()
            else:
                su[lid] = {
                    'name': loc.get('name', ''),
                    'count': 1,
                    'last_used': datetime.now().isoformat(),
                }

        self.prefs['last_search'] = {
            'from_id': from_id,
            'from_name': from_name,
            'from_latitude': from_loc.get('latitude'),
            'from_longitude': from_loc.get('longitude'),
            'to_id': to_id,
            'to_name': to_name,
            'to_latitude': to_loc.get('latitude'),
            'to_longitude': to_loc.get('longitude'),
        }

        if self.prefs['feature_flags'].get('commute_suggestions'):
            self._detect_commutes()

        self._save()


    def _maybe_adapt_default_sort(self):
        usage = self.prefs['sort_usage']
        total = sum(usage.values())
        if total < MIN_SORT_USES:
            return
        best_sort, best_count = max(usage.items(), key=lambda x: x[1])
        if best_count / total >= SORT_DOMINANCE_THRESHOLD:
            self.prefs['default_sort'] = best_sort

    def get_recommendation_weights(self) -> dict:
        base = {'speed': 0.35, 'transfers': 0.30, 'delay': 0.25, 'walk': 0.10}

        if not self.prefs['feature_flags'].get('adaptive_weights'):
            return base

        usage = self.prefs['sort_usage']
        total = sum(usage.values())
        if total < MIN_WEIGHT_ADAPTATION_USES:
            return base

        speed_pct = (usage.get('fastest', 0) + usage.get('next_departure', 0) * 0.5) / total
        transfer_pct = usage.get('fewest_transfers', 0) / total
        price_pct = usage.get('cheapest', 0) / total
        other_pct = max(0, 1 - speed_pct - transfer_pct - price_pct)

        w = {
            'speed': base['speed'] * 0.6 + speed_pct * 0.4,
            'transfers': base['transfers'] * 0.6 + transfer_pct * 0.4,
            'delay': base['delay'] * 0.6 + other_pct * 0.2,
            'walk': base['walk'],
        }
        s = sum(w.values())
        return {k: round(v / s, 3) for k, v in w.items()}

    def _detect_commutes(self):
        searches = self.prefs['route_searches']
        detected = self.prefs['detected_commutes']

        for search in searches:
            if search['count'] < COMMUTE_MIN_TRIPS:
                continue

            from_id = search['from_id']
            to_id = search['to_id']

            already = any(
                c['from_id'] == from_id and c['to_id'] == to_id for c in detected
            )
            if already:
                continue

            avg_hour = search.get('avg_departure_hour', 12)
            if 6 <= avg_hour <= 10:
                pattern = 'morning'
                label = 'Zur Schule'
            elif 14 <= avg_hour <= 19:
                pattern = 'evening'
                label = 'Nach Hause'
            else:
                pattern = 'general'
                label = f"{search['from_name']} \u2192 {search['to_name']}"

            detected.append({
                'from_id': from_id,
                'from_name': search['from_name'],
                'to_id': to_id,
                'to_name': search['to_name'],
                'pattern': pattern,
                'label': label,
                'avg_departure_hour': avg_hour,
            })


    def get_preferences(self) -> dict:
        return self.prefs

    def get_default_sort(self) -> str:
        return self.prefs.get('default_sort', 'recommended')

    def get_route_sort(self, from_id: str, to_id: str) -> Optional[str]:
        key = f"{from_id}_{to_id}"
        return self.prefs['route_sort_prefs'].get(key)

    def get_frequent_routes(self, limit: int = 4) -> list:
        searches = self.prefs['route_searches']
        qualified = [s for s in searches if s['count'] >= 3]
        qualified.sort(key=lambda x: x['count'], reverse=True)
        return qualified[:limit]

    def get_commute_suggestions(self) -> list:
        return self.prefs.get('detected_commutes', [])

    def get_station_usage(self) -> dict:
        return self.prefs.get('station_usage', {})

    def get_last_search(self) -> Optional[dict]:
        return self.prefs.get('last_search')


    def update_flags(self, flags: dict):
        current = self.prefs['feature_flags']
        for key in current:
            if key in flags and isinstance(flags[key], bool):
                current[key] = flags[key]
        self._save()

    def reset(self):
        self.prefs = _default_preferences()
        self._save()


_instance: Optional[VBBPersonalization] = None


def get_personalization() -> VBBPersonalization:
    global _instance
    if _instance is None:
        _instance = VBBPersonalization()
    return _instance
