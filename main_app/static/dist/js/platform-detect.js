/* =====================================================================
   Platform detection — sets an adaptive look class on <html>.

   Adds exactly one of:
     .platform-apple    iPhone / iPad / Mac (→ "Liquid Glass" theme)
     .platform-android  Android devices       (→ solid Material theme)
     .platform-other    everything / unknown  (→ solid Material theme)

   Loaded synchronously in <head> BEFORE the stylesheets so the class is
   present when CSS first matches (no flash of the wrong theme).

   Manual override for testing (persisted in localStorage):
     ?platform=apple | android | other   → force a look
     ?platform=auto                       → clear the override
   ===================================================================== */
(function () {
  'use strict';

  var docEl = document.documentElement;
  var cls = null;

  /* ── Manual override (testing) ─────────────────────────────────────── */
  try {
    var q = new URLSearchParams(window.location.search).get('platform');
    if (q === 'auto') {
      localStorage.removeItem('ui_platform_override');
    } else if (q === 'apple' || q === 'android' || q === 'other') {
      localStorage.setItem('ui_platform_override', q);
    }
    var override = localStorage.getItem('ui_platform_override');
    if (override === 'apple' || override === 'android' || override === 'other') {
      cls = 'platform-' + override;
    }
  } catch (e) { /* localStorage/URL unavailable — fall through to detection */ }

  /* ── Auto detection ────────────────────────────────────────────────── */
  if (!cls) {
    var ua = navigator.userAgent || '';
    var plat = navigator.platform || '';
    var maxTouch = navigator.maxTouchPoints || 0;

    var isIOS = /iPhone|iPad|iPod/.test(ua) || /iPhone|iPad|iPod/.test(plat);
    // iPadOS 13+ masquerades as "Macintosh"; a real Mac has no touch screen,
    // so maxTouchPoints > 1 on a "Mac" means it is actually an iPad.
    var isMac = /Mac/.test(plat) || /Mac OS X/.test(ua);
    var isiPadOS = isMac && maxTouch > 1;
    var isAndroid = /Android/.test(ua);

    if (isIOS || isiPadOS || isMac) {
      cls = 'platform-apple';
    } else if (isAndroid) {
      cls = 'platform-android';
    } else {
      // Uncertain → safe, readable, non-glass fallback.
      cls = 'platform-other';
    }
  }

  docEl.classList.add(cls);
  docEl.setAttribute('data-platform', cls.slice('platform-'.length));
})();
