from django.db import migrations, models
import django.db.models.deletion
import django.utils.timezone


class Migration(migrations.Migration):

    dependencies = [
        ('main_app', '0022_study_center_levels'),
    ]

    operations = [
        # Add 'vocabulary' category + 'link' field to Notification
        migrations.AddField(
            model_name='notification',
            name='link',
            field=models.CharField(
                blank=True, default='', max_length=500,
                help_text='Optional URL the notification links to',
            ),
        ),
        migrations.AlterField(
            model_name='notification',
            name='category',
            field=models.CharField(
                choices=[
                    ('attendance', 'Attendance'),
                    ('result', 'Result'),
                    ('announcement', 'Announcement'),
                    ('homework', 'Homework'),
                    ('vocabulary', 'Vocabulary'),
                    ('general', 'General'),
                ],
                default='general', max_length=20,
            ),
        ),

        # VocabularyDay
        migrations.CreateModel(
            name='VocabularyDay',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('day_number', models.PositiveIntegerField(help_text='Day 1, Day 2, …')),
                ('title', models.CharField(blank=True, default='', max_length=200,
                                           help_text='Optional title, e.g. "Describing People"')),
                ('level', models.PositiveSmallIntegerField(
                    null=True, blank=True,
                    help_text='Target level (1–6). Leave blank to inherit the group default.',
                )),
                ('release_at', models.DateTimeField(
                    help_text='Words become visible to students at this date/time.',
                )),
                ('notes', models.TextField(blank=True, default='')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('created_by', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='vocabulary_days', to='main_app.staff',
                )),
                ('group', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='vocabulary_days', to='main_app.group',
                )),
                ('notified_students', models.ManyToManyField(
                    blank=True, related_name='notified_vocab_days', to='main_app.student',
                )),
            ],
            options={'ordering': ['day_number']},
        ),
        migrations.AddConstraint(
            model_name='vocabularyday',
            constraint=models.UniqueConstraint(
                fields=['group', 'day_number'], name='unique_group_day',
            ),
        ),

        # VocabularyDayWord
        migrations.CreateModel(
            name='VocabularyDayWord',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('word', models.CharField(max_length=200)),
                ('meaning', models.TextField()),
                ('example_sentence', models.TextField(blank=True, default='')),
                ('pronunciation_note', models.CharField(blank=True, default='', max_length=300)),
                ('order', models.PositiveSmallIntegerField(default=0)),
                ('day', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='words', to='main_app.vocabularyday',
                )),
            ],
            options={'ordering': ['order', 'id']},
        ),

        # VocabularyDayCompletion
        migrations.CreateModel(
            name='VocabularyDayCompletion',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('completed_at', models.DateTimeField(auto_now_add=True)),
                ('day', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='completions', to='main_app.vocabularyday',
                )),
                ('student', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='day_completions', to='main_app.student',
                )),
            ],
            options={'unique_together': {('student', 'day')}},
        ),

        # VocabularyQuizResult
        migrations.CreateModel(
            name='VocabularyQuizResult',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('score', models.FloatField(help_text='Percentage 0–100')),
                ('correct', models.PositiveIntegerField(default=0)),
                ('total', models.PositiveIntegerField(default=0)),
                ('taken_at', models.DateTimeField(auto_now_add=True)),
                ('day', models.ForeignKey(
                    null=True, blank=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name='quiz_results', to='main_app.vocabularyday',
                )),
                ('student', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='quiz_results', to='main_app.student',
                )),
            ],
            options={'ordering': ['-taken_at']},
        ),
    ]
