from django.contrib.auth import authenticate
from django.core.exceptions import PermissionDenied as DjangoPermissionDenied
from django.db import transaction, models
from django.db.models import Q
from rest_framework import generics, status
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import RefreshToken

from .. import branching
from ..models import (
    Assignment,
    Attendance,
    AttendanceReport,
    Branch,
    Course,
    CustomUser,
    DashboardStory,
    Enrollment,
    FeedbackStaff,
    FeedbackStudent,
    Group,
    Invoice,
    LeaveReportStaff,
    LeaveReportStudent,
    LeaderboardSeason,
    LeaderboardSnapshot,
    Notification,
    RegistrationLead,
    ResultFile,
    Staff,
    Student,
    StudentResult,
    Submission,
    VocabularyDay,
    VocabularyDayCompletion,
    VocabularyDayWord,
    VocabularyQuizResult,
)
from .permissions import IsAdmin, IsAdminOrTeacher, IsStudent, IsTeacher
from .serializers import (
    AdminStaffFeedbackSerializer,
    AdminStaffLeaveSerializer,
    AdminStaffSerializer,
    AdminStudentFeedbackSerializer,
    AdminStudentLeaveSerializer,
    AdminStudentSerializer,
    AssignmentDetailSerializer,
    AssignmentSerializer,
    AttendanceSaveSerializer,
    AttendanceSerializer,
    ChangePasswordSerializer,
    CourseSerializer,
    EnrollmentSerializer,
    FcmTokenSerializer,
    GroupDetailSerializer,
    GroupSerializer,
    InvoiceSerializer,
    MeSerializer,
    NotificationSerializer,
    RegistrationLeadSerializer,
    StaffFeedbackSerializer,
    StaffLeaveSerializer,
    StaffStatsSerializer,
    StaffVocabularyDaySerializer,
    StorySerializer,
    StudentFeedbackSerializer,
    StudentLeaveSerializer,
    StudentResultSerializer,
    SubmissionSerializer,
    SubmitAssignmentSerializer,
    UserSerializer,
    VocabularyQuizSerializer,
    VocabularyWordWriteSerializer,
)


# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        # Accept either `email` or `login_id` in the identifier field.
        # The mobile app sends `identifier`; the web API sends `email`.
        identifier = (
            request.data.get("identifier")
            or request.data.get("email")
            or request.data.get("login_id")
            or ""
        ).strip()
        password = request.data.get("password", "")

        if not identifier or not password:
            return Response(
                {"detail": "Identifier (email or login ID) and password are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Pass the identifier directly — EmailBackend handles both email (admin)
        # and login_id (staff/student) lookup internally.
        try:
            user = authenticate(request=request, username=identifier, password=password)
        except DjangoPermissionDenied:
            return Response(
                {"detail": "Account temporarily locked. Try again later."},
                status=status.HTTP_403_FORBIDDEN,
            )

        if user is None:
            return Response(
                {"detail": "Invalid credentials."},
                status=status.HTTP_401_UNAUTHORIZED,
            )
        if not user.is_active:
            return Response(
                {"detail": "Account is disabled."},
                status=status.HTTP_403_FORBIDDEN,
            )

        refresh = RefreshToken.for_user(user)
        return Response(
            {
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "user": UserSerializer(user, context={"request": request}).data,
            }
        )


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        refresh_token = request.data.get("refresh")
        if not refresh_token:
            return Response(
                {"detail": "Refresh token required."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            RefreshToken(refresh_token).blacklist()
        except TokenError:
            return Response(
                {"detail": "Invalid or expired token."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return Response({"detail": "Logged out successfully."})


# ---------------------------------------------------------------------------
# Profile
# ---------------------------------------------------------------------------


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(MeSerializer(request.user, context={"request": request}).data)

    def patch(self, request):
        user = request.user
        # Profile picture arrives as a file upload (multipart).
        if "profile_pic" in request.FILES:
            user.profile_pic = request.FILES["profile_pic"]
        serializer = MeSerializer(
            user, data=request.data, partial=True, context={"request": request}
        )
        if serializer.is_valid():
            serializer.save()
            return Response(MeSerializer(user, context={"request": request}).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        user = request.user
        if not user.check_password(serializer.validated_data["old_password"]):
            return Response(
                {"old_password": "Incorrect password."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        user.set_password(serializer.validated_data["new_password"])
        user.save()
        return Response({"detail": "Password changed successfully."})


class FcmTokenView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = FcmTokenSerializer(data=request.data)
        if serializer.is_valid():
            request.user.fcm_token = serializer.validated_data["token"]
            request.user.save(update_fields=["fcm_token"])
            return Response({"detail": "FCM token updated."})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


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


# ---------------------------------------------------------------------------
# Attendance
# ---------------------------------------------------------------------------


class AttendanceView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        user_type = str(user.user_type)
        group_id = request.query_params.get("group_id")
        date_str = request.query_params.get("date")

        # Students get their own attendance timeline
        if user_type == "3":
            try:
                student = user.student
            except Student.DoesNotExist:
                return Response({"count": 0, "results": []})
            reports = (
                AttendanceReport.objects.filter(student=student)
                .select_related("attendance__group")
                .order_by("-attendance__date")
            )
            if group_id:
                reports = reports.filter(attendance__group_id=group_id)
            paginator = PageNumberPagination()
            paginator.page_size = 20
            page = paginator.paginate_queryset(reports, request)
            data = [
                {
                    "date": r.attendance.date,
                    "group_id": r.attendance.group_id,
                    "group_name": r.attendance.group.name if r.attendance.group else None,
                    "status": r.status,
                    "status_display": r.get_status_display(),
                }
                for r in page
            ]
            return paginator.get_paginated_response(data)

        # Admin and Teachers get full attendance records, branch-scoped.
        qs = Attendance.objects.select_related("group").prefetch_related(
            "attendancereport_set__student__admin"
        )
        qs = branching.filter_attendance_for_user(user, qs)
        if group_id:
            qs = qs.filter(group_id=group_id)
        if date_str:
            qs = qs.filter(date=date_str)
        qs = qs.order_by("-date")

        paginator = PageNumberPagination()
        paginator.page_size = 20
        page = paginator.paginate_queryset(qs, request)
        serializer = AttendanceSerializer(page, many=True, context={"request": request})
        return paginator.get_paginated_response(serializer.data)

    def post(self, request):
        if str(request.user.user_type) not in ("1", "2"):
            return Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)

        serializer = AttendanceSaveSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        group = Group.objects.get(id=data["group_id"])

        # Unified branch/ownership check: super admin (all), branch admin
        # (their branches), teacher (their groups).
        if not branching.user_can_access_group(request.user, group):
            return Response(
                {"detail": "You can only take attendance for groups in your scope."},
                status=status.HTTP_403_FORBIDDEN,
            )

        records = data["records"]
        with transaction.atomic():
            attendance, _ = Attendance.objects.get_or_create(group=group, date=data["date"])

            existing = {
                r.student_id: r for r in AttendanceReport.objects.filter(attendance=attendance)
            }
            to_create, to_update = [], []
            for rec in records:
                sid = int(rec["student_id"])
                st = int(rec["status"])
                if sid in existing:
                    existing[sid].status = st
                    to_update.append(existing[sid])
                else:
                    to_create.append(
                        AttendanceReport(attendance=attendance, student_id=sid, status=st)
                    )
            if to_create:
                AttendanceReport.objects.bulk_create(to_create)
            if to_update:
                AttendanceReport.objects.bulk_update(to_update, ["status"])

        return Response({"detail": "Attendance saved.", "attendance_id": attendance.id})


# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------


class ResultView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        group_id = request.query_params.get("group_id")

        qs = StudentResult.objects.select_related("student__admin", "group")
        qs = branching.filter_results_for_user(user, qs)

        if group_id:
            qs = qs.filter(group_id=group_id)

        paginator = PageNumberPagination()
        paginator.page_size = 20
        page = paginator.paginate_queryset(qs, request)
        serializer = StudentResultSerializer(page, many=True, context={"request": request})
        return paginator.get_paginated_response(serializer.data)

    def post(self, request):
        if str(request.user.user_type) not in ("1", "2"):
            return Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)

        student_id = request.data.get("student_id")
        group_id = request.data.get("group_id")
        if not student_id or not group_id:
            return Response(
                {"detail": "student_id and group_id are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            student = Student.objects.get(id=student_id)
            group = Group.objects.get(id=group_id)
        except (Student.DoesNotExist, Group.DoesNotExist):
            return Response(
                {"detail": "Student or group not found."}, status=status.HTTP_404_NOT_FOUND
            )

        if not branching.user_can_access_group(request.user, group):
            return Response(
                {"detail": "You can only update results for groups in your scope."},
                status=status.HTTP_403_FORBIDDEN,
            )

        result, created = StudentResult.objects.update_or_create(
            student=student,
            group=group,
            defaults={
                "test": request.data.get("test", 0),
                "exam": request.data.get("exam", 0),
                "comment": request.data.get("comment", ""),
            },
        )

        Notification.objects.create(
            recipient=student.admin,
            category=Notification.RESULT,
            message=(
                f"Your result for {group.name}: "
                f"Test={result.test}, Exam={result.exam}."
                + (f" {result.comment}" if result.comment else "")
            ),
        )

        serializer = StudentResultSerializer(result, context={"request": request})
        return Response(
            serializer.data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


# ---------------------------------------------------------------------------
# Assignments
# ---------------------------------------------------------------------------


class AssignmentListView(APIView):
    permission_classes = [IsAuthenticated]

    def _queryset(self, user):
        user_type = str(user.user_type)
        qs = Assignment.objects.select_related("group", "created_by__admin")
        if user_type == "1":
            if branching.is_super_admin(user):
                return qs
            ids = list(branching.get_accessible_branches(user).values_list("id", flat=True))
            return qs.filter(group__branch_id__in=ids)
        if user_type == "2":
            try:
                return qs.filter(created_by=user.staff)
            except Staff.DoesNotExist:
                return qs.none()
        if user_type == "3":
            try:
                ids = Enrollment.objects.filter(
                    student=user.student,
                    is_active=True,
                ).values_list("group_id", flat=True)
                return qs.filter(group_id__in=ids)
            except Student.DoesNotExist:
                return qs.none()
        return qs.none()

    def get(self, request):
        qs = self._queryset(request.user).order_by("-created_at")
        paginator = PageNumberPagination()
        paginator.page_size = 20
        page = paginator.paginate_queryset(qs, request)
        serializer = AssignmentSerializer(page, many=True, context={"request": request})
        return paginator.get_paginated_response(serializer.data)

    def post(self, request):
        if str(request.user.user_type) not in ("1", "2"):
            return Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)
        try:
            staff = request.user.staff
        except Staff.DoesNotExist:
            return Response(
                {"detail": "Staff profile not found."}, status=status.HTTP_403_FORBIDDEN
            )

        serializer = AssignmentSerializer(data=request.data, context={"request": request})
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        assignment = serializer.save(created_by=staff)
        return Response(
            AssignmentSerializer(assignment, context={"request": request}).data,
            status=status.HTTP_201_CREATED,
        )


class AssignmentDetailView(generics.RetrieveAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = AssignmentDetailSerializer

    def get_queryset(self):
        user = self.request.user
        user_type = str(user.user_type)
        qs = Assignment.objects.select_related("group", "created_by__admin")
        if user_type == "1":
            if branching.is_super_admin(user):
                return qs
            ids = list(branching.get_accessible_branches(user).values_list("id", flat=True))
            return qs.filter(group__branch_id__in=ids)
        if user_type == "2":
            try:
                return qs.filter(created_by=user.staff)
            except Staff.DoesNotExist:
                return qs.none()
        if user_type == "3":
            try:
                ids = Enrollment.objects.filter(
                    student=user.student,
                    is_active=True,
                ).values_list("group_id", flat=True)
                return qs.filter(group_id__in=ids)
            except Student.DoesNotExist:
                return qs.none()
        return qs.none()


class SubmitAssignmentView(APIView):
    permission_classes = [IsStudent]

    def post(self, request, pk):
        try:
            assignment = Assignment.objects.get(pk=pk)
        except Assignment.DoesNotExist:
            return Response({"detail": "Assignment not found."}, status=status.HTTP_404_NOT_FOUND)

        try:
            student = request.user.student
        except Student.DoesNotExist:
            return Response(
                {"detail": "Student profile not found."}, status=status.HTTP_403_FORBIDDEN
            )

        if not Enrollment.objects.filter(
            student=student, group=assignment.group, is_active=True
        ).exists():
            return Response(
                {"detail": "You are not enrolled in this group."}, status=status.HTTP_403_FORBIDDEN
            )

        serializer = SubmitAssignmentSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        submission, created = Submission.objects.update_or_create(
            assignment=assignment,
            student=student,
            defaults={
                "file": serializer.validated_data.get("file"),
                "note": serializer.validated_data.get("note", ""),
            },
        )
        return Response(
            SubmissionSerializer(submission, context={"request": request}).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


# ---------------------------------------------------------------------------
# Notifications
# ---------------------------------------------------------------------------


class NotificationListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = NotificationSerializer

    def get_queryset(self):
        qs = Notification.objects.filter(recipient=self.request.user)
        category = self.request.query_params.get("category")
        if category:
            qs = qs.filter(category=category)
        if self.request.query_params.get("unread") == "1":
            qs = qs.filter(is_read=False)
        return qs


class NotificationReadView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        updated = Notification.objects.filter(pk=pk, recipient=request.user).update(is_read=True)
        if not updated:
            return Response({"detail": "Notification not found."}, status=status.HTTP_404_NOT_FOUND)
        return Response({"detail": "Marked as read."})


class NotificationMarkAllReadView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        Notification.objects.filter(recipient=request.user, is_read=False).update(is_read=True)
        return Response({"detail": "All notifications marked as read."})


# ---------------------------------------------------------------------------
# File upload (result files)
# ---------------------------------------------------------------------------


class FileUploadView(APIView):
    permission_classes = [IsAdminOrTeacher]

    def post(self, request):
        file_obj = request.FILES.get("file")
        if not file_obj:
            return Response({"detail": "No file provided."}, status=status.HTTP_400_BAD_REQUEST)

        group_id = request.data.get("group_id")
        if not group_id:
            return Response({"detail": "group_id is required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            group = Group.objects.get(id=group_id)
        except Group.DoesNotExist:
            return Response({"detail": "Group not found."}, status=status.HTTP_404_NOT_FOUND)

        # Admins may upload to any group; teachers only to their own groups.
        user_type = str(request.user.user_type)
        if user_type == "2":
            try:
                staff = request.user.staff
            except Staff.DoesNotExist:
                return Response(
                    {"detail": "Staff profile not found."}, status=status.HTTP_403_FORBIDDEN
                )
            if group.teacher_id != staff.id:
                return Response(
                    {"detail": "You are not the teacher of this group."},
                    status=status.HTTP_403_FORBIDDEN,
                )
        else:
            staff = None

        student_id = request.data.get("student_id")
        student = None
        if student_id:
            try:
                student = Student.objects.get(id=student_id)
            except Student.DoesNotExist:
                return Response({"detail": "Student not found."}, status=status.HTTP_404_NOT_FOUND)
            # Verify the student is enrolled in this group.
            if not Enrollment.objects.filter(student=student, group=group, is_active=True).exists():
                return Response(
                    {"detail": "Student is not enrolled in this group."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        title = request.data.get("title", file_obj.name)
        description = request.data.get("description", "")

        result_file = ResultFile.objects.create(
            group=group,
            student=student,
            file=file_obj,
            title=title,
            description=description,
            uploaded_by=staff,
        )

        if student:
            Notification.objects.create(
                recipient=student.admin,
                category=Notification.RESULT,
                message=f"New result file: {title}",
            )

        return Response(
            {
                "id": result_file.id,
                "title": result_file.title,
                "file_url": request.build_absolute_uri(result_file.file.url),
                "uploaded_at": result_file.uploaded_at,
            },
            status=status.HTTP_201_CREATED,
        )


# ---------------------------------------------------------------------------
# Admin endpoints
# ---------------------------------------------------------------------------


class AdminStatsView(APIView):
    permission_classes = [IsAdmin]

    def get(self, request):
        user = request.user
        students = branching.filter_students_for_user(user, Student.objects.all())
        staff = branching.filter_staff_for_user(user, Staff.objects.all())
        groups = branching.filter_groups_for_user(user, Group.objects.all())
        return Response(
            {
                "student_count": students.count(),
                "active_students": students.filter(status="active").count(),
                "staff_count": staff.count(),
                "group_count": groups.filter(is_archived=False).count(),
                "archived_groups": groups.filter(is_archived=True).count(),
                "course_count": Course.objects.filter(is_active=True).count(),
            }
        )


class AdminUserListView(generics.ListAPIView):
    permission_classes = [IsAdmin]
    serializer_class = UserSerializer

    def get_queryset(self):
        qs = CustomUser.objects.all()
        # Branch admins only see users (students/teachers) within their branches.
        if not branching.is_super_admin(self.request.user):
            allowed_students = branching.filter_students_for_user(
                self.request.user, Student.objects.all()
            )
            allowed_staff = branching.filter_staff_for_user(
                self.request.user, Staff.objects.all()
            )
            qs = qs.filter(Q(student__in=allowed_students) | Q(staff__in=allowed_staff))
        user_type = self.request.query_params.get("user_type")
        if user_type:
            qs = qs.filter(user_type=user_type)
        search = self.request.query_params.get("search")
        if search:
            qs = qs.filter(
                Q(first_name__icontains=search)
                | Q(last_name__icontains=search)
                | Q(email__icontains=search)
            )
        return qs.order_by("-date_joined")


class AdminGroupListView(generics.ListAPIView):
    permission_classes = [IsAdmin]
    serializer_class = GroupSerializer

    def get_queryset(self):
        qs = Group.objects.select_related("course", "teacher__admin", "branch")
        if self.request.query_params.get("archived") != "1":
            qs = qs.filter(is_archived=False)
        return branching.filter_groups_for_user(self.request.user, qs)


class AdminEnrollmentView(APIView):
    permission_classes = [IsAdmin]

    def post(self, request):
        serializer = EnrollmentSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        student = serializer.validated_data["student"]
        group = serializer.validated_data["group"]

        # Branch admins can only enrol within their branches and not across
        # a branch boundary (super admin may override a mismatch).
        if not branching.user_can_access_group(request.user, group):
            return Response(
                {"detail": "You don't have access to that group's branch."},
                status=status.HTTP_403_FORBIDDEN,
            )
        if (
            not branching.is_super_admin(request.user)
            and group.branch_id
            and student.branch_id
            and group.branch_id != student.branch_id
        ):
            return Response(
                {"detail": "Student belongs to a different branch than the group."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        enrollment, created = Enrollment.objects.get_or_create(
            student=student, group=group, defaults={"is_active": True}
        )
        if not created and not enrollment.is_active:
            enrollment.is_active = True
            enrollment.save(update_fields=["is_active"])

        return Response(
            EnrollmentSerializer(enrollment).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )

    def delete(self, request):
        student_id = request.data.get("student")
        group_id = request.data.get("group")
        scoped = branching.filter_enrollments_for_user(request.user, Enrollment.objects.all())
        updated = scoped.filter(
            student_id=student_id,
            group_id=group_id,
        ).update(is_active=False)
        if not updated:
            return Response({"detail": "Enrollment not found."}, status=status.HTTP_404_NOT_FOUND)
        return Response({"detail": "Student unenrolled."})


# ---------------------------------------------------------------------------
# Staff dashboard stats
# ---------------------------------------------------------------------------


class StudentDashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if str(user.user_type) != "3":
            return Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)

        try:
            student = user.student
        except Student.DoesNotExist:
            return Response({
                "attendance_percentage": None, "total_subjects": 0,
                "average_score": None, "enrolled_groups": 0, "notices": [],
            })

        # Attendance percentage
        reports = AttendanceReport.objects.filter(student=student)
        total = reports.count()
        present = reports.filter(status=AttendanceReport.PRESENT).count()
        att_pct = round(present / total * 100, 1) if total > 0 else None

        # Enrolled groups + distinct subjects
        enrollments = Enrollment.objects.filter(
            student=student, is_active=True
        ).select_related("group__course")
        enrolled_count = enrollments.count()
        course_ids = {e.group.course_id for e in enrollments if e.group.course_id}
        total_subjects = len(course_ids) if course_ids else enrolled_count

        # Average score (test + exam out of 100)
        results = StudentResult.objects.filter(student=student)
        scores = [r.test + r.exam for r in results]
        avg_score = round(sum(scores) / len(scores), 1) if scores else None

        # Recent notices
        notifications = Notification.objects.filter(
            recipient=user
        ).order_by("-created_at")[:5]
        notices = [
            {"title": n.get_category_display(), "message": n.message}
            for n in notifications
        ]

        # Active stories for student's groups
        enrolled_group_ids = [e.group_id for e in enrollments]
        from django.utils import timezone as tz
        now = tz.now()
        stories_qs = DashboardStory.objects.filter(
            is_active=True
        ).filter(
            models.Q(expires_at__isnull=True) | models.Q(expires_at__gt=now)
        ).order_by("-created_at")[:20]
        stories_out = []
        for s in stories_qs:
            target_ids = list(s.target_groups.values_list("id", flat=True))
            if not target_ids or any(gid in target_ids for gid in enrolled_group_ids):
                stories_out.append({
                    "id": s.id,
                    "title": s.title,
                    "content": s.body,
                    "author_name": s.created_by.get_full_name() if s.created_by else "",
                })

        return Response({
            "attendance_percentage": att_pct,
            "total_subjects": total_subjects,
            "average_score": avg_score,
            "enrolled_groups": enrolled_count,
            "notices": notices,
            "stories": stories_out,
        })


class AdminDashboardView(APIView):
    permission_classes = [IsAdmin]

    def get(self, request):
        user = request.user
        students = branching.filter_students_for_user(user, Student.objects.all())
        staff    = branching.filter_staff_for_user(user, Staff.objects.all())
        groups   = branching.filter_groups_for_user(
            user, Group.objects.filter(is_archived=False)
        )
        group_ids = list(groups.values_list("id", flat=True))

        # Avg attendance across all scoped groups
        total_reports   = AttendanceReport.objects.filter(
            attendance__group_id__in=group_ids
        ).count()
        present_reports = AttendanceReport.objects.filter(
            attendance__group_id__in=group_ids,
            status=AttendanceReport.PRESENT,
        ).count()
        avg_att = round(present_reports / total_reports * 100, 1) if total_reports else None

        leads          = RegistrationLead.objects.all()
        total_branches = Branch.objects.count()

        return Response({
            "total_students":  students.count(),
            "total_staff":     staff.count(),
            "total_groups":    groups.count(),
            "avg_attendance":  avg_att,
            "new_leads":       leads.count(),
            "total_leads":     leads.count(),
            "total_branches":  total_branches,
        })


class StaffStatsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        import datetime
        user = request.user
        user_type = str(user.user_type)
        today = datetime.date.today()

        if user_type == "2":
            try:
                staff = user.staff
            except Staff.DoesNotExist:
                return Response({
                    "total_students": 0, "total_groups": 0,
                    "sessions_today": 0, "avg_attendance": None,
                })
            groups = Group.objects.filter(teacher=staff, is_archived=False)
            group_ids = list(groups.values_list("id", flat=True))
            student_ids = Enrollment.objects.filter(
                group_id__in=group_ids, is_active=True
            ).values_list("student_id", flat=True).distinct()
            sessions_today = Attendance.objects.filter(
                group_id__in=group_ids, date=today
            ).count()
            total_reports = AttendanceReport.objects.filter(
                attendance__group_id__in=group_ids
            ).count()
            present_reports = AttendanceReport.objects.filter(
                attendance__group_id__in=group_ids,
                status=AttendanceReport.PRESENT,
            ).count()
            avg_att = round(present_reports / total_reports * 100, 1) if total_reports else None
            return Response({
                "total_students": len(set(student_ids)),
                "total_groups": groups.count(),
                "sessions_today": sessions_today,
                "avg_attendance": avg_att,
            })

        # Admin sees branch-scoped totals
        if user_type == "1":
            students = branching.filter_students_for_user(user, Student.objects.all())
            groups = branching.filter_groups_for_user(
                user, Group.objects.filter(is_archived=False)
            )
            group_ids = list(groups.values_list("id", flat=True))
            sessions_today = Attendance.objects.filter(
                group_id__in=group_ids, date=today
            ).count()
            total_reports = AttendanceReport.objects.filter(
                attendance__group_id__in=group_ids
            ).count()
            present_reports = AttendanceReport.objects.filter(
                attendance__group_id__in=group_ids,
                status=AttendanceReport.PRESENT,
            ).count()
            avg_att = round(present_reports / total_reports * 100, 1) if total_reports else None
            return Response({
                "total_students": students.count(),
                "total_groups": groups.count(),
                "sessions_today": sessions_today,
                "avg_attendance": avg_att,
            })

        return Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)


# ---------------------------------------------------------------------------
# Leave  (GET/POST for the logged-in user; admin PATCH to approve/reject)
# ---------------------------------------------------------------------------


class LeaveView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        user_type = str(user.user_type)

        if user_type == "3":
            try:
                qs = LeaveReportStudent.objects.filter(student=user.student).order_by("-created_at")
            except Student.DoesNotExist:
                return Response({"count": 0, "results": []})
            paginator = PageNumberPagination()
            paginator.page_size = 20
            page = paginator.paginate_queryset(qs, request)
            return paginator.get_paginated_response(
                StudentLeaveSerializer(page, many=True).data
            )

        if user_type == "2":
            try:
                qs = LeaveReportStaff.objects.filter(staff=user.staff).order_by("-created_at")
            except Staff.DoesNotExist:
                return Response({"count": 0, "results": []})
            paginator = PageNumberPagination()
            paginator.page_size = 20
            page = paginator.paginate_queryset(qs, request)
            return paginator.get_paginated_response(
                StaffLeaveSerializer(page, many=True).data
            )

        # Admin: return combined leave from both students and staff with optional filters
        if user_type == "1":
            leave_type = request.query_params.get("type", "student")
            status_filter = request.query_params.get("status")
            paginator = PageNumberPagination()
            paginator.page_size = 20

            if leave_type == "staff":
                qs = LeaveReportStaff.objects.select_related("staff__admin").order_by("-created_at")
                qs = branching.filter_staff_leave_for_user(user, qs) if hasattr(
                    branching, "filter_staff_leave_for_user"
                ) else qs
                if status_filter is not None:
                    qs = qs.filter(status=status_filter)
                page = paginator.paginate_queryset(qs, request)
                return paginator.get_paginated_response(
                    AdminStaffLeaveSerializer(page, many=True).data
                )
            else:
                qs = LeaveReportStudent.objects.select_related("student__admin").order_by("-created_at")
                if status_filter is not None:
                    qs = qs.filter(status=status_filter)
                page = paginator.paginate_queryset(qs, request)
                return paginator.get_paginated_response(
                    AdminStudentLeaveSerializer(page, many=True).data
                )

        return Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)

    def post(self, request):
        user = request.user
        user_type = str(user.user_type)

        if user_type == "3":
            try:
                student = user.student
            except Student.DoesNotExist:
                return Response({"detail": "Student profile not found."}, status=status.HTTP_403_FORBIDDEN)
            serializer = StudentLeaveSerializer(data=request.data)
            if not serializer.is_valid():
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            leave = serializer.save(student=student)
            return Response(StudentLeaveSerializer(leave).data, status=status.HTTP_201_CREATED)

        if user_type == "2":
            try:
                staff = user.staff
            except Staff.DoesNotExist:
                return Response({"detail": "Staff profile not found."}, status=status.HTTP_403_FORBIDDEN)
            serializer = StaffLeaveSerializer(data=request.data)
            if not serializer.is_valid():
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            leave = serializer.save(staff=staff)
            return Response(StaffLeaveSerializer(leave).data, status=status.HTTP_201_CREATED)

        return Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)


class LeaveDetailView(APIView):
    """Admin: PATCH to approve (status=1) or reject (status=-1)."""
    permission_classes = [IsAdmin]

    def patch(self, request, pk):
        leave_type = request.query_params.get("type", "student")
        new_status = request.data.get("status")

        if new_status not in (1, -1, "1", "-1"):
            return Response(
                {"detail": "status must be 1 (approved) or -1 (rejected)."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        new_status = int(new_status)

        if leave_type == "staff":
            try:
                leave = LeaveReportStaff.objects.get(pk=pk)
            except LeaveReportStaff.DoesNotExist:
                return Response({"detail": "Leave not found."}, status=status.HTTP_404_NOT_FOUND)
            leave.status = new_status
            leave.save(update_fields=["status", "updated_at"])
            return Response(AdminStaffLeaveSerializer(leave).data)
        else:
            try:
                leave = LeaveReportStudent.objects.get(pk=pk)
            except LeaveReportStudent.DoesNotExist:
                return Response({"detail": "Leave not found."}, status=status.HTTP_404_NOT_FOUND)
            leave.status = new_status
            leave.save(update_fields=["status", "updated_at"])
            return Response(AdminStudentLeaveSerializer(leave).data)


# ---------------------------------------------------------------------------
# Feedback  (GET/POST for the logged-in user; admin PATCH to reply)
# ---------------------------------------------------------------------------


class FeedbackView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        user_type = str(user.user_type)
        paginator = PageNumberPagination()
        paginator.page_size = 20

        if user_type == "3":
            try:
                qs = FeedbackStudent.objects.filter(student=user.student).order_by("-created_at")
            except Student.DoesNotExist:
                return Response({"count": 0, "results": []})
            page = paginator.paginate_queryset(qs, request)
            return paginator.get_paginated_response(StudentFeedbackSerializer(page, many=True).data)

        if user_type == "2":
            try:
                qs = FeedbackStaff.objects.filter(staff=user.staff).order_by("-created_at")
            except Staff.DoesNotExist:
                return Response({"count": 0, "results": []})
            page = paginator.paginate_queryset(qs, request)
            return paginator.get_paginated_response(StaffFeedbackSerializer(page, many=True).data)

        if user_type == "1":
            feedback_type = request.query_params.get("type", "student")
            if feedback_type == "staff":
                qs = FeedbackStaff.objects.select_related("staff__admin").order_by("-created_at")
                page = paginator.paginate_queryset(qs, request)
                return paginator.get_paginated_response(
                    AdminStaffFeedbackSerializer(page, many=True).data
                )
            else:
                qs = FeedbackStudent.objects.select_related("student__admin").order_by("-created_at")
                page = paginator.paginate_queryset(qs, request)
                return paginator.get_paginated_response(
                    AdminStudentFeedbackSerializer(page, many=True).data
                )

        return Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)

    def post(self, request):
        user = request.user
        user_type = str(user.user_type)

        if user_type == "3":
            try:
                student = user.student
            except Student.DoesNotExist:
                return Response({"detail": "Student profile not found."}, status=status.HTTP_403_FORBIDDEN)
            text = request.data.get("feedback", "").strip()
            if not text:
                return Response({"feedback": "This field is required."}, status=status.HTTP_400_BAD_REQUEST)
            fb = FeedbackStudent.objects.create(student=student, feedback=text)
            return Response(StudentFeedbackSerializer(fb).data, status=status.HTTP_201_CREATED)

        if user_type == "2":
            try:
                staff = user.staff
            except Staff.DoesNotExist:
                return Response({"detail": "Staff profile not found."}, status=status.HTTP_403_FORBIDDEN)
            text = request.data.get("feedback", "").strip()
            if not text:
                return Response({"feedback": "This field is required."}, status=status.HTTP_400_BAD_REQUEST)
            fb = FeedbackStaff.objects.create(staff=staff, feedback=text)
            return Response(StaffFeedbackSerializer(fb).data, status=status.HTTP_201_CREATED)

        return Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)


class FeedbackDetailView(APIView):
    """Admin: PATCH to add a reply."""
    permission_classes = [IsAdmin]

    def patch(self, request, pk):
        feedback_type = request.query_params.get("type", "student")
        reply = request.data.get("reply", "").strip()
        if not reply:
            return Response({"reply": "Reply text is required."}, status=status.HTTP_400_BAD_REQUEST)

        if feedback_type == "staff":
            try:
                fb = FeedbackStaff.objects.get(pk=pk)
            except FeedbackStaff.DoesNotExist:
                return Response({"detail": "Feedback not found."}, status=status.HTTP_404_NOT_FOUND)
            fb.reply = reply
            fb.save(update_fields=["reply", "updated_at"])
            return Response(AdminStaffFeedbackSerializer(fb).data)
        else:
            try:
                fb = FeedbackStudent.objects.get(pk=pk)
            except FeedbackStudent.DoesNotExist:
                return Response({"detail": "Feedback not found."}, status=status.HTTP_404_NOT_FOUND)
            fb.reply = reply
            fb.save(update_fields=["reply", "updated_at"])
            return Response(AdminStudentFeedbackSerializer(fb).data)


# ---------------------------------------------------------------------------
# Invoices (student: own invoices; admin: all)
# ---------------------------------------------------------------------------


class InvoiceView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = InvoiceSerializer

    def get_queryset(self):
        user = self.request.user
        user_type = str(user.user_type)
        qs = Invoice.objects.prefetch_related("payments").select_related("group")
        if user_type == "3":
            try:
                return qs.filter(student=user.student).order_by("-period")
            except Student.DoesNotExist:
                return qs.none()
        if user_type == "1":
            students = branching.filter_students_for_user(user, Student.objects.all())
            return qs.filter(student__in=students).order_by("-period")
        return qs.none()


class InvoiceDetailView(generics.RetrieveAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = InvoiceSerializer

    def get_queryset(self):
        user = self.request.user
        user_type = str(user.user_type)
        qs = Invoice.objects.prefetch_related("payments").select_related("group")
        if user_type == "3":
            try:
                return qs.filter(student=user.student)
            except Student.DoesNotExist:
                return qs.none()
        if user_type == "1":
            students = branching.filter_students_for_user(user, Student.objects.all())
            return qs.filter(student__in=students)
        return qs.none()


# ---------------------------------------------------------------------------
# Admin: Registration leads
# ---------------------------------------------------------------------------


class AdminLeadListView(APIView):
    permission_classes = [IsAdmin]

    def get(self, request):
        qs = RegistrationLead.objects.order_by("-created_at")
        status_filter = request.query_params.get("status")
        search = request.query_params.get("search")
        if status_filter:
            qs = qs.filter(status=status_filter)
        if search:
            qs = qs.filter(
                Q(full_name__icontains=search)
                | Q(first_name__icontains=search)
                | Q(last_name__icontains=search)
                | Q(phone__icontains=search)
                | Q(email__icontains=search)
            )
        paginator = PageNumberPagination()
        paginator.page_size = 30
        page = paginator.paginate_queryset(qs, request)
        return paginator.get_paginated_response(RegistrationLeadSerializer(page, many=True).data)

    def post(self, request):
        serializer = RegistrationLeadSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        lead = serializer.save()
        return Response(RegistrationLeadSerializer(lead).data, status=status.HTTP_201_CREATED)


class AdminLeadDetailView(APIView):
    permission_classes = [IsAdmin]

    def get(self, request, pk):
        try:
            lead = RegistrationLead.objects.get(pk=pk)
        except RegistrationLead.DoesNotExist:
            return Response({"detail": "Lead not found."}, status=status.HTTP_404_NOT_FOUND)
        return Response(RegistrationLeadSerializer(lead).data)

    def patch(self, request, pk):
        try:
            lead = RegistrationLead.objects.get(pk=pk)
        except RegistrationLead.DoesNotExist:
            return Response({"detail": "Lead not found."}, status=status.HTTP_404_NOT_FOUND)
        serializer = RegistrationLeadSerializer(lead, data=request.data, partial=True)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        serializer.save()
        return Response(serializer.data)


# ---------------------------------------------------------------------------
# Admin: Student management
# ---------------------------------------------------------------------------


class AdminStudentListView(generics.ListAPIView):
    permission_classes = [IsAdmin]
    serializer_class = AdminStudentSerializer

    def get_queryset(self):
        qs = Student.objects.select_related("admin", "course", "branch")
        qs = branching.filter_students_for_user(self.request.user, qs)
        search = self.request.query_params.get("search")
        status_filter = self.request.query_params.get("status")
        if status_filter:
            qs = qs.filter(status=status_filter)
        if search:
            qs = qs.filter(
                Q(admin__first_name__icontains=search)
                | Q(admin__last_name__icontains=search)
                | Q(admin__email__icontains=search)
                | Q(admin__login_id__icontains=search)
                | Q(phone__icontains=search)
            )
        return qs.order_by("admin__first_name")

    @transaction.atomic
    def post(self, request):
        """Create a new student account."""
        from ..hod_views import _generate_login_id
        import datetime

        data = request.data
        first_name = data.get("first_name", "").strip()
        last_name = data.get("last_name", "").strip()
        password = data.get("password", "").strip()
        phone = data.get("phone", "").strip()
        gender = data.get("gender", "M")
        address = data.get("address", "").strip()
        course_id = data.get("course")
        branch_id = data.get("branch")
        status_val = data.get("status", Student.STATUS_ACTIVE)
        level = data.get("level")
        dob_str = data.get("date_of_birth", "")

        if not first_name or not password:
            return Response(
                {"detail": "first_name and password are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        dob = None
        if dob_str:
            try:
                dob = datetime.date.fromisoformat(dob_str)
            except ValueError:
                return Response(
                    {"detail": "Invalid date_of_birth format. Use YYYY-MM-DD."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        login_id = _generate_login_id("IC", dob)
        email = f"{login_id.lower()}@iceberg.internal"

        user = CustomUser.objects.create_user(
            email=email,
            password=password,
            user_type=3,
            first_name=first_name,
            last_name=last_name,
            login_id=login_id,
        )
        user.gender = gender
        user.address = address
        user.date_of_birth = dob
        user.save()

        student = user.student
        if course_id:
            from ..models import Course as CourseModel
            try:
                student.course = CourseModel.objects.get(pk=course_id)
            except CourseModel.DoesNotExist:
                pass
        if branch_id:
            try:
                student.branch = Branch.objects.get(pk=branch_id)
            except Branch.DoesNotExist:
                pass
        student.phone = phone
        student.status = status_val
        student.level = int(level) if level else None
        student.save()

        return Response(
            AdminStudentSerializer(student, context={"request": request}).data,
            status=status.HTTP_201_CREATED,
        )


class AdminStudentDetailView(APIView):
    permission_classes = [IsAdmin]

    def _get_student(self, request, pk):
        try:
            student = Student.objects.select_related("admin", "course", "branch").get(pk=pk)
        except Student.DoesNotExist:
            return None, Response({"detail": "Student not found."}, status=status.HTTP_404_NOT_FOUND)
        if not branching.is_super_admin(request.user):
            allowed = branching.filter_students_for_user(request.user, Student.objects.all())
            if not allowed.filter(pk=pk).exists():
                return None, Response({"detail": "Access denied."}, status=status.HTTP_403_FORBIDDEN)
        return student, None

    def get(self, request, pk):
        student, err = self._get_student(request, pk)
        if err:
            return err
        return Response(AdminStudentSerializer(student, context={"request": request}).data)

    def patch(self, request, pk):
        student, err = self._get_student(request, pk)
        if err:
            return err
        serializer = AdminStudentSerializer(
            student, data=request.data, partial=True, context={"request": request}
        )
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        serializer.save()
        return Response(serializer.data)


# ---------------------------------------------------------------------------
# Admin: Staff management
# ---------------------------------------------------------------------------


class AdminStaffListView(generics.ListAPIView):
    permission_classes = [IsAdmin]
    serializer_class = AdminStaffSerializer

    def get_queryset(self):
        qs = Staff.objects.select_related("admin", "course", "branch")
        qs = branching.filter_staff_for_user(self.request.user, qs)
        search = self.request.query_params.get("search")
        active_filter = self.request.query_params.get("is_active")
        if active_filter is not None:
            qs = qs.filter(is_active=(active_filter == "1"))
        if search:
            qs = qs.filter(
                Q(admin__first_name__icontains=search)
                | Q(admin__last_name__icontains=search)
                | Q(admin__email__icontains=search)
                | Q(admin__login_id__icontains=search)
                | Q(phone__icontains=search)
            )
        return qs.order_by("admin__first_name")

    @transaction.atomic
    def post(self, request):
        """Create a new staff account."""
        from ..hod_views import _generate_login_id
        import datetime

        data = request.data
        first_name = data.get("first_name", "").strip()
        last_name = data.get("last_name", "").strip()
        password = data.get("password", "").strip()
        phone = data.get("phone", "").strip()
        specialization = data.get("specialization", "").strip()
        gender = data.get("gender", "M")
        course_id = data.get("course")
        branch_id = data.get("branch")
        dob_str = data.get("date_of_birth", "")

        if not first_name or not password:
            return Response(
                {"detail": "first_name and password are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        dob = None
        if dob_str:
            try:
                dob = datetime.date.fromisoformat(dob_str)
            except ValueError:
                return Response(
                    {"detail": "Invalid date_of_birth format. Use YYYY-MM-DD."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        login_id = _generate_login_id("TC", dob)
        email = f"{login_id.lower()}@iceberg.internal"

        user = CustomUser.objects.create_user(
            email=email,
            password=password,
            user_type=2,
            first_name=first_name,
            last_name=last_name,
            login_id=login_id,
        )
        user.gender = gender
        user.date_of_birth = dob
        user.save()

        staff = user.staff
        if course_id:
            from ..models import Course as CourseModel
            try:
                staff.course = CourseModel.objects.get(pk=course_id)
            except CourseModel.DoesNotExist:
                pass
        if branch_id:
            try:
                staff.branch = Branch.objects.get(pk=branch_id)
            except Branch.DoesNotExist:
                pass
        staff.phone = phone
        staff.specialization = specialization
        staff.save()

        return Response(
            AdminStaffSerializer(staff, context={"request": request}).data,
            status=status.HTTP_201_CREATED,
        )


class AdminStaffDetailView(APIView):
    permission_classes = [IsAdmin]

    def _get_staff(self, request, pk):
        try:
            staff = Staff.objects.select_related("admin", "course", "branch").get(pk=pk)
        except Staff.DoesNotExist:
            return None, Response({"detail": "Staff not found."}, status=status.HTTP_404_NOT_FOUND)
        if not branching.is_super_admin(request.user):
            allowed = branching.filter_staff_for_user(request.user, Staff.objects.all())
            if not allowed.filter(pk=pk).exists():
                return None, Response({"detail": "Access denied."}, status=status.HTTP_403_FORBIDDEN)
        return staff, None

    def get(self, request, pk):
        staff, err = self._get_staff(request, pk)
        if err:
            return err
        return Response(AdminStaffSerializer(staff, context={"request": request}).data)

    def patch(self, request, pk):
        staff, err = self._get_staff(request, pk)
        if err:
            return err
        serializer = AdminStaffSerializer(
            staff, data=request.data, partial=True, context={"request": request}
        )
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        serializer.save()
        return Response(serializer.data)


# ---------------------------------------------------------------------------
# Vocabulary
# ---------------------------------------------------------------------------


class VocabularyDayListView(generics.ListAPIView):
    """Student: list released vocabulary days for their enrolled groups."""
    permission_classes = [IsAuthenticated]
    serializer_class = None  # set below after serializer import

    def get_serializer_class(self):
        from .serializers import VocabularyDaySerializer
        return VocabularyDaySerializer

    def get_queryset(self):
        from django.utils import timezone as tz
        user = self.request.user
        try:
            student = user.student
        except Exception:
            return VocabularyDay.objects.none()
        enrolled_groups = Group.objects.filter(enrollments__student=student)
        return (
            VocabularyDay.objects
            .filter(group__in=enrolled_groups, release_at__lte=tz.now())
            .prefetch_related("words")
            .select_related("group")
            .order_by("group", "day_number")
        )


class VocabularyDayDetailView(APIView):
    """Student: get full words for one vocabulary day."""
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        from .serializers import VocabularyDaySerializer
        from django.utils import timezone as tz
        try:
            student = request.user.student
        except Exception:
            return Response({"detail": "Students only."}, status=status.HTTP_403_FORBIDDEN)
        try:
            day = VocabularyDay.objects.prefetch_related("words").select_related("group").get(pk=pk)
        except VocabularyDay.DoesNotExist:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)
        if not day.is_released:
            return Response({"detail": "Not released yet."}, status=status.HTTP_403_FORBIDDEN)
        enrolled = Group.objects.filter(enrollments__student=student, pk=day.group_id).exists()
        if not enrolled:
            return Response({"detail": "Access denied."}, status=status.HTTP_403_FORBIDDEN)
        return Response(VocabularyDaySerializer(day, context={"request": request}).data)


class VocabularyDayCompleteView(APIView):
    """Student: mark a vocabulary day as completed."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            student = request.user.student
        except Exception:
            return Response({"detail": "Students only."}, status=status.HTTP_403_FORBIDDEN)
        try:
            day = VocabularyDay.objects.get(pk=pk)
        except VocabularyDay.DoesNotExist:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)
        enrolled = Group.objects.filter(enrollments__student=student, pk=day.group_id).exists()
        if not enrolled:
            return Response({"detail": "Access denied."}, status=status.HTTP_403_FORBIDDEN)
        VocabularyDayCompletion.objects.get_or_create(student=student, day=day)
        return Response({"status": "completed"})


# ---------------------------------------------------------------------------
# Leaderboard
# ---------------------------------------------------------------------------


class LeaderboardView(APIView):
    """Return the active season leaderboard (or a specified season by ?season_id=)."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from .serializers import LeaderboardSeasonSerializer
        season_id = request.query_params.get("season_id")
        if season_id:
            try:
                season = LeaderboardSeason.objects.get(pk=season_id)
            except LeaderboardSeason.DoesNotExist:
                return Response({"detail": "Season not found."}, status=status.HTTP_404_NOT_FOUND)
        else:
            season = LeaderboardSeason.objects.filter(is_active=True).order_by("-start_date").first()
            if not season:
                return Response({"detail": "No active leaderboard season."}, status=status.HTTP_404_NOT_FOUND)
        data = LeaderboardSeasonSerializer(season, context={"request": request}).data
        return Response(data)


# ---------------------------------------------------------------------------
# Admin: Branches (superadmin)
# ---------------------------------------------------------------------------


class AdminBranchListView(generics.ListAPIView):
    """Superadmin: list all branches; branch-admin: list own branches."""
    permission_classes = [IsAdmin]

    def get_serializer_class(self):
        from .serializers import BranchSerializer
        return BranchSerializer

    def get_queryset(self):
        return branching.get_accessible_branches(self.request.user)


# ---------------------------------------------------------------------------
# Vocabulary Quiz
# ---------------------------------------------------------------------------

import random as _random


class VocabularyQuizView(APIView):
    """Student: generate shuffled MCQ quiz for a vocabulary day."""
    permission_classes = [IsStudent]

    def get(self, request, pk):
        from django.utils import timezone as tz
        try:
            student = request.user.student
        except Student.DoesNotExist:
            return Response({"detail": "Student profile not found."}, status=status.HTTP_403_FORBIDDEN)

        try:
            day = VocabularyDay.objects.prefetch_related("words").select_related("group").get(pk=pk)
        except VocabularyDay.DoesNotExist:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)

        if not day.is_released:
            return Response({"detail": "Not released yet."}, status=status.HTTP_403_FORBIDDEN)

        enrolled = Enrollment.objects.filter(student=student, group=day.group, is_active=True).exists()
        if day.release_scope != VocabularyDay.SCOPE_ALL and not enrolled:
            return Response({"detail": "Access denied."}, status=status.HTTP_403_FORBIDDEN)

        all_words = list(day.words.all())
        if len(all_words) < 2:
            return Response({"detail": "Need at least 2 words for a quiz."}, status=status.HTTP_400_BAD_REQUEST)

        questions = []
        for w in all_words:
            distractors = _random.sample(
                [x for x in all_words if x.id != w.id], min(3, len(all_words) - 1)
            )
            choices = [{"id": w.id, "word": w.word}] + [
                {"id": d.id, "word": d.word} for d in distractors
            ]
            _random.shuffle(choices)
            questions.append({
                "id": w.id,
                "meaning": w.meaning,
                "example_sentence": w.example_sentence,
                "correct_id": w.id,
                "choices": choices,
            })
        _random.shuffle(questions)

        data = {
            "day_number": day.day_number,
            "title": day.title,
            "questions": questions,
        }
        serializer = VocabularyQuizSerializer(data=data)
        serializer.is_valid(raise_exception=True)
        return Response(serializer.data)


class VocabularyQuizResultView(APIView):
    """Student: submit quiz result, auto-complete day if score >= 60%."""
    permission_classes = [IsStudent]

    def post(self, request, pk):
        try:
            student = request.user.student
        except Student.DoesNotExist:
            return Response({"detail": "Student profile not found."}, status=status.HTTP_403_FORBIDDEN)

        try:
            day = VocabularyDay.objects.get(pk=pk)
        except VocabularyDay.DoesNotExist:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)

        correct = request.data.get("correct")
        total = request.data.get("total")
        if correct is None or total is None:
            return Response({"detail": "correct and total are required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            correct = int(correct)
            total = int(total)
        except (ValueError, TypeError):
            return Response({"detail": "correct and total must be integers."}, status=status.HTTP_400_BAD_REQUEST)

        score = round((correct / total) * 100, 1) if total else 0.0

        VocabularyQuizResult.objects.create(
            student=student,
            day=day,
            score=score,
            correct=correct,
            total=total,
        )

        if score >= 60:
            VocabularyDayCompletion.objects.get_or_create(student=student, day=day)

        best_result = VocabularyQuizResult.objects.filter(student=student, day=day).order_by("-score").first()
        best_score = best_result.score if best_result else score

        return Response({"status": "ok", "score": score, "best_score": best_score})


# ---------------------------------------------------------------------------
# Student Progress
# ---------------------------------------------------------------------------


class StudentProgressView(APIView):
    """Student: chart data for the progress screen."""
    permission_classes = [IsStudent]

    def get(self, request):
        import datetime
        from django.db.models import Avg, Count
        from django.db.models.functions import TruncDate
        from django.utils import timezone as tz

        try:
            student = request.user.student
        except Student.DoesNotExist:
            return Response({"detail": "Student profile not found."}, status=status.HTTP_403_FORBIDDEN)

        enrolled_group_ids = list(
            Enrollment.objects.filter(student=student, is_active=True).values_list("group_id", flat=True)
        )
        today = tz.localdate()
        days_30 = [(today - datetime.timedelta(days=i)) for i in range(29, -1, -1)]
        date_labels_30d = [d.strftime("%b %d") for d in days_30]

        # Vocab days completed per day (last 30 days)
        completions_qs = dict(
            VocabularyDayCompletion.objects.filter(student=student)
            .annotate(d=TruncDate("completed_at"))
            .values("d")
            .annotate(cnt=Count("id"))
            .values_list("d", "cnt")
        )
        activity_30d = [completions_qs.get(d, 0) for d in days_30]

        # Last 20 quiz results ordered by taken_at
        quiz_results_qs = VocabularyQuizResult.objects.filter(student=student).order_by("taken_at")[:20]
        quiz_scores = [
            {
                "score": qr.score,
                "taken_at_str": qr.taken_at.strftime("%b %d"),
                "day_title": qr.day.title if qr.day else "",
            }
            for qr in quiz_results_qs
        ]

        # Exam results per enrolled group
        results_qs = StudentResult.objects.filter(
            student=student, group_id__in=enrolled_group_ids
        ).select_related("group")
        exam_results = []
        for r in results_qs:
            total = int(r.test) + int(r.exam)
            score_pct = round(total / 2, 1)  # out of 100 total (50+50)
            exam_results.append({
                "group_name": r.group.name if r.group else "General",
                "test_score": r.test,
                "exam_score": r.exam,
                "total": total,
                "score_pct": score_pct,
            })

        # Attendance percentage
        reports = AttendanceReport.objects.filter(student=student)
        total_att = reports.count()
        present_att = reports.filter(status=AttendanceReport.PRESENT).count()
        attendance_pct = round(present_att / total_att * 100, 1) if total_att else 0.0

        # Summary stats
        completed_days = VocabularyDayCompletion.objects.filter(student=student).count()
        quiz_count = VocabularyQuizResult.objects.filter(student=student).count()
        avg_quiz_agg = VocabularyQuizResult.objects.filter(student=student).aggregate(avg=Avg("score"))
        avg_quiz_score = round(avg_quiz_agg["avg"], 1) if avg_quiz_agg["avg"] is not None else 0.0

        return Response({
            "activity_30d": activity_30d,
            "quiz_scores": quiz_scores,
            "exam_results": exam_results,
            "date_labels_30d": date_labels_30d,
            "attendance_pct": attendance_pct,
            "completed_days": completed_days,
            "quiz_count": quiz_count,
            "avg_quiz_score": avg_quiz_score,
        })


# ---------------------------------------------------------------------------
# Stories
# ---------------------------------------------------------------------------


class StoryListView(APIView):
    """GET: all authenticated users. Filters by enrolled groups for students."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from django.utils import timezone as tz
        user = request.user
        user_type = str(user.user_type)

        now = tz.now()
        qs = DashboardStory.objects.filter(is_active=True).filter(
            Q(expires_at__isnull=True) | Q(expires_at__gt=now)
        ).prefetch_related("target_groups")

        if user_type == "3":
            try:
                student = user.student
            except Student.DoesNotExist:
                return Response([], status=status.HTTP_200_OK)
            enrolled_group_ids = list(
                Enrollment.objects.filter(student=student, is_active=True).values_list("group_id", flat=True)
            )
            # Show stories targeted to enrolled groups OR stories with no target groups (all)
            qs = qs.filter(
                Q(target_groups__isnull=True) | Q(target_groups__in=enrolled_group_ids)
            ).distinct()

        qs = qs.order_by("-created_at")
        serializer = StorySerializer(qs, many=True, context={"request": request})
        return Response(serializer.data)


class StoryCreateView(APIView):
    """POST: Admin or Staff only."""
    permission_classes = [IsAdminOrTeacher]

    def post(self, request):
        from django.utils import timezone as tz
        user = request.user
        user_type = str(user.user_type)

        title = request.data.get("title", "").strip()
        if not title:
            return Response({"title": "This field is required."}, status=status.HTTP_400_BAD_REQUEST)

        body = request.data.get("body", "")
        story_type = request.data.get("story_type", DashboardStory.TYPE_ANNOUNCEMENT)
        emoji = request.data.get("emoji", "📢")
        bg_color = request.data.get("bg_color", "#0C1F45")
        expires_at = request.data.get("expires_at", None)
        target_group_ids = request.data.get("target_group_ids", [])

        # Resolve created_by: for staff, store the CustomUser (admin field of Staff)
        if user_type == "2":
            created_by = user  # DashboardStory.created_by is a FK to CustomUser
        else:
            created_by = user

        story = DashboardStory.objects.create(
            title=title,
            body=body,
            story_type=story_type,
            emoji=emoji,
            bg_color=bg_color,
            created_by=created_by,
            expires_at=expires_at or None,
        )

        if target_group_ids:
            groups = Group.objects.filter(id__in=target_group_ids)
            story.target_groups.set(groups)

        serializer = StorySerializer(story, context={"request": request})
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class StoryDetailView(APIView):
    """DELETE: Admin or creator (staff)."""
    permission_classes = [IsAdminOrTeacher]

    def delete(self, request, pk):
        try:
            story = DashboardStory.objects.get(pk=pk)
        except DashboardStory.DoesNotExist:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)

        user = request.user
        user_type = str(user.user_type)

        # Admin can delete any; staff can only delete their own
        if user_type != "1" and story.created_by_id != user.id:
            return Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)

        story.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


# ---------------------------------------------------------------------------
# Staff Vocabulary Management
# ---------------------------------------------------------------------------


class StaffVocabularyListView(APIView):
    """Staff: list vocabulary days they created."""
    permission_classes = [IsTeacher]

    def get(self, request):
        try:
            staff = request.user.staff
        except Staff.DoesNotExist:
            return Response({"detail": "Staff profile not found."}, status=status.HTTP_403_FORBIDDEN)

        days = VocabularyDay.objects.filter(created_by=staff).select_related("group").prefetch_related("words", "completions")
        serializer = StaffVocabularyDaySerializer(days, many=True, context={"request": request})
        return Response(serializer.data)


class StaffVocabularyCreateView(APIView):
    """Staff: create a new vocabulary day."""
    permission_classes = [IsTeacher]

    def post(self, request):
        try:
            staff = request.user.staff
        except Staff.DoesNotExist:
            return Response({"detail": "Staff profile not found."}, status=status.HTTP_403_FORBIDDEN)

        group_id = request.data.get("group")
        if not group_id:
            return Response({"detail": "group is required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            group = Group.objects.get(pk=group_id)
        except Group.DoesNotExist:
            return Response({"detail": "Group not found."}, status=status.HTTP_404_NOT_FOUND)

        # Staff can only create vocab for groups assigned to them
        if group.teacher_id != staff.id:
            return Response(
                {"detail": "You can only create vocabulary for groups assigned to you."},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = StaffVocabularyDaySerializer(data=request.data, context={"request": request})
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        day = serializer.save(created_by=staff, group=group)
        return Response(
            StaffVocabularyDaySerializer(day, context={"request": request}).data,
            status=status.HTTP_201_CREATED,
        )


class StaffVocabularyDetailView(APIView):
    """Staff: GET/PATCH/DELETE a vocabulary day they own."""
    permission_classes = [IsTeacher]

    def _get_day(self, request, pk):
        try:
            staff = request.user.staff
        except Staff.DoesNotExist:
            return None, Response({"detail": "Staff profile not found."}, status=status.HTTP_403_FORBIDDEN)
        try:
            day = VocabularyDay.objects.prefetch_related("words", "completions").select_related("group").get(pk=pk)
        except VocabularyDay.DoesNotExist:
            return None, Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)
        if day.created_by_id != staff.id:
            return None, Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)
        return day, None

    def get(self, request, pk):
        day, err = self._get_day(request, pk)
        if err:
            return err
        serializer = StaffVocabularyDaySerializer(day, context={"request": request})
        return Response(serializer.data)

    def patch(self, request, pk):
        day, err = self._get_day(request, pk)
        if err:
            return err
        serializer = StaffVocabularyDaySerializer(day, data=request.data, partial=True, context={"request": request})
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        serializer.save()
        return Response(serializer.data)

    def delete(self, request, pk):
        day, err = self._get_day(request, pk)
        if err:
            return err
        day.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class StaffVocabularyWordView(APIView):
    """Staff: add or remove words from a vocabulary day they own."""
    permission_classes = [IsTeacher]

    def _get_day(self, request, pk):
        try:
            staff = request.user.staff
        except Staff.DoesNotExist:
            return None, Response({"detail": "Staff profile not found."}, status=status.HTTP_403_FORBIDDEN)
        try:
            day = VocabularyDay.objects.get(pk=pk)
        except VocabularyDay.DoesNotExist:
            return None, Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)
        if day.created_by_id != staff.id:
            return None, Response({"detail": "Permission denied."}, status=status.HTTP_403_FORBIDDEN)
        return day, None

    def post(self, request, pk):
        day, err = self._get_day(request, pk)
        if err:
            return err
        serializer = VocabularyWordWriteSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        word = serializer.save(day=day)
        return Response(
            VocabularyWordWriteSerializer(word).data,
            status=status.HTTP_201_CREATED,
        )

    def delete(self, request, pk, word_pk):
        day, err = self._get_day(request, pk)
        if err:
            return err
        try:
            word = VocabularyDayWord.objects.get(pk=word_pk, day=day)
        except VocabularyDayWord.DoesNotExist:
            return Response({"detail": "Word not found."}, status=status.HTTP_404_NOT_FOUND)
        word.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
