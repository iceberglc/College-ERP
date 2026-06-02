from rest_framework import serializers

from ..models import (
    CustomUser,
    Course,
    Branch,
    Group,
    Student,
    Staff,
    Enrollment,
    Attendance,
    AttendanceReport,
    StudentResult,
    Assignment,
    Submission,
    Notification,
)


# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------


class UserSerializer(serializers.ModelSerializer):
    profile_pic_url = serializers.SerializerMethodField()

    class Meta:
        model = CustomUser
        fields = [
            "id",
            "email",
            "login_id",
            "first_name",
            "last_name",
            "user_type",
            "gender",
            "date_of_birth",
            "profile_pic_url",
            "address",
        ]

    def get_profile_pic_url(self, obj):
        if not obj.profile_pic:
            return None
        request = self.context.get("request")
        if request:
            return request.build_absolute_uri(obj.profile_pic.url)
        return obj.profile_pic.url


# ---------------------------------------------------------------------------
# Profile (GET /me/)
# ---------------------------------------------------------------------------


class StaffRoleSerializer(serializers.ModelSerializer):
    course_id = serializers.IntegerField(source="course.id", read_only=True, allow_null=True)
    course_name = serializers.CharField(source="course.name", read_only=True, allow_null=True)

    class Meta:
        model = Staff
        fields = ["phone", "specialization", "course_id", "course_name", "is_active"]


class StudentRoleSerializer(serializers.ModelSerializer):
    course_id = serializers.IntegerField(source="course.id", read_only=True, allow_null=True)
    course_name = serializers.CharField(source="course.name", read_only=True, allow_null=True)

    class Meta:
        model = Student
        fields = ["phone", "status", "course_id", "course_name"]


class MeSerializer(serializers.ModelSerializer):
    profile_pic_url = serializers.SerializerMethodField()
    role_profile = serializers.SerializerMethodField()

    class Meta:
        model = CustomUser
        fields = [
            "id",
            "email",
            "login_id",
            "first_name",
            "last_name",
            "user_type",
            "gender",
            "date_of_birth",
            "profile_pic_url",
            "address",
            "role_profile",
        ]
        read_only_fields = ["id", "email", "login_id", "user_type"]

    def get_profile_pic_url(self, obj):
        if not obj.profile_pic:
            return None
        request = self.context.get("request")
        if request:
            return request.build_absolute_uri(obj.profile_pic.url)
        return obj.profile_pic.url

    def get_role_profile(self, obj):
        ctx = self.context
        user_type = str(obj.user_type)
        if user_type == "2":
            try:
                return StaffRoleSerializer(obj.staff, context=ctx).data
            except Staff.DoesNotExist:
                return None
        if user_type == "3":
            try:
                return StudentRoleSerializer(obj.student, context=ctx).data
            except Student.DoesNotExist:
                return None
        return None


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(write_only=True)
    new_password = serializers.CharField(write_only=True, min_length=8)
    confirm_password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        if attrs["new_password"] != attrs["confirm_password"]:
            raise serializers.ValidationError({"confirm_password": "Passwords do not match."})
        return attrs


class FcmTokenSerializer(serializers.Serializer):
    token = serializers.CharField(max_length=512)


# ---------------------------------------------------------------------------
# Courses & Branches
# ---------------------------------------------------------------------------


class CourseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Course
        fields = ["id", "name", "is_active"]


class BranchSerializer(serializers.ModelSerializer):
    class Meta:
        model = Branch
        fields = ["id", "name", "address"]


# ---------------------------------------------------------------------------
# Groups
# ---------------------------------------------------------------------------


class GroupSerializer(serializers.ModelSerializer):
    course_name = serializers.CharField(source="course.name", read_only=True)
    teacher_name = serializers.SerializerMethodField()
    branch_name = serializers.CharField(source="branch.name", read_only=True, allow_null=True)

    class Meta:
        model = Group
        fields = [
            "id",
            "name",
            "course",
            "course_name",
            "teacher",
            "teacher_name",
            "branch",
            "branch_name",
            "room",
            "schedule",
            "capacity",
            "is_archived",
        ]
        read_only_fields = ["course_name", "teacher_name", "branch_name"]

    def get_teacher_name(self, obj):
        if obj.teacher and obj.teacher.admin:
            u = obj.teacher.admin
            return f"{u.first_name} {u.last_name}".strip()
        return None


class StudentSummarySerializer(serializers.ModelSerializer):
    first_name = serializers.CharField(source="admin.first_name", read_only=True)
    last_name = serializers.CharField(source="admin.last_name", read_only=True)
    email = serializers.EmailField(source="admin.email", read_only=True)
    profile_pic_url = serializers.SerializerMethodField()

    class Meta:
        model = Student
        fields = ["id", "first_name", "last_name", "email", "phone", "status", "profile_pic_url"]

    def get_profile_pic_url(self, obj):
        if not obj.admin.profile_pic:
            return None
        request = self.context.get("request")
        if request:
            return request.build_absolute_uri(obj.admin.profile_pic.url)
        return obj.admin.profile_pic.url


