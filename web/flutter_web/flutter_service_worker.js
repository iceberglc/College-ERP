// Self-destructing service worker (kill switch).
//
// Earlier builds registered a precaching Flutter service worker that could
// serve a stale main.dart.js / index.html after a redeploy and hang the boot
// splash (notably on iOS Safari). The app no longer registers a service
// worker. This file replaces the old one at the same URL so that any browser
// still holding the old worker fetches this on its next update check, then:
//   1. deletes all caches,
//   2. unregisters itself,
//   3. reloads every open tab so the fresh, network-served app loads.
self.addEventListener('install', function (event) {
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  event.waitUntil((async function () {
    try {
      const keys = await caches.keys();
      await Promise.all(keys.map(function (k) { return caches.delete(k); }));
    } catch (e) { /* ignore */ }
    try {
      await self.registration.unregister();
    } catch (e) { /* ignore */ }
    try {
      const clients = await self.clients.matchAll({ type: 'window' });
      clients.forEach(function (client) {
        client.navigate(client.url);
      });
    } catch (e) { /* ignore */ }
  })());
});

// Never intercept fetches — always go to the network.
self.addEventListener('fetch', function (event) {});
