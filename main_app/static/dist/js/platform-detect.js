/* =====================================================================
   Platform detection + adaptive-look control.

   Sets exactly one class on <html>:
     .platform-apple    iPhone / iPad / Mac (→ "Liquid Glass" theme)
     .platform-android  Android devices       (→ solid Material theme)
     .platform-other    everything / unknown  (→ solid Material theme)

   Loaded synchronously in <head> BEFORE the stylesheets so the class is
   present when CSS first matches (no flash of the wrong theme).

   Exposes window.IcePlatform so a visible toggle (sidebar) can change the
   look live, and supports a URL override for testing:
     ?platform=apple | android | other   → force + persist a look
     ?platform=auto                       → clear the override
   ===================================================================== */
(function () {
  'use strict';

  var KEY = 'ui_platform_override';
  var docEl = document.documentElement;

  /* ── Auto detection from the user agent ────────────────────────────── */
  function detect() {
    var ua = navigator.userAgent || '';
    var plat = navigator.platform || '';
    var maxTouch = navigator.maxTouchPoints || 0;

    var isIOS = /iPhone|iPad|iPod/.test(ua) || /iPhone|iPad|iPod/.test(plat);
    // iPadOS 13+ masquerades as "Macintosh"; a real Mac has no touch screen,
    // so maxTouchPoints > 1 on a "Mac" means it is actually an iPad.
    var isMac = /Mac/.test(plat) || /Mac OS X/.test(ua);
    var isiPadOS = isMac && maxTouch > 1;
    var isAndroid = /Android/.test(ua);

    if (isIOS || isiPadOS || isMac) return 'apple';
    if (isAndroid) return 'android';
    return 'other'; // uncertain → safe, readable, non-glass fallback
  }

  function currentOverride() {
    try {
      var v = localStorage.getItem(KEY);
      return (v === 'apple' || v === 'android' || v === 'other') ? v : null;
    } catch (e) { return null; }
  }

  function setClass(platform) {
    docEl.classList.remove('platform-apple', 'platform-android', 'platform-other');
    docEl.classList.add('platform-' + platform);
    docEl.setAttribute('data-platform', platform);
  }

  /* Apply a preference live. value: 'apple' | 'android' | 'other' | 'auto'.
     Persists (or clears) the override and swaps the <html> class. */
  function apply(value) {
    var resolved;
    if (value === 'auto') {
      try { localStorage.removeItem(KEY); } catch (e) {}
      resolved = detect();
    } else if (value === 'apple' || value === 'android' || value === 'other') {
      try { localStorage.setItem(KEY, value); } catch (e) {}
      resolved = value;
    } else {
      resolved = currentOverride() || detect();
    }
    setClass(resolved);
    docEl.setAttribute('data-platform-pref', currentOverride() || 'auto');
    return resolved;
  }

  /* ── URL override (testing) — persists or clears, then falls through ─ */
  try {
    var q = new URLSearchParams(window.location.search).get('platform');
    if (q === 'auto') { localStorage.removeItem(KEY); }
    else if (q === 'apple' || q === 'android' || q === 'other') { localStorage.setItem(KEY, q); }
  } catch (e) { /* URL/localStorage unavailable */ }

  /* ── Apply before paint ────────────────────────────────────────────── */
  setClass(currentOverride() || detect());
  docEl.setAttribute('data-platform-pref', currentOverride() || 'auto');

  window.IcePlatform = {
    detect: detect,
    apply: apply,
    current: function () { return docEl.getAttribute('data-platform'); },
    pref: function () { return currentOverride() || 'auto'; }
  };
})();
