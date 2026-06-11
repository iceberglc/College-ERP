from django.urls import path

from . import views

urlpatterns = [
    # ── Auth ─────────────────────────────────────────────────────────────────
    path("auth/login/", views.LoginView.as_view(), name="api_login"),
    path("auth/logout/", views.LogoutView.as_view(), name="api_logout"),

    # ── Profile (all roles) ───────────────────────────────────────────────────
    path("me/", views.MeView.as_view(), name="api_me"),
    path("me/change-password/", views.ChangePasswordView.as_view(), name="api_change_password"),
    path("me/fcm-token/", views.FcmTokenView.as_view(), name="api_fcm_token"),

    # ── Courses & Groups ──────────────────────────────────────────────────────
    path("courses/", views.CourseListView.as_view(), name="api_courses"),
    path("groups/", views.GroupListView.as_view(), name="api_groups"),
    path("groups/<int:pk>/", views.GroupDetailView.as_view(), name="api_group_detail"),

    # ── Attendance ────────────────────────────────────────────────────────────
    path("attendance/", views.AttendanceView.as_view(), name="api_attendance"),

    # ── Results ───────────────────────────────────────────────────────────────
    path("results/", views.ResultView.as_view(), name="api_results"),

    # ── Assignments ───────────────────────────────────────────────────────────
    path("assignments/", views.AssignmentListView.as_view(), name="api_assignments"),
    path("assignments/<int:pk>/", views.AssignmentDetailView.as_view(), name="api_assignment_detail"),
    path("assignments/<int:pk>/submit/", views.SubmitAssignmentView.as_view(), name="api_submit_assignment"),

    # ── Notifications ─────────────────────────────────────────────────────────
    path("notifications/", views.NotificationListView.as_view(), name="api_notifications"),
    path("notifications/mark-all-read/", views.NotificationMarkAllReadView.as_view(), name="api_notifications_mark_all"),
    path("notifications/<int:pk>/read/", views.NotificationReadView.as_view(), name="api_notification_read"),

    # ── Leave  (student/staff POST own; admin GET all + PATCH approve/reject) ─
    path("leave/", views.LeaveView.as_view(), name="api_leave"),
    path("leave/<int:pk>/", views.LeaveDetailView.as_view(), name="api_leave_detail"),

    # ── Feedback  (student/staff POST own; admin GET all + PATCH reply) ───────
    path("feedback/", views.FeedbackView.as_view(), name="api_feedback"),
    path("feedback/<int:pk>/", views.FeedbackDetailView.as_view(), name="api_feedback_detail"),

    # ── Invoices  (student: own; admin: all) ─────────────────────────────────
    path("invoices/", views.InvoiceView.as_view(), name="api_invoices"),
    path("invoices/<int:pk>/", views.InvoiceDetailView.as_view(), name="api_invoice_detail"),

    # ── Dashboard endpoints (mobile home screens) ────────────────────────────
    path("student/home/", views.StudentDashboardView.as_view(), name="api_student_home"),
    path("admin/home/",   views.AdminDashboardView.as_view(),   name="api_admin_home"),

    # ── Stats  (staff + admin dashboard) ─────────────────────────────────────
    path("stats/", views.StaffStatsView.as_view(), name="api_stats"),

    # ── File upload ───────────────────────────────────────────────────────────
    path("upload/", views.FileUploadView.as_view(), name="api_upload"),

    # ── Admin: core stats & users ─────────────────────────────────────────────
    path("admin/stats/", views.AdminStatsView.as_view(), name="api_admin_stats"),
    path("admin/users/", views.AdminUserListView.as_view(), name="api_admin_users"),
    path("admin/groups/", views.AdminGroupListView.as_view(), name="api_admin_groups"),
    path("admin/enroll/", views.AdminEnrollmentView.as_view(), name="api_admin_enroll"),

    # ── Admin: student management ─────────────────────────────────────────────
    path("admin/students/", views.AdminStudentListView.as_view(), name="api_admin_students"),
    path("admin/students/<int:pk>/", views.AdminStudentDetailView.as_view(), name="api_admin_student_detail"),

    # ── Admin: staff management ───────────────────────────────────────────────
    path("admin/staff/", views.AdminStaffListView.as_view(), name="api_admin_staff"),
    path("admin/staff/<int:pk>/", views.AdminStaffDetailView.as_view(), name="api_admin_staff_detail"),

    # ── Admin: registration leads ─────────────────────────────────────────────
    path("admin/leads/", views.AdminLeadListView.as_view(), name="api_admin_leads"),
    path("admin/leads/<int:pk>/", views.AdminLeadDetailView.as_view(), name="api_admin_lead_detail"),

    # ── Admin: branches ───────────────────────────────────────────────────────
    path("admin/branches/", views.AdminBranchListView.as_view(), name="api_admin_branches"),

    # ── Vocabulary (student) ──────────────────────────────────────────────────
    path("vocabulary/", views.VocabularyDayListView.as_view(), name="api_vocabulary"),
    path("vocabulary/<int:pk>/", views.VocabularyDayDetailView.as_view(), name="api_vocabulary_detail"),
    path("vocabulary/<int:pk>/complete/", views.VocabularyDayCompleteView.as_view(), name="api_vocabulary_complete"),

    # ── Leaderboard ───────────────────────────────────────────────────────────
    path("leaderboard/", views.LeaderboardView.as_view(), name="api_leaderboard"),
]
