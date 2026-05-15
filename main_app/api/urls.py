from django.urls import path

from . import views

urlpatterns = [
    # Auth
    path('auth/login/', views.LoginView.as_view(), name='api_login'),
    path('auth/logout/', views.LogoutView.as_view(), name='api_logout'),

    # Profile
    path('me/', views.MeView.as_view(), name='api_me'),
    path('me/change-password/', views.ChangePasswordView.as_view(), name='api_change_password'),
    path('me/fcm-token/', views.FcmTokenView.as_view(), name='api_fcm_token'),

    # Courses
    path('courses/', views.CourseListView.as_view(), name='api_courses'),

    # Groups
    path('groups/', views.GroupListView.as_view(), name='api_groups'),
    path('groups/<int:pk>/', views.GroupDetailView.as_view(), name='api_group_detail'),

    # Attendance
    path('attendance/', views.AttendanceView.as_view(), name='api_attendance'),

    # Results
    path('results/', views.ResultView.as_view(), name='api_results'),

    # Assignments
    path('assignments/', views.AssignmentListView.as_view(), name='api_assignments'),
    path('assignments/<int:pk>/', views.AssignmentDetailView.as_view(), name='api_assignment_detail'),
    path('assignments/<int:pk>/submit/', views.SubmitAssignmentView.as_view(), name='api_submit_assignment'),

    # Notifications
    path('notifications/', views.NotificationListView.as_view(), name='api_notifications'),
    path('notifications/mark-all-read/', views.NotificationMarkAllReadView.as_view(), name='api_notifications_mark_all'),
    path('notifications/<int:pk>/read/', views.NotificationReadView.as_view(), name='api_notification_read'),

    # File upload
    path('upload/', views.FileUploadView.as_view(), name='api_upload'),

    # Admin
    path('admin/stats/', views.AdminStatsView.as_view(), name='api_admin_stats'),
    path('admin/users/', views.AdminUserListView.as_view(), name='api_admin_users'),
    path('admin/groups/', views.AdminGroupListView.as_view(), name='api_admin_groups'),
    path('admin/enroll/', views.AdminEnrollmentView.as_view(), name='api_admin_enroll'),
]
