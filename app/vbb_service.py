\
\
\
\
\
   
import os
import json
import requests
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from pathlib import Path

VBB_API_BASE = "https://v6.vbb.transport.rest"

LOCATIONS_CACHE_FILE = Path(__file__).parent.parent / 'data' / 'vbb_locations_cache.json'

KNOWN_LOCATIONS_FILE = Path(__file__).parent.parent / 'data' / 'known_locations.json'

class VBBService:
                                                          
    def __init__(self):
        self.locations_cache = self._load_locations_cache()
        self.known_locations = self._load_known_locations()

    def _load_locations_cache(self) -> Dict:
                                            
        if LOCATIONS_CACHE_FILE.exists():
            try:
                with open(LOCATIONS_CACHE_FILE, 'r') as f:
                    return json.load(f)
            except Exception:
                pass
        return {}

    def _save_locations_cache(self):
                                          
        LOCATIONS_CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(LOCATIONS_CACHE_FILE, 'w') as f:
            json.dump(self.locations_cache, f)

    def _load_known_locations(self) -> Dict:
                                         
        if KNOWN_LOCATIONS_FILE.exists():
            try:
                with open(KNOWN_LOCATIONS_FILE, 'r') as f:
                    return json.load(f)
            except Exception:
                pass
                                 
        return {
            'home': None,                       
            'dlrg': None,                          
            'gym': None,                 
            'school': None                  
        }

    def save_known_location(self, name: str, location: Dict) -> Dict:
                                                     
        self.known_locations[name] = location
        KNOWN_LOCATIONS_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(KNOWN_LOCATIONS_FILE, 'w') as f:
            json.dump(self.known_locations, f, indent=2)
        return {'success': True, 'location': location}

    def get_known_locations(self) -> Dict:
                                            
        return {'success': True, 'locations': self.known_locations}

    def search_location(self, query: str) -> Dict:
                                                               
        cache_key = query.lower().strip()
        if cache_key in self.locations_cache:
            cached = self.locations_cache[cache_key]
                                    
            if cached.get('cached_at'):
                cached_time = datetime.fromisoformat(cached['cached_at'])
                if datetime.now() - cached_time < timedelta(days=7):
                    return {'success': True, 'locations': cached['results'], 'cached': True}

        try:
                                  
            response = requests.get(
                f"{VBB_API_BASE}/locations",
                params={
                    'query': query,
                    'results': 10,
                    'addresses': True,
                    'poi': True,
                    'stops': True
                },
                timeout=10
            )
            response.raise_for_status()
            locations = response.json()

            normalized = []
            for loc in locations:
                normalized.append({
                    'id': loc.get('id'),
                    'name': loc.get('name'),
                    'type': loc.get('type'),                      
                    'latitude': loc.get('location', {}).get('latitude') if loc.get('location') else loc.get('latitude'),
                    'longitude': loc.get('location', {}).get('longitude') if loc.get('location') else loc.get('longitude'),
                    'address': loc.get('address'),
                    'products': loc.get('products', {})
                })

            self.locations_cache[cache_key] = {
                'results': normalized,
                'cached_at': datetime.now().isoformat()
            }
            self._save_locations_cache()

            return {'success': True, 'locations': normalized}

        except requests.RequestException as e:
            return {'success': False, 'error': f'API-Fehler: {str(e)}'}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def search_nearby_stops(self, latitude: float, longitude: float, radius: int = 1000) -> Dict:
                                                
        try:
            response = requests.get(
                f"{VBB_API_BASE}/stops/nearby",
                params={
                    'latitude': latitude,
                    'longitude': longitude,
                    'distance': radius,
                    'results': 10
                },
                timeout=10
            )
            response.raise_for_status()
            stops = response.json()

            normalized = []
            for stop in stops:
                normalized.append({
                    'id': stop.get('id'),
                    'name': stop.get('name'),
                    'distance': stop.get('distance'),
                    'latitude': stop.get('location', {}).get('latitude'),
                    'longitude': stop.get('location', {}).get('longitude'),
                    'products': stop.get('products', {})
                })

            return {'success': True, 'stops': normalized}

        except requests.RequestException as e:
            return {'success': False, 'error': f'API-Fehler: {str(e)}'}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def get_route(self, from_location: Dict, to_location: Dict,
                  arrival_time: datetime = None, departure_time: datetime = None,
                  num_results: int = 5) -> Dict:
