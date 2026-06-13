{{flutter_js}}
{{flutter_build_config}}

// Serve CanvasKit from our own host instead of the gstatic CDN, so the app is
// fully self-contained (works offline / behind strict firewalls).
//
// NOTE: the service worker is intentionally NOT registered. A precaching
// service worker repeatedly caused a stale main.dart.js to be served after a
// redeploy, hanging the boot splash (notably on iOS Safari). Assets are served
// fresh from the backend (which sends no-cache headers for .js), so the PWA
// service worker is unnecessary and removing it makes deploys reliable.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/"
  }
});
