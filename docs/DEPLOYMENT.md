# Deployment Guide

This document covers all deployment options for the Iceberg College ERP.

---

## 1. DigitalOcean App Platform (primary)

The primary deployment uses DigitalOcean App Platform, configured in `.do/app.yaml`.

### How it works

- **Service** (`web`): builds the Django app from `backend/`, installs
  requirements, runs `collectstatic`, and starts Gunicorn.
- **Pre-deploy job** (`db-migrate`): runs `manage.py migrate` before traffic is
  switched to the new release, guaranteeing zero-downtime schema changes.
- `source_dir: /backend` tells App Platform that the Django root is `backend/`,
  so `requirements.txt` and `manage.py` are found there automatically.

### Required environment variables (set in App Platform dashboard)

| Variable | Description |
|---|---|
| `DJANGO_SECRET_KEY` | Long random string — generate with `get_random_secret_key()` |
| `DATABASE_URL` | DigitalOcean managed PostgreSQL connection string |
| `DJANGO_ALLOWED_HOSTS` | `${APP_DOMAIN},app.iceberglc.com` |
| `CORS_ALLOWED_ORIGINS` | Comma-separated allowed origins for the public website |
| `CSRF_TRUSTED_ORIGINS` | `https://${APP_DOMAIN},https://app.iceberglc.com` |
| `EMAIL_HOST_USER` | Gmail (or SMTP) sender address |
| `EMAIL_HOST_PASSWORD` | Gmail App Password |
| `FCM_SERVER_KEY` | Firebase server key for push notifications |
| `RECOVERY_ADMIN_EMAIL` | Fallback admin email |
| `RECOVERY_ADMIN_PASSWORD` | Fallback admin password |
| `REGISTRATION_LEADS_API_TOKEN` | Shared secret for the public registration form |

### Deploying

Push to `main` — `deploy_on_push: true` triggers a deployment automatically.
Monitor progress in the DigitalOcean dashboard.

---

## 2. VPS / Self-hosted (Ubuntu 22.04)

Use `infra/deploy/setup.sh` to set up a fresh server.

```bash
# As root on a fresh Ubuntu 22.04 server:
curl -sSL https://raw.githubusercontent.com/iceberglc/College-ERP/main/infra/deploy/setup.sh | sudo bash
```

The script:
1. Installs nginx, certbot, Python 3.11, PostgreSQL, and build tools.
2. Clones the repository to `/home/iceberg/College-ERP`.
3. Creates a virtualenv and installs `backend/requirements.txt`.
4. Creates `.env` from `.env.example` (edit before first run!).
5. Runs `migrate` and `collectstatic`.
6. Installs the Gunicorn systemd service (`infra/deploy/gunicorn.service`).
7. Configures nginx (`infra/deploy/nginx.conf`) and obtains an SSL certificate.

### Post-setup

Edit `/home/iceberg/College-ERP/.env` to set `DATABASE_URL`, email credentials, etc.,
then:

```bash
sudo systemctl start gunicorn-iceberg
sudo systemctl status gunicorn-iceberg
```

Logs: `sudo journalctl -u gunicorn-iceberg -f`

---

## 3. Local development

```bash
# 1. Clone the repo
git clone https://github.com/iceberglc/College-ERP.git
cd College-ERP

# 2. Set up environment
cp .env.example .env    # edit DATABASE_URL, etc.

# 3. Create virtualenv and install dependencies
python3.11 -m venv venv
source venv/bin/activate
pip install -r backend/requirements.txt

# 4. Run migrations
cd backend
python manage.py migrate

# 5. Start dev server
python manage.py runserver
```

Visit http://127.0.0.1:8000/

---

## 4. Database migrations

Migrations run automatically on DigitalOcean via the pre-deploy job.

On VPS or local dev:

```bash
cd backend
python manage.py migrate
```

After modifying models, generate a new migration:

```bash
python manage.py makemigrations
python manage.py migrate
```

---

## 5. Flutter web rebuild

To update the web app served at `/app/`:

```bash
cd mobile/iceberg_app
flutter build web --release --output ../../web/flutter_web
git add ../../web/flutter_web/
git commit -m "chore: rebuild flutter web"
git push
```

The next DigitalOcean deploy will serve the updated build.

---

## 6. Environment variables reference

See `/.env.example` for a complete, commented list of all environment variables.

| Variable | Required | Description |
|---|---|---|
| `DJANGO_SECRET_KEY` | Yes | Django secret key (50+ char random string) |
| `DATABASE_URL` | Prod only | PostgreSQL connection URL |
| `DJANGO_DEBUG` | No | `True` for dev, `False` (default) for prod |
| `DJANGO_ALLOWED_HOSTS` | Prod only | Comma-separated allowed hostnames |
| `DJANGO_MEDIA_ROOT` | No | Path to user uploads directory |
| `FLUTTER_WEB_DIR` | No | Override path to Flutter web build |
| `EMAIL_HOST_USER` | No | SMTP sender email |
| `EMAIL_HOST_PASSWORD` | No | SMTP password / App Password |
| `FCM_SERVER_KEY` | No | Firebase server key for push notifications |
| `CORS_ALLOWED_ORIGINS` | No | Comma-separated CORS origins |
| `CSRF_TRUSTED_ORIGINS` | No | Comma-separated trusted origins |
| `REGISTRATION_LEADS_API_TOKEN` | No | Token for public registration API |
| `RECOVERY_ADMIN_EMAIL` | No | Fallback admin login email |
| `RECOVERY_ADMIN_PASSWORD` | No | Fallback admin login password |
| `SPACES_KEY` / `SPACES_SECRET` | No | DigitalOcean Spaces credentials for media |
| `SPACES_BUCKET` | No | Spaces bucket name |
| `SPACES_REGION` | No | Spaces region (e.g. `fra1`) |
