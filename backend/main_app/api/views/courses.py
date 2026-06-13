from rest_framework import generics
from rest_framework.permissions import IsAuthenticated

from ... import branching
from ...models import Course, Group
from ..serializers import CourseSerializer, GroupDetailSerializer, GroupSerializer


# ---------------------------------------------------------------------------
# Courses
# ---------------------------------------------------------------------------


class CourseListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = CourseSerializer
    pagination_class = None

    def get_queryset(self):
        return Course.objects.filter(is_active=True).order_by("name")


# ---------------------------------------------------------------------------
# Groups
# ---------------------------------------------------------------------------


class GroupListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = GroupSerializer

    def get_queryset(self):
        # Branch-aware: super admin → all, branch admin → assigned branches,
        # teacher → own groups, student → enrolled groups.
        qs = Group.objects.select_related("course", "teacher__admin", "branch").filter(
            is_archived=False
        )
        return branching.filter_groups_for_user(self.request.user, qs)


class GroupDetailView(generics.RetrieveAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = GroupDetailSerializer

    def get_queryset(self):
        qs = Group.objects.select_related("course", "teacher__admin", "branch")
        return branching.filter_groups_for_user(self.request.user, qs)
