from rest_framework.permissions import BasePermission


class IsAdmin(BasePermission):
    """HOD / Admin users only."""

    def has_permission(self, request, view):
        return request.user.is_authenticated and str(request.user.user_type) == "1"


class IsTeacher(BasePermission):
    """Staff / Teacher users only."""

    def has_permission(self, request, view):
        return request.user.is_authenticated and str(request.user.user_type) == "2"


class IsStudent(BasePermission):
    """Student users only."""

    def has_permission(self, request, view):
        return request.user.is_authenticated and str(request.user.user_type) == "3"


class IsAdminOrTeacher(BasePermission):
    """Admin or Teacher users."""

    def has_permission(self, request, view):
        return request.user.is_authenticated and str(request.user.user_type) in ("1", "2")
