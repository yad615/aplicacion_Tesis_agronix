from datetime import date, datetime, timedelta
from enum import Enum
import typing
from django.utils import timezone

from . import views

class AmPmOrUnknown(Enum):
    AM = "AM"
    PM = "PM"
    UNKNOWN = "UNKNOWN"

class GenericCalendarProvider(Enum):
    GOOGLE_CALENDAR = "Google Calendar"
    OUTLOOK_CALENDAR = "Outlook Calendar"
    APPLE_CALENDAR = "Apple Calendar"
    ANY = "Any"

class CalendarEvent(typing.TypedDict):
    id: str
    title: str
    description: typing.Optional[str]
    date: str
    time: str
    priority: str
    created_by_ai: bool
    created_at: str

class ActionSummary(typing.TypedDict):
    action: str
    result: str
    details: typing.Optional[dict]

def _generate_event_id() -> str:
    import uuid
    return f"event_{str(uuid.uuid4())[:8]}"

def _parse_time_with_ampm(time_str: str, am_pm: AmPmOrUnknown) -> str:
    if not time_str:
        return "09:00"
    
    try:
        if am_pm == AmPmOrUnknown.AM:
            parts = time_str.split(':')
            hour = int(parts[0])
            minute = int(parts[1]) if len(parts) > 1 else 0
            if hour == 12:
                hour = 0
            return f"{hour:02d}:{minute:02d}"
        elif am_pm == AmPmOrUnknown.PM:
            parts = time_str.split(':')
            hour = int(parts[0])
            minute = int(parts[1]) if len(parts) > 1 else 0
            if hour != 12:
                hour += 12
            return f"{hour:02d}:{minute:02d}"
        else:
            parts = time_str.split(':')
            hour = int(parts[0])
            minute = int(parts[1]) if len(parts) > 1 else 0
            return f"{hour:02d}:{minute:02d}"
    except (ValueError, IndexError):
        return "09:00"

def _validate_date(date_str: str) -> str:
    if not date_str:
        return timezone.now().date().isoformat()
    
    try:
        parsed_date = datetime.strptime(date_str, "%Y-%m-%d")
        return parsed_date.strftime("%Y-%m-%d")
    except ValueError:
        return timezone.now().date().isoformat()

def _get_user_events(user_id: int) -> list:
    if hasattr(views, 'CALENDAR_EVENTS'):
        return views.CALENDAR_EVENTS.get(user_id, [])
    return []

def _save_user_events(user_id: int, events: list):
    if hasattr(views, 'CALENDAR_EVENTS'):
        views.CALENDAR_EVENTS[user_id] = events

def _create_event_dict(title: str, description: str, date_str: str, time_str: str, priority: str) -> dict:
    return {
        'id': _generate_event_id(),
        'title': title,
        'description': description,
        'date': date_str,
        'time': time_str,
        'priority': priority,
        'created_by_ai': True,
        'created_at': timezone.now().isoformat()
    }

def create_calendar_event(
    title: str,
    description: typing.Optional[str] = None,
    date: str = None,
    time: typing.Optional[str] = None,
    start_am_pm_or_unknown: AmPmOrUnknown = AmPmOrUnknown.UNKNOWN,
    priority: str = "normal",
    user_id: int = None
) -> ActionSummary:
    if not user_id:
        return ActionSummary(
            action="create_calendar_event",
            result="error",
            details={"message": "❌ ID de usuario requerido"}
        )
    
    validated_date = _validate_date(date)
    parsed_time = _parse_time_with_ampm(time or "09:00", start_am_pm_or_unknown)
    
    new_event = _create_event_dict(
        title=title,
        description=description or f"Evento programado para {title}",
        date_str=validated_date,
        time_str=parsed_time,
        priority=priority
    )
    
    user_events = _get_user_events(user_id)
    user_events.append(new_event)
    
    _save_user_events(user_id, user_events)
    
    return ActionSummary(
        action="create_calendar_event",
        result="success",
        details={
            "event_id": new_event['id'],
            "title": title,
            "date": validated_date,
            "time": parsed_time,
            "message": f"✅ Evento '{title}' programado para el {validated_date} a las {parsed_time}",
            "priority": priority
        }
    )

def search_calendar_events(
    query: str,
    start_date: typing.Optional[str] = None,
    end_date: typing.Optional[str] = None,
    user_id: int = None
) -> ActionSummary:
    if not user_id:
        return ActionSummary(
            action="search_calendar_events",
            result="error",
            details={"message": "❌ ID de usuario requerido"}
        )
    
    user_events = _get_user_events(user_id)
    
    if not user_events:
        return ActionSummary(
            action="search_calendar_events",
            result="success",
            details={
                "message": f"🔍 No se encontraron eventos para '{query}'",
                "events": [],
                "count": 0
            }
        )
    
    if not start_date:
        start_date = timezone.now().date().isoformat()
    if not end_date:
        end_date = (timezone.now().date() + timedelta(days=30)).isoformat()
    
    filtered_events = []
    query_lower = query.lower()
    
    for event in user_events:
        event_date = event.get("date", "")
        if start_date <= event_date <= end_date:
            title_lower = event.get("title", "").lower()
            desc_lower = event.get("description", "").lower()
            
            if (query_lower in title_lower or query_lower in desc_lower):
                filtered_events.append({
                    "id": event.get("id", ""),
                    "title": event.get("title", ""),
                    "date": event.get("date", ""),
                    "time": event.get("time", ""),
                    "description": event.get("description", ""),
                    "priority": event.get("priority", "normal")
                })
    
    return ActionSummary(
        action="search_calendar_events",
        result="success",
        details={
            "message": f"🔍 Encontrados {len(filtered_events)} eventos para '{query}'",
            "events": filtered_events[:5],
            "count": len(filtered_events)
        }
    )

