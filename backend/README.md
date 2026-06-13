# Backend — Django ERP

This directory contains the Django application that powers the Iceberg Language Center ERP system.

## Directory layout

```
backend/
├── college_management_system/   Django project settings, URLs, wsgi/asgi
├── main_app/                    Main application (models, views, API, templates)
│   ├── api/                     REST API (DRF) consumed by the Flutter clients
│   │   ├── views/               Split view package (auth, courses, attendance, …)
│   │   ├── admin_views.py       Admin-only CRUD endpoints
│   │   ├── student_views.py     Student-specific endpoints
│   │   ├── serializers.py
│   │   ├── permissions.py
│   │   └── urls.py
│   ├── migrations/
│   ├── templates/
│   └── static/
├── manage.py
├── requirements.txt
├── runtime.txt
└── ruff.toml
```

## Local setup

```bash
# 1. Create and activate a virtual environment
python3.11 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate

# 2. Install dependencies
pip install -r backend/requirements.txt

# 3. Configure environment
cp .env.example .env            # from repo root; edit values

# 4. Run migrations
cd backend
python manage.py migrate

# 5. Create a superuser (first run only)
python manage.py createsuperuser

# 6. Start the development server
python manage.py runserver
```

The admin panel is at http://127.0.0.1:8000/admin/ and the web ERP at http://127.0.0.1:8000/.

## Environment variables

All variables are documented in `/.env.example` at the repository root.
Required in production: `DJANGO_SECRET_KEY`, `DATABASE_URL`, `DJANGO_ALLOWED_HOSTS`.

## Running tests

```bash
cd backend
python manage.py test
```

## API

The REST API is mounted at `/api/v1/` and uses JWT authentication (SimpleJWT).

Key endpoints:
- `POST /api/v1/auth/login/` — obtain access + refresh tokens
- `GET  /api/v1/me/` — current user profile
- `GET  /api/v1/groups/` — list groups visible to the authenticated user
- `GET  /api/v1/attendance/` — attendance records
- `GET  /api/v1/admin/home/` — admin dashboard data

Full URL map: `backend/main_app/api/urls.py`

## Linting

```bash
cd backend
ruff check .
ruff format .
```

Configuration: `backend/ruff.toml`
