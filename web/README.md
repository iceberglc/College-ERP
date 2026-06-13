# Web — Flutter Web Build Artifacts

This directory contains the pre-built Flutter web application that the Django backend
serves at `/app/`.

## Directory layout

```
web/
└── flutter_web/    Built output from `flutter build web`
    ├── main.dart.js
    ├── index.html
    ├── flutter.js
    ├── flutter_bootstrap.js
    ├── flutter_service_worker.js
    ├── assets/
    └── canvaskit/  (excluded from git — large binary, excluded in .gitignore)
```

## How the artifacts get here

The Flutter web build output must be placed in `web/flutter_web/` so that Django can
serve it. To rebuild:

```bash
cd mobile/iceberg_app
flutter build web --release --output ../../web/flutter_web
```

Django serves the contents at `/app/` via `flutter_view.py`. The path can be
overridden with the `FLUTTER_WEB_DIR` environment variable.

## Updating the deployed web app

1. Rebuild: `cd mobile/iceberg_app && flutter build web --release --output ../../web/flutter_web`
2. Commit the updated build artifacts (excluding `canvaskit/` which is in `.gitignore`): `git add web/flutter_web/ && git commit -m "chore: rebuild flutter web"`
3. Push to main — the DigitalOcean App Platform deployment picks it up automatically.
