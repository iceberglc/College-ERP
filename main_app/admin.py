from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import (
    CustomUser, Admin, Staff, Student, Course, Book, Loan,
    Subject, Session, Branch, Group, Enrollment, Assignment,
    Submission, Notification,
)


@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    ordering = ('email',)
    list_display  = ('login_id', 'email', 'first_name', 'last_name', 'user_type', 'is_active')
    list_filter   = ('user_type', 'is_active', 'gender')
    search_fields = ('login_id', 'email', 'first_name', 'last_name')
    readonly_fields = ('login_id', 'created_at', 'updated_at')

    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('ICE Identity', {'fields': ('login_id', 'user_type')}),
        ('Personal info', {'fields': ('first_name', 'last_name', 'gender', 'profile_pic', 'avatar', 'address')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        ('Timestamps', {'fields': ('created_at', 'updated_at', 'last_login', 'date_joined')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'password1', 'password2', 'user_type', 'first_name', 'last_name'),
        }),
    )

    def get_user_type_display(self, obj):
        return obj.get_user_type_display()
    get_user_type_display.short_description = 'Role'


@admin.register(Staff)
class StaffAdmin(admin.ModelAdmin):
    list_display  = ('teacher_id', 'full_name', 'course', 'is_active')
    list_filter   = ('is_active', 'course')
    search_fields = ('admin__login_id', 'admin__first_name', 'admin__last_name', 'admin__email')
    raw_id_fields = ('admin',)

    def teacher_id(self, obj):
        return obj.admin.login_id or '—'
    teacher_id.short_description = 'Teacher ID'

    def full_name(self, obj):
        return f"{obj.admin.first_name} {obj.admin.last_name}".strip() or obj.admin.email
    full_name.short_description = 'Name'


@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display  = ('ice_id', 'full_name', 'course', 'status')
    list_filter   = ('status', 'course')
    search_fields = ('admin__login_id', 'admin__first_name', 'admin__last_name', 'admin__email')
    raw_id_fields = ('admin',)

    def ice_id(self, obj):
        return obj.admin.login_id or '—'
    ice_id.short_description = 'ICE ID'

    def full_name(self, obj):
        return f"{obj.admin.first_name} {obj.admin.last_name}".strip() or obj.admin.email
    full_name.short_description = 'Name'


admin.site.register(Course)
admin.site.register(Book)
admin.site.register(Loan)
admin.site.register(Subject)
admin.site.register(Session)
admin.site.register(Branch)
admin.site.register(Group)
admin.site.register(Enrollment)
admin.site.register(Assignment)
admin.site.register(Submission)
admin.site.register(Notification)
