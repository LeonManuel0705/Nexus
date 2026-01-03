import subprocess
import json
from datetime import datetime, timedelta
from typing import List, Dict, Optional
import re

# Try to use EventKit (native macOS calendar API)
try:
    import EventKit
    EVENTKIT_AVAILABLE = True
except ImportError:
    EVENTKIT_AVAILABLE = False


def get_macos_calendar_events_eventkit(days_ahead: int = 14) -> Dict:
    """Fetch events from macOS Calendar using EventKit (native API)."""
    if not EVENTKIT_AVAILABLE:
        return {
            "success": False,
            "error": "eventkit_not_available",
            "message": "EventKit not available. Install with: pip install pyobjc-framework-EventKit",
            "events": []
        }

    try:
        store = EventKit.EKEventStore.alloc().init()

        # Request access - this will prompt for permission if needed
        # Note: In a GUI app, this would show a dialog. In a server context,
        # it relies on existing permissions

        # Check authorization status
        status = EventKit.EKEventStore.authorizationStatusForEntityType_(EventKit.EKEntityTypeEvent)

        if status == EventKit.EKAuthorizationStatusNotDetermined:
            # Request access - this triggers a permission dialog on first run
            try:
                # macOS 14+ API
                store.requestFullAccessToEventsWithCompletion_(lambda granted, error: None)
            except:
                # Legacy API
                store.requestAccessToEntityType_completion_(
                    EventKit.EKEntityTypeEvent,
                    lambda granted, error: None
                )
            # Return a message telling user to grant permission
            return {
                "success": False,
                "error": "permission_needed",
                "message": "Calendar permission needed. Please go to System Settings → Privacy & Security → Calendars and enable access for Python/Terminal, then refresh.",
                "events": []
            }
        elif status == EventKit.EKAuthorizationStatusDenied or status == EventKit.EKAuthorizationStatusRestricted:
            return {
                "success": False,
                "error": "no_permission",
                "message": "Calendar access denied. Please grant permission in System Settings → Privacy & Security → Calendars → Enable for Terminal/Python.",
                "events": []
            }

        # Get date range
        start_date = EventKit.NSDate.date()
        end_date = EventKit.NSDate.dateWithTimeIntervalSinceNow_(days_ahead * 24 * 60 * 60)

        # Get all calendars
        calendars = store.calendarsForEntityType_(EventKit.EKEntityTypeEvent)

        if not calendars or len(calendars) == 0:
            return {
                "success": False,
                "error": "no_calendars",
                "message": "No calendars found. Make sure you have calendars set up in the Calendar app.",
                "events": []
            }

        # Create predicate for events
        predicate = store.predicateForEventsWithStartDate_endDate_calendars_(
            start_date, end_date, calendars
        )

        # Fetch events
        ek_events = store.eventsMatchingPredicate_(predicate)

        events = []
        for ek_event in ek_events:
            try:
                # Get start date
                start = ek_event.startDate()
                if start:
                    # Convert NSDate to Python datetime
                    timestamp = start.timeIntervalSince1970()
                    dt = datetime.fromtimestamp(timestamp)
                    date_str = dt.strftime("%Y-%m-%d")
                    time_str = dt.strftime("%H:%M") if not ek_event.allDay() else ""
                else:
                    date_str = datetime.now().strftime("%Y-%m-%d")
                    time_str = ""

                event = {
                    "id": str(ek_event.eventIdentifier() or hash(ek_event.title() or "")),
                    "title": str(ek_event.title() or "Untitled"),
                    "date": date_str,
                    "time": time_str,
                    "location": str(ek_event.location() or ""),
                    "description": str(ek_event.notes() or ""),
                    "source": "macos",
                    "calendar": str(ek_event.calendar().title()) if ek_event.calendar() else ""
                }
                events.append(event)
            except Exception as e:
                # Skip problematic events
                continue

        # Sort by date and time
        events.sort(key=lambda e: (e.get('date', ''), e.get('time', '')))

        return {
            "success": True,
            "events": events,
            "source": "macos"
        }

    except Exception as e:
        return {
            "success": False,
            "error": "eventkit_error",
            "message": f"EventKit error: {str(e)}",
            "events": []
        }


