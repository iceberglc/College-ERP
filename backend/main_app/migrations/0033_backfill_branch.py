"""Backfill branch-first fields for the branch isolation rollout.

Safe by design:
  * Branch fields stay nullable — records without a derivable branch are left
    NULL (the audit_branch_integrity command surfaces them for manual cleanup).
  * Existing Admin profiles are forced to is_super_admin=True so no current
    admin is locked out of branches they used to manage.
  * Reverse migration is a no-op (we never want to wipe branch assignments).
"""

from django.db import migrations


def backfill_branches(apps, schema_editor):
    Student = apps.get_model("main_app", "Student")
    Staff = apps.get_model("main_app", "Staff")
    Group = apps.get_model("main_app", "Group")
    Enrollment = apps.get_model("main_app", "Enrollment")
    Admin = apps.get_model("main_app", "Admin")

    # Existing admins remain super admins (default is already True, but make it
    # explicit and idempotent in case any row was created differently).
    Admin.objects.update(is_super_admin=True)

    # Students: take the branch of their first active enrollment group.
    student_updates = []
    for student in Student.objects.filter(branch__isnull=True):
        enrollment = (
            Enrollment.objects.filter(
                student=student, is_active=True, group__branch__isnull=False
            )
            .select_related("group")
            .first()
        )
        if enrollment is not None:
            student.branch_id = enrollment.group.branch_id
            student_updates.append(student)
    if student_updates:
        Student.objects.bulk_update(student_updates, ["branch"])

    # Teachers: take the branch of the first group they teach that has one.
    staff_updates = []
    for staff in Staff.objects.filter(branch__isnull=True):
        group = (
            Group.objects.filter(teacher=staff, branch__isnull=False)
            .order_by("id")
            .first()
        )
        if group is not None:
            staff.branch_id = group.branch_id
            staff_updates.append(staff)
    if staff_updates:
        Staff.objects.bulk_update(staff_updates, ["branch"])


def noop_reverse(apps, schema_editor):
    # Intentionally do nothing on reverse — branch assignments are kept.
    pass


class Migration(migrations.Migration):
    dependencies = [
        ("main_app", "0032_admin_branches_admin_is_super_admin_staff_branch_and_more"),
    ]

    operations = [
        migrations.RunPython(backfill_branches, noop_reverse),
    ]
