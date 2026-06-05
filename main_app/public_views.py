import json
import logging

from django.conf import settings
from django.http import HttpResponse, JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

from .models import RegistrationLead


logger = logging.getLogger(__name__)


def _first_value(payload, *keys):
    for key in keys:
        value = payload.get(key)
        if value is not None and str(value).strip():
            return str(value).strip()
    return ""


def _parse_payload(request):
    content_type = request.META.get("CONTENT_TYPE", "")
    if "application/json" in content_type:
        if not request.body:
            return {}
        return json.loads(request.body.decode("utf-8"))
    return {key: value for key, value in request.POST.items()}


def _remote_addr(request):
    forwarded = request.META.get("HTTP_X_FORWARDED_FOR", "")
    if forwarded:
        return forwarded.split(",", 1)[0].strip()
    return request.META.get("REMOTE_ADDR", "")


@csrf_exempt
@require_http_methods(["POST", "OPTIONS"])
def registration_leads_receiver(request):
    if request.method == "OPTIONS":
        return HttpResponse(status=204)

    expected_token = getattr(settings, "REGISTRATION_LEADS_API_TOKEN", "").strip()
    if expected_token:
        auth_header = request.META.get("HTTP_AUTHORIZATION", "").strip()
        if auth_header != f"Bearer {expected_token}":
            return JsonResponse({"detail": "Unauthorized"}, status=401)

    try:
        payload = _parse_payload(request)
    except (json.JSONDecodeError, UnicodeDecodeError):
        return JsonResponse({"detail": "Invalid JSON payload."}, status=400)

    if not isinstance(payload, dict):
        return JsonResponse({"detail": "Payload must be an object."}, status=400)

    first_name = _first_value(payload, "first_name", "firstName", "given_name")
    last_name = _first_value(payload, "last_name", "lastName", "family_name")
    full_name = _first_value(payload, "full_name", "fullName", "name", "student_name")
    if not full_name:
        full_name = " ".join(part for part in [first_name, last_name] if part).strip()

    phone = _first_value(
        payload,
        "phone",
        "phone_number",
        "phoneNumber",
        "student_phone",
        "contact_phone",
        "contact",
    )
    email = _first_value(payload, "email", "email_address", "emailAddress")
    parent_phone = _first_value(
        payload,
        "parent_phone",
        "parentPhone",
        "guardian_phone",
        "guardianPhone",
        "parent_contact",
    )

    if not phone and not email and not parent_phone:
        return JsonResponse({"detail": "At least one contact field is required."}, status=400)

    lead = RegistrationLead.objects.create(
        full_name=full_name or "Unknown lead",
        first_name=first_name,
        last_name=last_name,
        email=email,
        phone=phone,
        parent_phone=parent_phone,
        program=_first_value(payload, "program", "course", "interested_program", "interested_course"),
        branch=_first_value(payload, "branch", "location", "preferred_branch"),
        preferred_schedule=_first_value(
            payload, "preferred_schedule", "preferredSchedule", "schedule", "preferred_time"
        ),
        source=_first_value(payload, "source", "lead_source", "platform") or "website",
        social_handle=_first_value(
            payload, "social_handle", "socialHandle", "instagram", "telegram", "username"
        ),
        campaign=_first_value(payload, "campaign", "ad_campaign"),
        utm_source=_first_value(payload, "utm_source", "utmSource"),
        utm_medium=_first_value(payload, "utm_medium", "utmMedium"),
        utm_campaign=_first_value(payload, "utm_campaign", "utmCampaign"),
        referrer=_first_value(payload, "referrer", "referer", "page_url", "pageUrl"),
        message=_first_value(payload, "message", "notes", "comment", "comments"),
        raw_payload=payload,
        remote_addr=_remote_addr(request),
        user_agent=request.META.get("HTTP_USER_AGENT", "")[:500],
    )
    logger.info("Registration lead received: id=%s source=%s", lead.pk, lead.source)
    return JsonResponse({"status": "ok", "lead_id": lead.pk}, status=201)
