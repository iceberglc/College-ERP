import json
import re
from datetime import date
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.core import mail
from django.test import TestCase, override_settings
from django.urls import reverse

from main_app.hod_views import _generate_login_id
from main_app.messaging import unread_message_count
from main_app.models import (
    Attendance,
    AttendanceReport,
    Assignment,
    ChatMessage,
    ChatReadState,
    ChatThread,
    Course,
    Enrollment,
    Group,
    RegistrationLead,
    Staff,
    Student,
)


_BASE_OVERRIDES = dict(
    EMAIL_BACKEND="django.core.mail.backends.locmem.EmailBackend",
    # Disable SSL redirect so the test client (HTTP) reaches views without
    # being bounced to HTTPS (which then strips POST bodies on 301 redirect).
    SECURE_SSL_REDIRECT=False,
)


class LoginPageTests(TestCase):
    def setUp(self):
        UserModel = get_user_model()
        self.admin = UserModel.objects.create_user(
            email="admin@example.com",
            password="AdminPass123!",
            first_name="Test",
            last_name="Admin",
            user_type="1",
            gender="M",
            address="Test",
            profile_pic="",
        )
        self.staff = UserModel.objects.create_user(
            email="staff@example.com",
            password="StaffPass123!",
            first_name="Test",
            last_name="Staff",
            user_type="2",
            gender="M",
            address="Test",
            profile_pic="",
            login_id="TC500",
        )
        self.student = UserModel.objects.create_user(
            email="student@example.com",
            password="StudentPass123!",
            first_name="Test",
            last_name="Student",
            user_type="3",
            gender="M",
            address="Test",
            profile_pic="",
            login_id="IC1000",
        )

    @override_settings(**_BASE_OVERRIDES)
    def test_login_page_get_returns_200(self):
        response = self.client.get(reverse("login_page"))
        self.assertEqual(response.status_code, 200)

    @override_settings(**_BASE_OVERRIDES)
    def test_login_invalid_credentials_shows_error(self):
        response = self.client.post(
            reverse("user_login"),
            {
                "email": "nobody@example.com",
                "password": "wrongpassword",
            },
            follow=True,
        )
        self.assertEqual(response.status_code, 200)
        self.assertIn(b"not found", response.content)

    @override_settings(**_BASE_OVERRIDES)
    def test_admin_login_redirects_to_admin_home(self):
        response = self.client.post(
            reverse("user_login"),
            {
                "identifier": "admin@example.com",
                "password": "AdminPass123!",
            },
        )
        self.assertRedirects(response, reverse("admin_home"), fetch_redirect_response=False)

    @override_settings(**_BASE_OVERRIDES)
    def test_staff_login_redirects_to_staff_home(self):
        response = self.client.post(
            reverse("user_login"),
            {
                "identifier": "TC500",
                "password": "StaffPass123!",
            },
        )
        self.assertRedirects(response, reverse("staff_home"), fetch_redirect_response=False)

    @override_settings(**_BASE_OVERRIDES)
    def test_student_login_redirects_to_student_home(self):
        response = self.client.post(
            reverse("user_login"),
            {
                "identifier": "IC1000",
                "password": "StudentPass123!",
            },
        )
        self.assertRedirects(response, reverse("student_home"), fetch_redirect_response=False)

    @override_settings(**_BASE_OVERRIDES)
    def test_no_role_confusion_admin_cannot_reach_student_home(self):
        # force_login bypasses auth backends (avoids axes request requirement).
        # We only need to test role-based routing here, not authentication.
        self.client.force_login(self.admin)
        response = self.client.get(reverse("student_home"))
        # Admin should be redirected away from student pages.
        self.assertNotEqual(response.status_code, 200)

    @override_settings(**_BASE_OVERRIDES)
    def test_unauthenticated_blocked_from_admin_home(self):
        response = self.client.get(reverse("admin_home"))
        self.assertNotEqual(response.status_code, 200)


