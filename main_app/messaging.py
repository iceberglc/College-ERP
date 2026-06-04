from django.db.models import Count, Q

from .models import ChatReadState, ChatThread, Group


def accessible_groups_for_user(user):
    """Return groups the user can participate in or supervise."""
    if not user.is_authenticated:
        return Group.objects.none()

    user_type = str(getattr(user, "user_type", ""))
    base = Group.objects.select_related("course", "teacher__admin", "branch")

    if user_type == "1":
        return base.annotate(
            active_student_count=Count("enrollment", filter=Q(enrollment__is_active=True))
        ).order_by("is_archived", "name")

    if user_type == "2":
        try:
            staff = user.staff
        except Exception:
            return Group.objects.none()
        return (
            base.filter(teacher=staff, is_archived=False)
            .annotate(
                active_student_count=Count("enrollment", filter=Q(enrollment__is_active=True))
            )
            .order_by("name")
        )

    if user_type == "3":
        try:
            student = user.student
        except Exception:
            return Group.objects.none()
        return (
            base.filter(enrollment__student=student, enrollment__is_active=True, is_archived=False)
            .annotate(
                active_student_count=Count("enrollment", filter=Q(enrollment__is_active=True))
            )
            .distinct()
            .order_by("name")
        )

    return Group.objects.none()


def can_access_group(user, group):
    return accessible_groups_for_user(user).filter(id=group.id).exists()


def ensure_thread_for_group(group):
    thread, _ = ChatThread.objects.get_or_create(group=group)
    return thread


def unread_count_for_thread(user, thread):
    if not user.is_authenticated:
        return 0
    messages = thread.messages.exclude(sender=user)
    read_state = ChatReadState.objects.filter(thread=thread, user=user).first()
    if read_state and read_state.last_read_at:
        messages = messages.filter(created_at__gt=read_state.last_read_at)
    return messages.count()


def unread_message_count(user):
    total = 0
    for group in accessible_groups_for_user(user):
        total += unread_count_for_thread(user, ensure_thread_for_group(group))
    return total