\
\
\
\
\
\
\
\
\
           
        try:
            params = {
                'results': num_results,
                'stopovers': True,
                'remarks': True,
                'polylines': False,
                'tickets': False
            }

            if from_location.get('id'):
                params['from'] = from_location['id']
            elif from_location.get('latitude') and from_location.get('longitude'):
                params['from.latitude'] = from_location['latitude']
                params['from.longitude'] = from_location['longitude']
                params['from.address'] = from_location.get('name', 'Aktueller Standort')
            else:
                return {'success': False, 'error': 'Ungültiger Startort'}

            if to_location.get('id'):
                params['to'] = to_location['id']
            elif to_location.get('latitude') and to_location.get('longitude'):
                params['to.latitude'] = to_location['latitude']
                params['to.longitude'] = to_location['longitude']
                params['to.address'] = to_location.get('name', 'Ziel')
            else:
                return {'success': False, 'error': 'Ungültiges Ziel'}

            if arrival_time:
                params['arrival'] = arrival_time.isoformat()
            elif departure_time:
                params['departure'] = departure_time.isoformat()
            else:
                params['departure'] = datetime.now().isoformat()

            response = requests.get(
                f"{VBB_API_BASE}/journeys",
                params=params,
                timeout=15
            )
            response.raise_for_status()
            data = response.json()

            journeys = data.get('journeys', [])
            routes = []

            for journey in journeys:
                legs = []
                total_duration = 0
                has_delay = False
                max_delay = 0

                for leg in journey.get('legs', []):
                                     
                    delay_departure = 0
                    delay_arrival = 0

                    if leg.get('departureDelay'):
                        delay_departure = leg['departureDelay'] // 60                      
                        if delay_departure > 0:
                            has_delay = True
                            max_delay = max(max_delay, delay_departure)

                    if leg.get('arrivalDelay'):
                        delay_arrival = leg['arrivalDelay'] // 60
                        if delay_arrival > 0:
                            has_delay = True
                            max_delay = max(max_delay, delay_arrival)

                    leg_info = {
                        'type': 'walk' if leg.get('walking') else 'transit',
                        'departure': {
                            'time': leg.get('departure'),
                            'planned_time': leg.get('plannedDeparture'),
                            'delay': delay_departure,
                            'station': leg.get('origin', {}).get('name'),
                            'platform': leg.get('departurePlatform')
                        },
                        'arrival': {
                            'time': leg.get('arrival'),
                            'planned_time': leg.get('plannedArrival'),
                            'delay': delay_arrival,
                            'station': leg.get('destination', {}).get('name'),
                            'platform': leg.get('arrivalPlatform')
                        },
                        'duration': leg.get('duration', 0) // 60 if leg.get('duration') else 0,           
                        'distance': leg.get('distance')
                    }

                    if not leg.get('walking'):
                        line = leg.get('line', {})
                        leg_info['line'] = {
                            'name': line.get('name'),
                            'product': line.get('product'),                                                         
                            'direction': leg.get('direction'),
                            'operator': line.get('operator', {}).get('name') if line.get('operator') else None
                        }

                        stopovers = leg.get('stopovers', [])
                        leg_info['stops_count'] = max(0, len(stopovers) - 2)                                  

                    legs.append(leg_info)
                    total_duration += leg_info['duration']

                departure_time_str = journey.get('legs', [{}])[0].get('departure')
                arrival_time_str = journey.get('legs', [{}])[-1].get('arrival') if journey.get('legs') else None

                routes.append({
                    'departure': departure_time_str,
                    'arrival': arrival_time_str,
                    'duration': total_duration,
                    'transfers': len([l for l in legs if l['type'] == 'transit']) - 1,
                    'legs': legs,
                    'has_delay': has_delay,
                    'max_delay': max_delay,
                    'price': journey.get('price', {}).get('amount') if journey.get('price') else None
                })

            return {
                'success': True,
                'routes': routes,
                'from': from_location.get('name', 'Start'),
                'to': to_location.get('name', 'Ziel')
            }

        except requests.RequestException as e:
            return {'success': False, 'error': f'API-Fehler: {str(e)}'}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def get_route_to_event(self, event: Dict, current_location: Dict,
                          buffer_minutes: int = 15) -> Dict:
