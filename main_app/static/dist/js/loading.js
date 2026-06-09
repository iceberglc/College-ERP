/* ============================================================================
   ICEBERG · loading.js
   Perceived-speed layer: top progress bar + delayed page loader + form
   submit feedback. Pure progressive enhancement — if this file fails to load,
   links and forms behave exactly as normal server-rendered navigation.
   ========================================================================== */
(function () {
  'use strict';

  var OVERLAY_DELAY = 220;   // only show the heavy overlay if nav is slow
  var showTimer = null;

  function progress() { return document.getElementById('ice-progress'); }
  function overlay()  { return document.getElementById('ice-loader'); }

  function start() {
    var p = progress();
    if (p) { p.classList.remove('is-active'); void p.offsetWidth; p.classList.add('is-active'); }
    clearTimeout(showTimer);
    showTimer = setTimeout(function () {
      var o = overlay();
      if (o) o.classList.add('is-visible');
    }, OVERLAY_DELAY);
  }

  function stop() {
    clearTimeout(showTimer);
    var p = progress();
    if (p) p.classList.remove('is-active');
    var o = overlay();
    if (o) o.classList.remove('is-visible');
  }

  // ── Internal link clicks ────────────────────────────────────────────────
  document.addEventListener('click', function (e) {
    // Only plain left-clicks with no modifiers.
    if (e.button !== 0 || e.ctrlKey || e.metaKey || e.shiftKey || e.altKey) return;
    var a = e.target.closest('a[href]');
    if (!a || e.defaultPrevented) return;
    if (a.hasAttribute('download') || a.hasAttribute('data-no-loader')) return;
    if (a.target && a.target !== '_self') return;

    var raw = a.getAttribute('href') || '';
    if (/^(mailto:|tel:|javascript:|#)/i.test(raw)) return;

    var url;
    try { url = new URL(a.href, location.href); } catch (_) { return; }
    if (url.origin !== location.origin) return;                 // external
    // Same-page hash navigation — no page load.
    if (url.pathname === location.pathname &&
        url.search === location.search && url.hash) return;

    start();
  }, true);

  // ── Form submissions ────────────────────────────────────────────────────
  document.addEventListener('submit', function (e) {
    var f = e.target;
    if (!f || f.nodeName !== 'FORM') return;
    // The animated-logout component runs its own choreography + progress.
    if (f.hasAttribute('data-animated-logout')) return;

    if (!f.hasAttribute('data-no-disable')) {
      var btn = f.querySelector('button[type="submit"], input[type="submit"]');
      if (btn && !btn.disabled) {
        btn.classList.add('btn-loading', 'is-loading');
        // Disable AFTER the submit is dispatched so the button value still posts.
        setTimeout(function () { try { btn.disabled = true; } catch (_) {} }, 0);
      }
    }
    if (!f.hasAttribute('data-no-loader')) start();
  }, true);

  // ── Never let the loader get stuck ──────────────────────────────────────
  // Fires on normal load AND on bfcache restore (back/forward).
  window.addEventListener('pageshow', stop);
  window.addEventListener('load', stop);
  document.addEventListener('DOMContentLoaded', stop);
  // If the tab becomes visible again after a cancelled navigation, clear it.
  document.addEventListener('visibilitychange', function () {
    if (document.visibilityState === 'visible') stop();
  });

  // Expose a tiny hook so other scripts can drive it if needed.
  window.iceLoader = { start: start, stop: stop };
})();