class ProfileHubTests(TestCase):
    def setUp(self):
        UserModel = get_user_model()
        self.course = Course.objects.create(name="Profile Hub Course")
        self.admin = UserModel.objects.create_user(
            email="profile-admin@example.com",
            password="AdminPass123!",
            first_name="Ada",
            last_name="Admin",
            user_type="1",
            gender="F",
            address="HQ",
            profile_pic="",
        )
        self.staff_user = UserModel.objects.create_user(
            email="profile-staff@example.com",
            password="StaffPass123!",
            first_name="Theo",
            last_name="Teacher",
            user_type="2",
            gender="M",
            address="Branch",
            profile_pic="",
            login_id="TC90001",
        )
        self.student_user = UserModel.objects.create_user(
            email="profile-student@example.com",
            password="StudentPass123!",
            first_name="Sam",
            last_name="Student",
            user_type="3",
            gender="M",
            address="Home",
            profile_pic="",
            login_id="IC90001",
        )
        self.staff = Staff.objects.get(admin=self.staff_user)
        self.staff.course = self.course
        self.staff.specialization = "IELTS"
        self.staff.save()
        self.student = Student.objects.get(admin=self.student_user)
        self.student.course = self.course
        self.student.phone = "+998 90 000 00 00"
        self.student.save()

    @override_settings(**_BASE_OVERRIDES)
    def test_profile_hub_renders_for_all_roles(self):
        cases = [
            (self.admin, "Admin", "Administration"),
            (self.staff_user, "Teacher", "Teaching"),
            (self.student_user, "Student", "My Studies"),
        ]
        for user, role_label, role_section in cases:
            with self.subTest(role=role_label):
                self.client.force_login(user)
                response = self.client.get(reverse("profile_hub"))
                self.assertEqual(response.status_code, 200)
                self.assertContains(response, "profile-hub")
                self.assertContains(response, role_label)
                self.assertContains(response, role_section)
                self.assertContains(response, "Theme / Appearance")
                self.assertContains(response, "Log Out")
                self.client.logout()

    @override_settings(**_BASE_OVERRIDES)
    def test_student_can_update_profile_from_hub(self):
        self.client.force_login(self.student_user)
        response = self.client.post(
            reverse("profile_hub"),
            {
                "first_name": "Samuel",
                "last_name": "Student",
                "gender": "M",
                "date_of_birth": "2005-05-10",
                "phone": "+998 90 111 22 33",
                "password": "",
            },
        )
        self.assertRedirects(response, reverse("profile_hub"), fetch_redirect_response=False)
        self.student_user.refresh_from_db()
        self.student.refresh_from_db()
        self.assertEqual(self.student_user.first_name, "Samuel")
        self.assertEqual(self.student.phone, "+998 90 111 22 33")