def show_calendar_events(
    date: typing.Optional[str] = None,
    user_id: int = None
) -> ActionSummary:
    if not user_id:
        return ActionSummary(
            action="show_calendar_events",
            result="error",
            details={"message": "❌ ID de usuario requerido"}
        )
    
    target_date = date or timezone.now().date().isoformat()
    
    user_events = _get_user_events(user_id)
    
    events_for_date = [
        event for event in user_events
        if event.get('date') == target_date
    ]
    
    events_for_date.sort(key=lambda x: x.get('time', '00:00'))
    
    formatted_events = []
    for event in events_for_date:
        formatted_events.append({
            "id": event.get("id", ""),
            "title": event.get("title", ""),
            "time": event.get("time", ""),
            "description": event.get("description", ""),
            "priority": event.get("priority", "normal")
        })
    
    return ActionSummary(
        action="show_calendar_events",
        result="success",
        details={
            "message": f"📅 Eventos para {target_date}: {len(formatted_events)} encontrados",
            "events": formatted_events,
            "count": len(formatted_events),
            "date": target_date
        }
    )

def modify_calendar_event(
    event_id: str,
    title: typing.Optional[str] = None,
    description: typing.Optional[str] = None,
    date: typing.Optional[str] = None,
    time: typing.Optional[str] = None,
    priority: typing.Optional[str] = None,
    user_id: int = None
) -> ActionSummary:
    if not user_id:
        return ActionSummary(
            action="modify_calendar_event",
            result="error",
            details={"message": "❌ ID de usuario requerido"}
        )
    
    user_events = _get_user_events(user_id)
    
    event_found = None
    for event in user_events:
        if event.get("id") == event_id:
            event_found = event
            break
    
    if not event_found:
        return ActionSummary(
            action="modify_calendar_event",
            result="error",
            details={"message": f"❌ No se encontró el evento con ID {event_id}"}
        )
    
    changes = []
    if title:
        event_found["title"] = title
        changes.append(f"título: {title}")
    
    if description:
        event_found["description"] = description
        changes.append("descripción actualizada")
    
    if date:
        event_found["date"] = _validate_date(date)
        changes.append(f"fecha: {date}")
    
    if time:
        event_found["time"] = _parse_time_with_ampm(time, AmPmOrUnknown.UNKNOWN)
        changes.append(f"hora: {time}")
    
    if priority:
        event_found["priority"] = priority
        changes.append(f"prioridad: {priority}")
    
    _save_user_events(user_id, user_events)
    
    changes_text = ", ".join(changes) if changes else "ningún cambio"
    
    return ActionSummary(
        action="modify_calendar_event",
        result="success",
        details={
            "event_id": event_id,
            "title": event_found["title"],
            "changes": changes_text,
            "message": f"✏️ Evento '{event_found['title']}' modificado: {changes_text}"
        }
    )

def delete_calendar_event(
    event_id: str,
    user_id: int = None
) -> ActionSummary:
    if not user_id:
        return ActionSummary(
            action="delete_calendar_event",
            result="error",
            details={"message": "❌ ID de usuario requerido"}
        )
    
    user_events = _get_user_events(user_id)
    
    event_found = None
    for i, event in enumerate(user_events):
        if event.get("id") == event_id:
            event_found = user_events.pop(i)
            break
    
    if not event_found:
        return ActionSummary(
            action="delete_calendar_event",
            result="error",
            details={"message": f"❌ No se encontró el evento con ID {event_id}"}
        )
    
    _save_user_events(user_id, user_events)
    
    return ActionSummary(
        action="delete_calendar_event",
        result="success",
        details={
            "event_id": event_id,
            "title": event_found["title"],
            "message": f"🗑️ Evento '{event_found['title']}' eliminado correctamente"
        }
    )

def get_events_for_date(target_date: str, user_id: int) -> list:
    user_events = _get_user_events(user_id)
    events = [event for event in user_events if event.get("date") == target_date]
    return sorted(events, key=lambda x: x.get("time", ""))

def get_upcoming_events(user_id: int, days_ahead: int = 7) -> list:
    start_date = timezone.now().date().isoformat()
    end_date = (timezone.now().date() + timedelta(days=days_ahead)).isoformat()
    
    user_events = _get_user_events(user_id)
    upcoming = []
    
    for event in user_events:
        event_date = event.get("date", "")
        if start_date <= event_date <= end_date:
            upcoming.append(event)
    
    return sorted(upcoming, key=lambda x: (x.get("date", ""), x.get("time", "")))

def get_events_count(user_id: int) -> int:
    user_events = _get_user_events(user_id)
    return len(user_events)