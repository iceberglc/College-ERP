from django.db import migrations


def strip_media_prefix(apps, schema_editor):
    """Strip leading /media/ from profile_pic values stored as full URL paths."""
    from django.db import connection
    with connection.cursor() as cursor:
        cursor.execute(
            "UPDATE main_app_customuser SET profile_pic = SUBSTR(profile_pic, 8) "
            "WHERE profile_pic LIKE '/media/%'"
        )


def restore_media_prefix(apps, schema_editor):
    """Reverse: prepend /media/ to bare filenames."""
    from django.db import connection
    with connection.cursor() as cursor:
        cursor.execute(
            "UPDATE main_app_customuser SET profile_pic = '/media/' || profile_pic "
            "WHERE profile_pic != '' AND profile_pic NOT LIKE '/%' AND profile_pic NOT LIKE 'http%'"
        )


class Migration(migrations.Migration):

    dependencies = [
        ('main_app', '0017_step2_restructure_models'),
    ]

    operations = [
        migrations.RunPython(strip_media_prefix, restore_media_prefix),
    ]
