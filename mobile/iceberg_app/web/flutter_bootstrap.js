{{flutter_js}}
{{flutter_build_config}}

// Serve CanvasKit from our own host instead of gstatic CDN, so the app is
// fully self-contained (works offline / behind strict firewalls).
_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  },
  config: {
    canvasKitBaseUrl: "canvaskit/"
  }
});
