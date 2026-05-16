from django.contrib.auth.backends import ModelBackend
from django.contrib.auth import get_user_model


class EmailBackend(ModelBackend):
    """Dual-mode authentication backend.

    - Admin (user_type='1'): authenticates by email address.
    - Staff (user_type='2') and Student (user_type='3'): authenticates by login_id.

    The identifier field in the login form is named 'identifier'.  Django's
    authenticate() receives it as the 'username' keyword argument (set by the
    login view before calling authenticate).
    """

    def authenticate(self, request, username=None, password=None, **kwargs):
        UserModel = get_user_model()
        identifier = username or kwargs.get('identifier')
        if identifier is None:
            identifier = kwargs.get(UserModel.USERNAME_FIELD)
        if not identifier or not password:
            return None
        identifier = identifier.strip()

        user = None
        if '@' in identifier:
            # Looks like an email address — only valid for admin accounts.
            try:
                user = UserModel.objects.get(email__iexact=identifier)
            except UserModel.DoesNotExist:
                return None
            if user.user_type != '1':
                # Staff/students must use their login_id, not their email.
                return None
        else:
            # Not an email — treat as login_id (staff/student only).
            try:
                user = UserModel.objects.get(login_id__iexact=identifier)
            except UserModel.DoesNotExist:
                return None
            if user.user_type == '1':
                # Admin cannot log in with a login_id — must use email.
                return None

        if user.check_password(password) and self.user_can_authenticate(user):
            return user
        return None
