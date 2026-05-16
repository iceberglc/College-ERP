from django.db import migrations


def generate_login_ids(apps, schema_editor):
    CustomUser = apps.get_model('main_app', 'CustomUser')

    staff_counter = 1
    student_counter = 1

    for user in CustomUser.objects.filter(user_type='2').order_by('id'):
        user.login_id = f'TCH-{staff_counter:04d}'
        user.save(update_fields=['login_id'])
        staff_counter += 1

    for user in CustomUser.objects.filter(user_type='3').order_by('id'):
        user.login_id = f'STU-{student_counter:04d}'
        user.save(update_fields=['login_id'])
        student_counter += 1


class Migration(migrations.Migration):

    dependencies = [
        ('main_app', '0019_login_id_field'),
    ]

    operations = [
        migrations.RunPython(generate_login_ids, migrations.RunPython.noop),
    ]