\
\
\
\
\
\
\
           
        if not event.get('location'):
            return {'success': False, 'error': 'Event hat keinen Ort'}

        location_search = self.search_location(event['location'])
        if not location_search.get('success') or not location_search.get('locations'):
            return {'success': False, 'error': f"Ort nicht gefunden: {event['location']}"}

        destination = location_search['locations'][0]

        event_start = event.get('start')
        if isinstance(event_start, str):
            try:
                                       
                for fmt in ['%Y-%m-%dT%H:%M:%S%z', '%Y-%m-%dT%H:%M:%S', '%Y-%m-%d %H:%M']:
                    try:
                        event_start = datetime.strptime(event_start.replace('Z', '+00:00'), fmt)
                        break
                    except ValueError:
                        continue
                else:
                                                                
                    event_start = datetime.strptime(event_start[:10], '%Y-%m-%d')
                    event_start = event_start.replace(hour=9, minute=0)                   
            except Exception:
                return {'success': False, 'error': 'Ungültiges Datum'}

        arrival_time = event_start - timedelta(minutes=buffer_minutes)

        routes = self.get_route(
            from_location=current_location,
            to_location=destination,
            arrival_time=arrival_time,
            num_results=3
        )

        if routes.get('success'):
            routes['event'] = {
                'title': event.get('title') or event.get('summary'),
                'start': event_start.isoformat() if isinstance(event_start, datetime) else str(event_start),
                'location': event['location'],
                'buffer_minutes': buffer_minutes
            }

        return routes

    def get_departures(self, stop_id: str, duration: int = 30) -> Dict:
                                                  
        try:
            response = requests.get(
                f"{VBB_API_BASE}/stops/{stop_id}/departures",
                params={
                    'duration': duration,
                    'results': 20,
                    'remarks': True
                },
                timeout=10
            )
            response.raise_for_status()
            data = response.json()

            departures = []
            for dep in data.get('departures', []):
                delay = dep.get('delay', 0) // 60 if dep.get('delay') else 0

                departures.append({
                    'time': dep.get('when'),
                    'planned_time': dep.get('plannedWhen'),
                    'delay': delay,
                    'line': dep.get('line', {}).get('name'),
                    'product': dep.get('line', {}).get('product'),
                    'direction': dep.get('direction'),
                    'platform': dep.get('platform'),
                    'cancelled': dep.get('cancelled', False),
                    'remarks': [r.get('text') for r in dep.get('remarks', []) if r.get('text')]
                })

            return {'success': True, 'departures': departures, 'stop_id': stop_id}

        except requests.RequestException as e:
            return {'success': False, 'error': f'API-Fehler: {str(e)}'}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def check_delays_for_route(self, route: Dict) -> Dict:
                                                       
        delays = []
        total_delay = 0

        for leg in route.get('legs', []):
            if leg.get('type') != 'transit':
                continue

            departure = leg.get('departure', {})
            if departure.get('delay', 0) > 0:
                delays.append({
                    'station': departure.get('station'),
                    'line': leg.get('line', {}).get('name'),
                    'delay_minutes': departure.get('delay'),
                    'type': 'departure'
                })
                total_delay = max(total_delay, departure.get('delay', 0))

            arrival = leg.get('arrival', {})
            if arrival.get('delay', 0) > 0:
                delays.append({
                    'station': arrival.get('station'),
                    'line': leg.get('line', {}).get('name'),
                    'delay_minutes': arrival.get('delay'),
                    'type': 'arrival'
                })
                total_delay = max(total_delay, arrival.get('delay', 0))

        return {
            'success': True,
            'has_delays': len(delays) > 0,
            'delays': delays,
            'max_delay_minutes': total_delay
        }

    def format_route_summary(self, route: Dict) -> str:
                                                         
        if not route.get('legs'):
            return "Keine Route gefunden"

        parts = []
        for leg in route['legs']:
            if leg['type'] == 'walk':
                if leg.get('distance'):
                    parts.append(f"🚶 {leg['distance']}m zu Fuß")
                else:
                    parts.append(f"🚶 {leg['duration']} Min. zu Fuß")
            else:
                line = leg.get('line', {})
                product = line.get('product', '')
                name = line.get('name', '')

                emoji = {
                    'suburban': '🚆',          
                    'subway': '🚇',            
                    'tram': '🚊',
                    'bus': '🚌',
                    'ferry': '⛴️',
                    'express': '🚄',
                    'regional': '🚂'
                }.get(product, '🚃')

                direction = line.get('direction', '')
                if direction and len(direction) > 20:
                    direction = direction[:20] + '...'

                parts.append(f"{emoji} {name} → {direction}")

        summary = " → ".join(parts)

        duration = route.get('duration', 0)
        transfers = route.get('transfers', 0)

        timing = f"⏱️ {duration} Min."
        if transfers > 0:
            timing += f", {transfers} Umstieg{'e' if transfers > 1 else ''}"

        if route.get('has_delay'):
            timing += f" ⚠️ +{route.get('max_delay', 0)} Min. Verspätung"

        return f"{summary}\n{timing}"

vbb_service = VBBService()

def get_vbb_service() -> VBBService:
                                              
    return vbb_service
