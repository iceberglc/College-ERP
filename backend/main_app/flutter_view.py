import os
import mimetypes
from pathlib import Path
from django.http import FileResponse, Http404, HttpResponse
from django.conf import settings

FLUTTER_DIR = os.environ.get(
    'FLUTTER_WEB_DIR',
    str(Path(settings.BASE_DIR).parent / 'web' / 'flutter_web')
)


def flutter_app(request, path='/'):
    # Strip leading slash and default to index.html
    rel = path.lstrip('/')

    if not rel:
        rel = 'index.html'

    file_path = os.path.realpath(os.path.join(FLUTTER_DIR, rel))

    # Security: block path traversal
    if not file_path.startswith(os.path.realpath(FLUTTER_DIR)):
        raise Http404

    if os.path.isfile(file_path):
        mime, _ = mimetypes.guess_type(file_path)
        response = FileResponse(open(file_path, 'rb'), content_type=mime or 'application/octet-stream')
        # Flutter service worker needs exact scope headers
        if rel == 'flutter_service_worker.js' or rel.endswith('.js'):
            response['Cache-Control'] = 'no-cache'
        return response

    # SPA fallback: any unknown path returns index.html so Flutter's router handles it
    index = os.path.join(FLUTTER_DIR, 'index.html')
    if os.path.isfile(index):
        return FileResponse(open(index, 'rb'), content_type='text/html')

    raise Http404