def get_macos_calendar_events_icalbuddy(days_ahead: int = 14) -> Dict:
    """Fetch events from macOS Calendar using icalBuddy (fallback)."""
    try:
        cmd = [
            'icalBuddy',
            '-f',
            '-ea',
            '-b', '',
            '-nc',
            '-nrd',
            '-df', '%Y-%m-%d',
            '-tf', '%H:%M',
            '-iep', 'title,datetime,location,notes,uid',
            '-ps', '|:|',
            '-po', 'datetime,title,location,notes,uid',
            f'eventsToday+{days_ahead}'
        ]

        result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)

        if result.returncode != 0:
            if "No calendars" in result.stderr:
                return {
                    "success": False,
                    "error": "no_calendars",
                    "message": "icalBuddy cannot access calendars. Please grant Calendar access in System Settings > Privacy & Security > Calendars.",
                    "events": []
                }
            return {
                "success": False,
                "error": "command_failed",
                "message": result.stderr or "Failed to fetch calendar events",
                "events": []
            }

        events = parse_icalbuddy_output(result.stdout)
        return {
            "success": True,
            "events": events,
            "source": "macos"
        }

    except FileNotFoundError:
        return {
            "success": False,
            "error": "not_installed",
            "message": "icalBuddy not installed. Run: brew install ical-buddy",
            "events": []
        }
    except subprocess.TimeoutExpired:
        return {
            "success": False,
            "error": "timeout",
            "message": "Calendar request timed out",
            "events": []
        }
    except Exception as e:
        return {
            "success": False,
            "error": "unknown",
            "message": str(e),
            "events": []
        }


def get_macos_calendar_events(days_ahead: int = 14) -> Dict:
    """Fetch events from macOS Calendar. Tries EventKit first, falls back to icalBuddy."""
    # Try EventKit first (native API, more reliable)
    if EVENTKIT_AVAILABLE:
        result = get_macos_calendar_events_eventkit(days_ahead)
        if result["success"] or result.get("error") in ["no_permission", "no_calendars"]:
            return result

    # Fall back to icalBuddy
    return get_macos_calendar_events_icalbuddy(days_ahead)


def parse_icalbuddy_output(output: str) -> List[Dict]:
    """Parse icalBuddy output into structured events."""
    events = []

    if not output.strip():
        return events

    lines = output.strip().split('\n')

    for line in lines:
        if not line.strip():
            continue

        parts = line.split('|:|')

        if len(parts) >= 2:
            datetime_str = parts[0].strip()
            title = parts[1].strip() if len(parts) > 1 else "Untitled"
            location = parts[2].strip() if len(parts) > 2 else ""
            notes = parts[3].strip() if len(parts) > 3 else ""
            uid = parts[4].strip() if len(parts) > 4 else str(hash(line))

            date_match = re.search(r'(\d{4}-\d{2}-\d{2})', datetime_str)
            time_match = re.search(r'(\d{2}:\d{2})', datetime_str)

            event = {
                "id": uid,
                "title": title,
                "date": date_match.group(1) if date_match else datetime.now().strftime("%Y-%m-%d"),
                "time": time_match.group(1) if time_match else "",
                "location": location,
                "description": notes,
                "source": "macos"
            }
            events.append(event)

    return events


def get_calendars() -> Dict:
    """Get list of available calendars."""
    # Try EventKit first
    if EVENTKIT_AVAILABLE:
        try:
            store = EventKit.EKEventStore.alloc().init()
            calendars = store.calendarsForEntityType_(EventKit.EKEntityTypeEvent)

            cal_list = []
            for cal in calendars:
                cal_list.append({
                    "name": str(cal.title()),
                    "type": str(cal.type()),
                    "color": str(cal.color()) if cal.color() else None
                })

            return {"success": True, "calendars": cal_list}
        except Exception as e:
            pass  # Fall through to icalBuddy

    # Fall back to icalBuddy
    try:
        result = subprocess.run(['icalBuddy', 'calendars'], capture_output=True, text=True, timeout=5)

        if result.returncode != 0:
            return {"success": False, "calendars": [], "error": result.stderr}

        calendars = []
        for line in result.stdout.strip().split('\n'):
            line = line.strip()
            if line and not line.startswith('•'):
                parts = line.split(' (')
                name = parts[0].strip()
                cal_type = parts[1].rstrip(')') if len(parts) > 1 else "local"
                calendars.append({"name": name, "type": cal_type})

        return {"success": True, "calendars": calendars}

    except Exception as e:
        return {"success": False, "calendars": [], "error": str(e)}


def merge_events(macos_events: List[Dict], local_events: List[Dict]) -> List[Dict]:
    """Merge macOS calendar events with local Nexus events."""
    all_events = []
    seen_ids = set()

    for event in macos_events:
        event_id = event.get('id', '')
        if event_id not in seen_ids:
            seen_ids.add(event_id)
            all_events.append(event)

    for event in local_events:
        event_id = event.get('id', '')
        if event_id not in seen_ids:
            event['source'] = 'nexus'
            seen_ids.add(event_id)
            all_events.append(event)

    all_events.sort(key=lambda e: (e.get('date', ''), e.get('time', '')))

    return all_events