class RegistrationLeadReceiverTests(TestCase):
    @override_settings(**_BASE_OVERRIDES, REGISTRATION_LEADS_API_TOKEN="secret-token")
    def test_receiver_requires_configured_bearer_token(self):
        response = self.client.post(
            reverse("public_registration_leads"),
            data=json.dumps({"full_name": "Public Student", "phone": "+998901234567"}),
            content_type="application/json",
        )
        self.assertEqual(response.status_code, 401)
        self.assertEqual(RegistrationLead.objects.count(), 0)

    @override_settings(**_BASE_OVERRIDES, REGISTRATION_LEADS_API_TOKEN="secret-token")
    def test_receiver_stores_json_registration_lead(self):
        response = self.client.post(
            reverse("public_registration_leads"),
            data=json.dumps(
                {
                    "full_name": "Public Student",
                    "phone": "+998901234567",
                    "course": "IELTS Academic",
                    "source": "instagram",
                    "utm_campaign": "summer-intake",
                    "social_handle": "@publicstudent",
                }
            ),
            content_type="application/json",
            HTTP_AUTHORIZATION="Bearer secret-token",
            HTTP_USER_AGENT="website-test-client",
            REMOTE_ADDR="127.0.0.5",
        )
        self.assertEqual(response.status_code, 201)
        lead = RegistrationLead.objects.get()
        self.assertEqual(lead.full_name, "Public Student")
        self.assertEqual(lead.phone, "+998901234567")
        self.assertEqual(lead.program, "IELTS Academic")
        self.assertEqual(lead.source, "instagram")
        self.assertEqual(lead.utm_campaign, "summer-intake")
        self.assertEqual(lead.social_handle, "@publicstudent")
        self.assertEqual(lead.user_agent, "website-test-client")

    @override_settings(**_BASE_OVERRIDES, REGISTRATION_LEADS_API_TOKEN="secret-token")
    def test_receiver_accepts_minimal_name_and_phone_payload(self):
        response = self.client.post(
            reverse("public_registration_leads"),
            data=json.dumps(
                {
                    "full_name": "Minimal Website Lead",
                    "phone": "+998901112233",
                }
            ),
            content_type="application/json",
            HTTP_AUTHORIZATION="Bearer secret-token",
        )
        self.assertEqual(response.status_code, 201)
        lead = RegistrationLead.objects.get()
        self.assertEqual(lead.full_name, "Minimal Website Lead")
        self.assertEqual(lead.phone, "+998901112233")
        self.assertEqual(lead.program, "")
        self.assertEqual(lead.email, "")
        self.assertEqual(lead.parent_phone, "")
        self.assertEqual(lead.source, "website")

    @override_settings(**_BASE_OVERRIDES, REGISTRATION_LEADS_API_TOKEN="secret-token")
    def test_receiver_accepts_optional_website_fields(self):
        response = self.client.post(
            reverse("public_registration_leads"),
            data=json.dumps(
                {
                    "full_name": "Optional Website Lead",
                    "phone": "+998901112244",
                    "course": "General English",
                    "date_of_birth": "",
                    "parent_phone": "+998909998877",
                    "email": "lead@example.com",
                    "branch": "Main",
                    "preferred_schedule": "Evening",
                    "social_source": "instagram",
                    "social_handle": "@optional",
                    "utm_source": "meta",
                    "utm_medium": "paid-social",
                    "utm_campaign": "summer-intake",
                    "message": "Please call after 5pm",
                    "submitted_at": "2026-06-05T12:00:00Z",
                }
            ),
            content_type="application/json",
            HTTP_AUTHORIZATION="Bearer secret-token",
        )
        self.assertEqual(response.status_code, 201)
        lead = RegistrationLead.objects.get()
        self.assertEqual(lead.program, "General English")
        self.assertEqual(lead.parent_phone, "+998909998877")
        self.assertEqual(lead.email, "lead@example.com")
        self.assertEqual(lead.branch, "Main")
        self.assertEqual(lead.preferred_schedule, "Evening")
        self.assertEqual(lead.source, "instagram")
        self.assertEqual(lead.social_handle, "@optional")
        self.assertEqual(lead.utm_source, "meta")
        self.assertEqual(lead.utm_medium, "paid-social")
        self.assertEqual(lead.utm_campaign, "summer-intake")
        self.assertEqual(lead.message, "Please call after 5pm")
        self.assertEqual(lead.raw_payload["date_of_birth"], "")
        self.assertEqual(lead.raw_payload["submitted_at"], "2026-06-05T12:00:00Z")

    @override_settings(**_BASE_OVERRIDES, REGISTRATION_LEADS_API_TOKEN="secret-token")
    def test_receiver_requires_name_and_phone_only(self):
        missing_name = self.client.post(
            reverse("public_registration_leads"),
            data=json.dumps({"phone": "+998901112233", "course": "Optional Course"}),
            content_type="application/json",
            HTTP_AUTHORIZATION="Bearer secret-token",
        )
        self.assertEqual(missing_name.status_code, 400)
        self.assertEqual(missing_name.json()["detail"], "full_name is required.")

        missing_phone = self.client.post(
            reverse("public_registration_leads"),
            data=json.dumps(
                {
                    "full_name": "No Phone Lead",
                    "email": "lead@example.com",
                    "parent_phone": "+998909998877",
                    "date_of_birth": "2010-01-02",
                }
            ),
            content_type="application/json",
            HTTP_AUTHORIZATION="Bearer secret-token",
        )
        self.assertEqual(missing_phone.status_code, 400)
        self.assertEqual(missing_phone.json()["detail"], "phone is required.")
        self.assertEqual(RegistrationLead.objects.count(), 0)

    @override_settings(**_BASE_OVERRIDES, REGISTRATION_LEADS_API_TOKEN="secret-token")
    def test_receiver_accepts_slashless_url_and_registration_token_header(self):
        response = self.client.post(
            "/public/registration-leads",
            data={
                "Full Name": "Website Form Student",
                "Phone Number": "+998977777777",
                "Course Name": "Speaking Club",
                "Preferred Time": "Evening",
            },
            HTTP_X_REGISTRATION_TOKEN="secret-token",
        )
        self.assertEqual(response.status_code, 201)
        lead = RegistrationLead.objects.get()
        self.assertEqual(lead.full_name, "Website Form Student")
        self.assertEqual(lead.phone, "+998977777777")
        self.assertEqual(lead.program, "Speaking Club")
        self.assertEqual(lead.preferred_schedule, "Evening")

    @override_settings(**_BASE_OVERRIDES, REGISTRATION_LEADS_API_TOKEN="secret-token")
    def test_receiver_accepts_text_plain_json_and_redacts_body_token(self):
        response = self.client.post(
            reverse("public_registration_leads"),
            data=json.dumps(
                {
                    "Name": "Loose Fetch Student",
                    "WhatsApp Number": "+998936666666",
                    "Selected Course": "General English",
                    "apiKey": "secret-token",
                }
            ),
            content_type="text/plain",
        )
        self.assertEqual(response.status_code, 201)
        lead = RegistrationLead.objects.get()
        self.assertEqual(lead.full_name, "Loose Fetch Student")
        self.assertEqual(lead.phone, "+998936666666")
        self.assertEqual(lead.program, "General English")
        self.assertEqual(lead.raw_payload["apiKey"], "[redacted]")

    @override_settings(**_BASE_OVERRIDES, REGISTRATION_LEADS_API_TOKEN="")
    def test_receiver_accepts_form_encoded_payload_when_token_not_configured(self):
        response = self.client.post(
            reverse("public_registration_leads"),
            data={
                "first_name": "Form",
                "last_name": "Lead",
                "phone": "+998900000001",
                "parent_phone": "+998991111111",
                "program": "General English",
            },
        )
        self.assertEqual(response.status_code, 201)
        lead = RegistrationLead.objects.get()
        self.assertEqual(lead.full_name, "Form Lead")
        self.assertEqual(lead.phone, "+998900000001")
        self.assertEqual(lead.parent_phone, "+998991111111")
        self.assertEqual(lead.program, "General English")

    @override_settings(**_BASE_OVERRIDES)
    def test_admin_can_view_registration_leads(self):
        UserModel = get_user_model()
        admin = UserModel.objects.create_user(
            email="lead-admin@example.com",
            password="AdminPass123!",
            first_name="Lead",
            last_name="Admin",
            user_type="1",
            gender="M",
            address="",
            profile_pic="",
        )
        RegistrationLead.objects.create(
            full_name="Dashboard Lead",
            phone="+998900000000",
            program="Speaking",
            source="facebook",
        )
        self.client.force_login(admin)
        response = self.client.get(reverse("manage_registration_leads"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Dashboard Lead")
        self.assertContains(response, "facebook")


class PasswordResetFlowTests(TestCase):
    @override_settings(**_BASE_OVERRIDES)
    def test_password_reset_end_to_end(self):
        user_model = get_user_model()
        user = user_model.objects.create_user(
            email="reset-flow@example.com",
            password="InitialPass123!",
            first_name="Reset",
            last_name="Flow",
            user_type="1",
            gender="M",
            address="Test Address",
            profile_pic="",
        )

        response = self.client.post("/accounts/password_reset/", {"email": user.email}, follow=True)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(mail.outbox), 1)

        body = mail.outbox[0].body
        match = re.search(r"https?://[^\s]+/accounts/reset/[^\s]+", body)
        self.assertIsNotNone(match)

        token_path = "/" + match.group(0).split("/", 3)[3]
        confirm_get_response = self.client.get(token_path, follow=True)
        final_path = confirm_get_response.wsgi_request.path

        new_password = "ChangedPass123!"
        confirm_post_response = self.client.post(
            final_path,
            {"new_password1": new_password, "new_password2": new_password},
            follow=True,
        )

        self.assertEqual(confirm_post_response.status_code, 200)
        user.refresh_from_db()
        self.assertTrue(user.check_password(new_password))


class LoginIdGeneratorTests(TestCase):
    """Birthday-based login_id generator: IC052401 etc."""

    def _make_user(self, login_id, dob=None, email=None, user_type="3"):
        UserModel = get_user_model()
        return UserModel.objects.create_user(
            email=email or f"{login_id.lower()}@iceberg.internal",
            password="x",
            first_name="X",
            last_name="Y",
            user_type=user_type,
            gender="M",
            address="",
            profile_pic="",
            login_id=login_id,
            date_of_birth=dob,
        )

    def test_student_id_encodes_birthday(self):
        lid = _generate_login_id("IC", date(2010, 5, 24))
        self.assertEqual(lid, "IC052401")

    def test_teacher_id_encodes_birthday(self):
        lid = _generate_login_id("TC", date(1985, 2, 12))
        self.assertEqual(lid, "TC021201")

    def test_suffix_increments_on_collision(self):
        dob = date(2009, 7, 7)
        self._make_user("IC070701", dob=dob)
        self._make_user("IC070702", dob=dob)
        self.assertEqual(_generate_login_id("IC", dob), "IC070703")

    def test_pads_month_and_day(self):
        # January 5 should be 0105, not 15.
        self.assertEqual(_generate_login_id("IC", date(2000, 1, 5)), "IC010501")

    def test_fallback_when_no_birthday(self):
        # Without DOB, falls back to sequential.
        lid = _generate_login_id("IC")
        self.assertTrue(lid.startswith("IC"))
        self.assertGreaterEqual(int(lid[2:]), 1000)

    def test_legacy_ids_do_not_collide(self):
        # Legacy formats (IC00005, IC1000, STU-0001) coexist with new format.
        self._make_user("IC00005")
        self._make_user("IC1000", email="legacy2@iceberg.internal")
        self._make_user("STU-0001", email="legacy3@iceberg.internal")
        new = _generate_login_id("IC", date(2012, 3, 15))
        self.assertEqual(new, "IC031501")


class LoginFlowResilienceTests(TestCase):
    def setUp(self):
        self.user_model = get_user_model()
        self.user = self.user_model.objects.create_user(
            email="admin-login@example.com",
            password="AdminPass123!",
            first_name="Admin",
            last_name="User",
            user_type="1",
            gender="M",
            address="Admin Address",
            profile_pic="",
        )

    @override_settings(SECURE_SSL_REDIRECT=False)
    @patch("main_app.views.login", side_effect=Exception("session backend unavailable"))
    def test_login_failure_is_handled_without_500(self, _mock_login):
        response = self.client.post(
            "/doLogin/",
            {"email": self.user.email, "password": "AdminPass123!"},
            follow=False,
        )
        self.assertEqual(response.status_code, 302)
        # doLogin redirects to reverse('login_page') == '/login/' on failure.
        self.assertEqual(response["Location"], "/login/")


class AjaxJsonShapeTests(TestCase):
    def setUp(self):
        UserModel = get_user_model()
        self.course = Course.objects.create(name="General English")
        self.staff_user = UserModel.objects.create_user(
            email="ajax-staff@example.com",
            password="Pass123!",
            first_name="Ajax",
            last_name="Staff",
            user_type="2",
            gender="M",
            address="",
            profile_pic="",
            login_id="TC70001",
        )
        self.staff = Staff.objects.get(admin=self.staff_user)
        self.group = Group.objects.create(name="Ajax Group", course=self.course, teacher=self.staff)
        self.student_user = UserModel.objects.create_user(
            email="ajax-student@example.com",
            password="Pass123!",
            first_name="Ajax",
            last_name="Student",
            user_type="3",
            gender="F",
            address="",
            profile_pic="",
            login_id="IC70001",
        )
        self.student = Student.objects.get(admin=self.student_user)
        Enrollment.objects.create(student=self.student, group=self.group, is_active=True)
        self.attendance = Attendance.objects.create(group=self.group, date=date(2026, 1, 2))
        AttendanceReport.objects.create(
            attendance=self.attendance,
            student=self.student,
            status=AttendanceReport.PRESENT,
        )

    @override_settings(SECURE_SSL_REDIRECT=False)
    def test_staff_student_roster_ajax_returns_json_array(self):
        self.client.force_login(self.staff_user)
        response = self.client.post(reverse("get_students"), {"group": str(self.group.id)})
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertIsInstance(payload, list)
        self.assertEqual(payload[0]["id"], self.student.id)

    @override_settings(SECURE_SSL_REDIRECT=False)
    def test_attendance_date_ajax_returns_json_array(self):
        self.client.force_login(self.staff_user)
        response = self.client.post(reverse("get_attendance"), {"group": str(self.group.id)})
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertIsInstance(payload, list)
        self.assertEqual(payload[0]["id"], self.attendance.id)


class StudentPrivacyTests(TestCase):
    """Students must not be able to access other students' group data."""

    def _make_user(self, email, user_type, login_id=None, dob=None):
        UserModel = get_user_model()
        return UserModel.objects.create_user(
            email=email,
            password="Pass123!",
            first_name="T",
            last_name="U",
            user_type=user_type,
            gender="M",
            address="",
            profile_pic="",
            login_id=login_id,
            date_of_birth=dob,
        )

    def setUp(self):
        self.course = Course.objects.create(name="General English")

        # Two separate teachers
        teacher_a_user = self._make_user("ta@iceberg.internal", "2", "TC50001")
        teacher_b_user = self._make_user("tb@iceberg.internal", "2", "TC50002")
        self.teacher_a = Staff.objects.get(admin=teacher_a_user)
        self.teacher_b = Staff.objects.get(admin=teacher_b_user)

        # Two separate groups
        self.group_a = Group.objects.create(
            name="Group A", course=self.course, teacher=self.teacher_a
        )
        self.group_b = Group.objects.create(
            name="Group B", course=self.course, teacher=self.teacher_b
        )

        # Student A → Group A only
        student_a_user = self._make_user(
            "ic10001@iceberg.internal", "3", "IC10001", date(2005, 5, 1)
        )
        self.student_a = Student.objects.get(admin=student_a_user)
        self.student_a.course = self.course
        self.student_a.save()
        Enrollment.objects.create(student=self.student_a, group=self.group_a, is_active=True)

        # Student B → Group B only
        student_b_user = self._make_user(
            "ic10002@iceberg.internal", "3", "IC10002", date(2005, 6, 1)
        )
        self.student_b = Student.objects.get(admin=student_b_user)
        self.student_b.course = self.course
        self.student_b.save()
        Enrollment.objects.create(student=self.student_b, group=self.group_b, is_active=True)

    @override_settings(SECURE_SSL_REDIRECT=False)
    def test_attendance_ajax_blocks_cross_group_access(self):
        """Student A cannot query attendance for Group B via the AJAX endpoint."""
        self.client.force_login(self.student_a.admin)
        response = self.client.post(
            reverse("student_view_attendance"),
            {
                "group": str(self.group_b.id),
                "start_date": "2026-01-01",
                "end_date": "2026-12-31",
            },
        )
        self.assertEqual(response.status_code, 403)

    @override_settings(SECURE_SSL_REDIRECT=False)
    def test_attendance_ajax_allows_own_group(self):
        """Student A can query attendance for Group A."""
        self.client.force_login(self.student_a.admin)
        response = self.client.post(
            reverse("student_view_attendance"),
            {
                "group": str(self.group_a.id),
                "start_date": "2026-01-01",
                "end_date": "2026-12-31",
            },
        )
        self.assertEqual(response.status_code, 200)
        self.assertIsInstance(response.json(), list)

    @override_settings(SECURE_SSL_REDIRECT=False)
    def test_submit_assignment_blocks_cross_group(self):
        """Student A cannot submit an assignment belonging to Group B."""
        assignment = Assignment.objects.create(
            title="Test",
            group=self.group_b,
            due_date=date(2026, 12, 31),
            created_by=self.teacher_b,
        )
        self.client.force_login(self.student_a.admin)
        response = self.client.post(
            reverse("submit_assignment", args=[assignment.id]),
            {"note": "hacked"},
        )
        self.assertEqual(response.status_code, 403)

    @override_settings(SECURE_SSL_REDIRECT=False)
    def test_student_b_cannot_access_student_home_as_student_a(self):
        """Student B logged in sees their own dashboard, not Student A's."""
        self.client.force_login(self.student_b.admin)
        response = self.client.get(reverse("student_home"))
        self.assertEqual(response.status_code, 200)
        # Student B should NOT see Group A's name in their dashboard
        self.assertNotIn(b"Group A", response.content)


class GroupMessagingTests(TestCase):
    def _make_user(self, email, user_type, login_id=None):
        UserModel = get_user_model()
        return UserModel.objects.create_user(
            email=email,
            password="Pass123!",
            first_name="Test",
            last_name="User",
            user_type=user_type,
            gender="M",
            address="",
            profile_pic="",
            login_id=login_id,
        )

    def setUp(self):
        self.admin_user = self._make_user("chat-admin@iceberg.internal", "1")
        self.course = Course.objects.create(name="Messaging Course")

        self.teacher_a_user = self._make_user("chat-ta@iceberg.internal", "2", "TC81001")
        self.teacher_b_user = self._make_user("chat-tb@iceberg.internal", "2", "TC81002")
        self.teacher_a = Staff.objects.get(admin=self.teacher_a_user)
        self.teacher_b = Staff.objects.get(admin=self.teacher_b_user)

        self.group_a = Group.objects.create(
            name="Messaging Group A",
            course=self.course,
            teacher=self.teacher_a,
        )
        self.group_b = Group.objects.create(
            name="Messaging Group B",
            course=self.course,
            teacher=self.teacher_b,
        )

        self.student_a_user = self._make_user("chat-sa@iceberg.internal", "3", "IC81001")
        self.student_b_user = self._make_user("chat-sb@iceberg.internal", "3", "IC81002")
        self.student_a = Student.objects.get(admin=self.student_a_user)
        self.student_b = Student.objects.get(admin=self.student_b_user)
        Enrollment.objects.create(student=self.student_a, group=self.group_a, is_active=True)
        Enrollment.objects.create(student=self.student_b, group=self.group_b, is_active=True)

    def test_group_thread_created_when_group_created(self):
        self.assertTrue(ChatThread.objects.filter(group=self.group_a).exists())
        self.assertTrue(ChatThread.objects.filter(group=self.group_b).exists())

    @override_settings(**_BASE_OVERRIDES)
    def test_messages_mobile_hub_and_conversation_states_render(self):
        self.client.force_login(self.student_a_user)

        hub_response = self.client.get(reverse("messages"))
        self.assertEqual(hub_response.status_code, 200)
        self.assertContains(hub_response, 'class="ice-chat-app is-hub"')
        self.assertContains(hub_response, "Iceberg Chat")
        self.assertContains(hub_response, "Your group conversations and class channels.")
        self.assertContains(hub_response, "Messaging Group A")

        thread_response = self.client.get(reverse("message_thread", args=[self.group_a.id]))
        self.assertEqual(thread_response.status_code, 200)
        self.assertContains(thread_response, 'class="ice-chat-app is-conversation"')
        self.assertContains(thread_response, 'class="ice-chat-back"')

    @override_settings(**_BASE_OVERRIDES)
    def test_student_can_post_to_own_group_and_teacher_reads(self):
        self.client.force_login(self.student_a_user)
        response = self.client.post(
            reverse("message_thread", args=[self.group_a.id]),
            {"body": "Can we review the assignment tomorrow?"},
        )
        self.assertRedirects(
            response,
            reverse("message_thread", args=[self.group_a.id]) + "#latest",
            fetch_redirect_response=False,
        )
        self.assertTrue(
            ChatMessage.objects.filter(
                thread__group=self.group_a,
                sender=self.student_a_user,
                body="Can we review the assignment tomorrow?",
            ).exists()
        )

        self.client.force_login(self.teacher_a_user)
        response = self.client.get(reverse("message_thread", args=[self.group_a.id]))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Can we review the assignment tomorrow?")

    @override_settings(**_BASE_OVERRIDES)
    def test_student_cannot_access_other_group_chat(self):
        self.client.force_login(self.student_a_user)
        response = self.client.get(reverse("message_thread", args=[self.group_b.id]))
        self.assertEqual(response.status_code, 403)

    @override_settings(**_BASE_OVERRIDES)
    def test_admin_can_access_all_group_chats_and_post(self):
        self.client.force_login(self.admin_user)
        response = self.client.post(
            reverse("message_thread", args=[self.group_b.id]),
            {"body": "Schedule update for Group B."},
        )
        self.assertRedirects(
            response,
            reverse("message_thread", args=[self.group_b.id]) + "#latest",
            fetch_redirect_response=False,
        )
        self.assertTrue(
            ChatMessage.objects.filter(
                thread__group=self.group_b,
                sender=self.admin_user,
                body="Schedule update for Group B.",
            ).exists()
        )

    @override_settings(**_BASE_OVERRIDES)
    def test_unread_count_excludes_own_messages_and_clears_on_read(self):
        thread = ChatThread.objects.get(group=self.group_a)
        ChatMessage.objects.create(
            thread=thread,
            sender=self.teacher_a_user,
            body="Please check the new material.",
        )
        ChatReadState.objects.create(thread=thread, user=self.teacher_a_user)

        self.assertEqual(unread_message_count(self.teacher_a_user), 0)
        self.assertEqual(unread_message_count(self.student_a_user), 1)

        self.client.force_login(self.student_a_user)
        response = self.client.get(reverse("message_thread", args=[self.group_a.id]))
        self.assertEqual(response.status_code, 200)
        self.assertEqual(unread_message_count(self.student_a_user), 0)


class BranchIsolationTests(TestCase):
    """Branch-first access control: super admin vs branch admin vs teacher vs student."""

    def _make_user(self, email, user_type, login_id=None):
        UserModel = get_user_model()
        return UserModel.objects.create_user(
            email=email,
            password="Pass123!",
            first_name="Test",
            last_name="User",
            user_type=user_type,
            gender="M",
            address="",
            profile_pic="",
            login_id=login_id,
        )

    def setUp(self):
        from main_app.models import Admin, Branch

        self.branch_a = Branch.objects.create(name="Branch A")
        self.branch_b = Branch.objects.create(name="Branch B")
        self.course = Course.objects.create(name="Branch Course")

        # Super admin (default flag is True).
        self.super_admin_user = self._make_user("super@iceberg.internal", "1")
        self.super_admin = Admin.objects.get(admin=self.super_admin_user)

        # Branch admin scoped to Branch A only. Mutate through the user's own
        # cached reverse accessor so is_super_admin reads back consistently
        # (the post_save signal pre-populates user.admin at creation time).
        self.branch_admin_user = self._make_user("ba@iceberg.internal", "1")
        self.branch_admin = self.branch_admin_user.admin
        self.branch_admin.is_super_admin = False
        self.branch_admin.save()
        self.branch_admin.branches.add(self.branch_a)

        # Teacher with one group in Branch A.
        self.teacher_a_user = self._make_user("bta@iceberg.internal", "2", "TC90001")
        self.teacher_a = Staff.objects.get(admin=self.teacher_a_user)
        self.teacher_a.branch = self.branch_a
        self.teacher_a.save()

        self.teacher_b_user = self._make_user("btb@iceberg.internal", "2", "TC90002")
        self.teacher_b = Staff.objects.get(admin=self.teacher_b_user)
        self.teacher_b.branch = self.branch_b
        self.teacher_b.save()

        self.group_a = Group.objects.create(
            name="Branch A Group", course=self.course, teacher=self.teacher_a, branch=self.branch_a
        )
        self.group_b = Group.objects.create(
            name="Branch B Group", course=self.course, teacher=self.teacher_b, branch=self.branch_b
        )

        self.student_a_user = self._make_user("bsa@iceberg.internal", "3", "IC90001")
        self.student_b_user = self._make_user("bsb@iceberg.internal", "3", "IC90002")
        self.student_a = Student.objects.get(admin=self.student_a_user)
        self.student_b = Student.objects.get(admin=self.student_b_user)
        self.student_a.branch = self.branch_a
        self.student_a.save()
        self.student_b.branch = self.branch_b
        self.student_b.save()
        Enrollment.objects.create(student=self.student_a, group=self.group_a, is_active=True)
        Enrollment.objects.create(student=self.student_b, group=self.group_b, is_active=True)

    # ── 1 & 9: super admin sees everything (and stays super after migration) ──
    def test_super_admin_sees_all(self):
        from main_app import branching

        self.assertTrue(branching.is_super_admin(self.super_admin_user))
        self.assertEqual(
            branching.filter_groups_for_user(self.super_admin_user, Group.objects.all()).count(), 2
        )
        self.assertEqual(
            branching.filter_students_for_user(self.super_admin_user, Student.objects.all()).count(),
            2,
        )
        self.assertEqual(
            branching.get_accessible_branches(self.super_admin_user).count(), 2
        )

    # ── 2: branch admin sees only Branch A ──
    def test_branch_admin_scoped_to_branch_a(self):
        from main_app import branching

        self.assertFalse(branching.is_super_admin(self.branch_admin_user))
        groups = branching.filter_groups_for_user(self.branch_admin_user, Group.objects.all())
        self.assertEqual(list(groups), [self.group_a])
        students = branching.filter_students_for_user(self.branch_admin_user, Student.objects.all())
        self.assertEqual(list(students), [self.student_a])
        staff = branching.filter_staff_for_user(self.branch_admin_user, Staff.objects.all())
        self.assertIn(self.teacher_a, staff)
        self.assertNotIn(self.teacher_b, staff)

    # ── 3: branch admin cannot open Branch B group detail by URL ──
    @override_settings(**_BASE_OVERRIDES)
    def test_branch_admin_cannot_open_other_branch_group(self):
        self.client.force_login(self.branch_admin_user)
        response = self.client.get(reverse("admin_group_detail", args=[self.group_b.id]))
        self.assertRedirects(
            response, reverse("manage_group"), fetch_redirect_response=False
        )
        # Own branch group works.
        ok = self.client.get(reverse("admin_group_detail", args=[self.group_a.id]))
        self.assertEqual(ok.status_code, 200)

    # ── 4: branch admin cannot fetch Branch B attendance by forged POST ──
    @override_settings(**_BASE_OVERRIDES)
    def test_branch_admin_cannot_fetch_other_branch_attendance(self):
        attendance_b = Attendance.objects.create(group=self.group_b, date=date.today())
        self.client.force_login(self.branch_admin_user)
        forged = self.client.post(
            reverse("get_admin_attendance"), {"attendance_date_id": str(attendance_b.id)}
        )
        self.assertEqual(forged.status_code, 403)

    # ── 5: teacher sees only their groups ──
    def test_teacher_sees_only_own_groups(self):
        from main_app import branching

        groups = branching.filter_groups_for_user(self.teacher_a_user, Group.objects.all())
        self.assertEqual(list(groups), [self.group_a])

    # ── 6: student sees only own groups ──
    def test_student_sees_only_own_groups(self):
        from main_app import branching

        groups = branching.filter_groups_for_user(self.student_a_user, Group.objects.all())
        self.assertEqual(list(groups), [self.group_a])

    # ── 7: messaging respects branch admin scope ──
    def test_messaging_respects_branch_admin_scope(self):
        from main_app.messaging import accessible_groups_for_user

        super_groups = accessible_groups_for_user(self.super_admin_user)
        self.assertEqual(super_groups.count(), 2)
        ba_groups = accessible_groups_for_user(self.branch_admin_user)
        self.assertEqual(list(ba_groups), [self.group_a])

    # ── 8: enrollment form rejects cross-branch student/group ──
    def test_enrollment_form_rejects_branch_mismatch(self):
        from main_app.forms import EnrollmentForm

        form = EnrollmentForm(
            data={"group": self.group_a.id, "student": self.student_b.id, "is_active": "True"},
            user=self.super_admin_user,
        )
        self.assertFalse(form.is_valid())
        self.assertIn("group", form.errors)

    # ── 10: null-branch records don't crash management pages ──
    @override_settings(**_BASE_OVERRIDES)
    def test_null_branch_student_does_not_crash_pages(self):
        orphan_user = self._make_user("orphan@iceberg.internal", "3", "IC99999")
        orphan = Student.objects.get(admin=orphan_user)
        orphan.branch = None
        orphan.save()
        # Super admin manage_student renders without error.
        self.client.force_login(self.super_admin_user)
        response = self.client.get(reverse("manage_student"))
        self.assertEqual(response.status_code, 200)
        # Branch admin page also renders (orphan simply isn't shown).
        self.client.force_login(self.branch_admin_user)
        response = self.client.get(reverse("manage_student"))
        self.assertEqual(response.status_code, 200)
