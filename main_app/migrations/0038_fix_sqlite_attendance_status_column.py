"""Repair AttendanceReport.status column type on SQLite.

Migration 0006 switched the field bool → smallint with
``SeparateDatabaseAndState`` and only ran ALTER TABLE on PostgreSQL.
On SQLite the column kept its ``bool`` declared type, and Django's
sqlite3 converter (registered for the ``bool`` decltype) reads any
stored value other than 1 as ``False`` — so the LATE status (2) was
silently collapsed to ABSENT on SQLite databases, including every
test database.

This migration rebuilds the column with the correct ``smallint`` type
on SQLite. PostgreSQL was already converted by 0006 and is skipped.
"""

from django.db import migrations, models


def fix_sqlite_column(apps, schema_editor):
    if schema_editor.connection.vendor != "sqlite":
        return
    AttendanceReport = apps.get_model("main_app", "AttendanceReport")
    old_field = models.BooleanField(default=False)
    old_field.set_attributes_from_name("status")
    new_field = models.SmallIntegerField(
        choices=[(0, "Absent"), (1, "Present"), (2, "Late")], default=0
    )
    new_field.set_attributes_from_name("status")
    # alter_field performs the full SQLite table rebuild, preserving data,
    # indexes and foreign keys.
    schema_editor.alter_field(AttendanceReport, old_field, new_field)


class Migration(migrations.Migration):

    dependencies = [
        ("main_app", "0037_student_app_settings"),
    ]

    operations = [
        migrations.RunPython(fix_sqlite_column, migrations.RunPython.noop),
    ]