class GroupDetailSerializer(GroupSerializer):
    enrolled_students = serializers.SerializerMethodField()
    enrolled_count = serializers.SerializerMethodField()

    class Meta(GroupSerializer.Meta):
        fields = GroupSerializer.Meta.fields + ["enrolled_students", "enrolled_count"]

    def get_enrolled_students(self, obj):
        enrollments = Enrollment.objects.filter(group=obj, is_active=True).select_related(
            "student__admin"
        )
        return StudentSummarySerializer(
            [e.student for e in enrollments],
            many=True,
            context=self.context,
        ).data

    def get_enrolled_count(self, obj):
        return Enrollment.objects.filter(group=obj, is_active=True).count()


# ---------------------------------------------------------------------------
# Attendance
# ---------------------------------------------------------------------------


class AttendanceReportItemSerializer(serializers.ModelSerializer):
    student_id = serializers.IntegerField(source="student.id", read_only=True)
    student_name = serializers.SerializerMethodField()

    class Meta:
        model = AttendanceReport
        fields = ["student_id", "student_name", "status"]

    def get_student_name(self, obj):
        u = obj.student.admin
        return f"{u.first_name} {u.last_name}".strip()


class AttendanceSerializer(serializers.ModelSerializer):
    group_name = serializers.CharField(source="group.name", read_only=True, allow_null=True)
    reports = AttendanceReportItemSerializer(
        source="attendancereport_set", many=True, read_only=True
    )

    class Meta:
        model = Attendance
        fields = ["id", "group", "group_name", "date", "reports"]


class AttendanceSaveSerializer(serializers.Serializer):
    group_id = serializers.IntegerField()
    date = serializers.DateField()
    records = serializers.ListField(
        child=serializers.DictField(),
        allow_empty=False,
    )

    def validate_group_id(self, value):
        if not Group.objects.filter(id=value).exists():
            raise serializers.ValidationError("Group not found.")
        return value

    def validate_records(self, records):
        for rec in records:
            if "student_id" not in rec or "status" not in rec:
                raise serializers.ValidationError("Each record must have student_id and status.")
            if int(rec["status"]) not in (0, 1, 2):
                raise serializers.ValidationError(
                    "Status must be 0 (Absent), 1 (Present), or 2 (Late)."
                )
        return records


# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------


class StudentResultSerializer(serializers.ModelSerializer):
    student_name = serializers.SerializerMethodField()
    group_name = serializers.CharField(source="group.name", read_only=True, allow_null=True)

    class Meta:
        model = StudentResult
        fields = [
            "id",
            "student",
            "student_name",
            "group",
            "group_name",
            "test",
            "exam",
            "comment",
            "updated_at",
        ]
        read_only_fields = ["student_name", "group_name", "updated_at"]

    def get_student_name(self, obj):
        u = obj.student.admin
        return f"{u.first_name} {u.last_name}".strip()


# ---------------------------------------------------------------------------
# Assignments & Submissions
# ---------------------------------------------------------------------------


class AssignmentSerializer(serializers.ModelSerializer):
    group_name = serializers.CharField(source="group.name", read_only=True, allow_null=True)
    created_by_name = serializers.SerializerMethodField()

    class Meta:
        model = Assignment
        fields = [
            "id",
            "title",
            "description",
            "group",
            "group_name",
            "due_date",
            "created_by_name",
            "created_at",
        ]
        read_only_fields = ["group_name", "created_by_name", "created_at"]

    def get_created_by_name(self, obj):
        u = obj.created_by.admin
        return f"{u.first_name} {u.last_name}".strip()


class SubmissionSerializer(serializers.ModelSerializer):
    file_url = serializers.SerializerMethodField()

    class Meta:
        model = Submission
        fields = ["id", "assignment", "file_url", "note", "submitted_at", "grade"]
        read_only_fields = ["submitted_at", "grade"]

    def get_file_url(self, obj):
        if not obj.file:
            return None
        request = self.context.get("request")
        if request:
            return request.build_absolute_uri(obj.file.url)
        return obj.file.url


class AssignmentDetailSerializer(AssignmentSerializer):
    my_submission = serializers.SerializerMethodField()

    class Meta(AssignmentSerializer.Meta):
        fields = AssignmentSerializer.Meta.fields + ["my_submission"]

    def get_my_submission(self, obj):
        request = self.context.get("request")
        if not request or str(request.user.user_type) != "3":
            return None
        try:
            sub = Submission.objects.get(assignment=obj, student=request.user.student)
            return SubmissionSerializer(sub, context=self.context).data
        except (Student.DoesNotExist, Submission.DoesNotExist):
            return None


class SubmitAssignmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Submission
        fields = ["file", "note"]


# ---------------------------------------------------------------------------
# Notifications
# ---------------------------------------------------------------------------


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ["id", "category", "message", "is_read", "created_at"]


# ---------------------------------------------------------------------------
# Admin helpers
# ---------------------------------------------------------------------------


class EnrollmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Enrollment
        fields = ["id", "student", "group", "enrolled_on", "is_active"]
        read_only_fields = ["enrolled_on"]
