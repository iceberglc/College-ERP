from django.contrib import messages as flash_messages
from django.contrib.auth.decorators import login_required
from django.core.exceptions import PermissionDenied
from django.shortcuts import redirect, render
from django.urls import reverse
from django.utils import timezone
from django.views.decorators.http import require_http_methods

from .messaging import accessible_groups_for_user, ensure_thread_for_group, unread_count_for_thread
from .models import ChatMessage, ChatReadState, Group


def _group_for_user_or_403(user, group_id):
    try:
        return accessible_groups_for_user(user).get(id=group_id)
    except Group.DoesNotExist as exc:
        raise PermissionDenied("You do not have access to this group chat.") from exc


def _thread_cards_for_user(user):
    cards = []
    for group in accessible_groups_for_user(user):
        thread = ensure_thread_for_group(group)
        last_message = thread.messages.select_related("sender").order_by("-created_at").first()
        cards.append(
            {
                "group": group,
                "thread": thread,
                "last_message": last_message,
                "unread_count": unread_count_for_thread(user, thread),
            }
        )
    cards.sort(
        key=lambda item: (
            item["last_message"].created_at if item["last_message"] else item["thread"].updated_at
        ),
        reverse=True,
    )
    return cards


@login_required
@require_http_methods(["GET", "POST"])
def messages_home(request, group_id=None):
    thread_cards = _thread_cards_for_user(request.user)
    active_group = None
    active_thread = None

    if group_id is not None:
        active_group = _group_for_user_or_403(request.user, group_id)
    elif thread_cards:
        active_group = thread_cards[0]["group"]

    if active_group:
        active_thread = ensure_thread_for_group(active_group)

    if request.method == "POST":
        if not active_thread:
            flash_messages.error(request, "Choose a group before sending a message.")
            return redirect(reverse("messages"))

        body = (request.POST.get("body") or "").strip()
        if not body:
            flash_messages.error(request, "Message cannot be empty.")
            return redirect(reverse("message_thread", args=[active_group.id]))

        if len(body) > 4000:
            flash_messages.error(request, "Message is too long. Keep it under 4000 characters.")
            return redirect(reverse("message_thread", args=[active_group.id]))

        message = ChatMessage.objects.create(
            thread=active_thread,
            sender=request.user,
            body=body,
        )
        active_thread.updated_at = message.created_at
        active_thread.save(update_fields=["updated_at"])
        ChatReadState.objects.update_or_create(
            thread=active_thread,
            user=request.user,
            defaults={"last_read_at": timezone.now()},
        )
        return redirect(reverse("message_thread", args=[active_group.id]) + "#latest")

    chat_messages = []
    if active_thread:
        ChatReadState.objects.update_or_create(
            thread=active_thread,
            user=request.user,
            defaults={"last_read_at": timezone.now()},
        )
        recent_messages = list(
            active_thread.messages.select_related("sender").order_by("-created_at")[:120]
        )
        chat_messages = list(reversed(recent_messages))
        thread_cards = _thread_cards_for_user(request.user)

    context = {
        "page_title": "Messages",
        "thread_cards": thread_cards,
        "active_group": active_group,
        "active_thread": active_thread,
        "chat_messages": chat_messages,
    }
    return render(request, "main_app/messages.html", context)
