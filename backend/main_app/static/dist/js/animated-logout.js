/* ============================================================================
   ICEBERG · animated-logout.js
   Plays the logout animation, then submits the real POST + CSRF logout form.
   Progressive enhancement:
     • No JS / JS error  → form submits normally (real logout still works).
     • Reduced motion    → skip choreography, submit immediately.
     • Double-click      → ignored while an animation is already running.
     • Safety timeout    → logout always proceeds even if a frame is dropped.
   ========================================================================== */
(function () {
  'use strict';

  var prefersReduced = window.matchMedia &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // Choreography states for the full SVG variant (adapted from the component).
  var FULL_STATES = {
    walking1: { '--figure-duration': '300', '--transform-figure': 'translateX(11px)', '--walking-duration': '300',
      '--transform-arm1': 'translateX(-4px) translateY(-2px) rotate(120deg)', '--transform-wrist1': 'rotate(-5deg)',
      '--transform-arm2': 'translateX(4px) rotate(-110deg)', '--transform-wrist2': 'rotate(-5deg)',
      '--transform-leg1': 'translateX(-3px) rotate(80deg)', '--transform-calf1': 'rotate(-30deg)',
      '--transform-leg2': 'translateX(4px) rotate(-60deg)', '--transform-calf2': 'rotate(20deg)' },
    walking2: { '--figure-duration': '400', '--transform-figure': 'translateX(17px)', '--walking-duration': '300',
      '--transform-arm1': 'rotate(60deg)', '--transform-arm2': 'rotate(-45deg)',
      '--transform-leg1': 'rotate(-5deg)', '--transform-leg2': 'rotate(10deg)' },
    falling1: { '--figure-duration': '1600', '--walking-duration': '400' }
  };

  function applyState(btn, state) {
    var map = FULL_STATES[state];
    if (!map) return;
    for (var k in map) if (map.hasOwnProperty(k)) btn.style.setProperty(k, map[k]);
  }

  function submitForm(form) {
    if (form.dataset.alSubmitted) return;
    form.dataset.alSubmitted = '1';
    if (window.iceLoader) window.iceLoader.start();
    // Use requestSubmit when available so native validation/CSRF stays intact.
    if (typeof form.requestSubmit === 'function') form.requestSubmit();
    else form.submit();
  }

  document.addEventListener('submit', function (e) {
    var form = e.target;
    if (!form || form.nodeName !== 'FORM') return;
    if (!form.hasAttribute('data-animated-logout')) return;
    if (form.dataset.alSubmitted) return;          // let the real submit through
    if (form.dataset.alRunning) { e.preventDefault(); return; } // ignore double

    if (prefersReduced) return;                    // submit immediately, no anim

    e.preventDefault();
    form.dataset.alRunning = '1';

    var btn = form.querySelector('button[type="submit"], .animated-logout');
    if (!btn) { submitForm(form); return; }

    btn.classList.add('is-leaving');
    var isFull = btn.classList.contains('animated-logout--full');
    var SAFETY = isFull ? 1100 : 600;              // hard cap → never hangs

    if (isFull) {
      applyState(btn, 'walking1');
      setTimeout(function () {
        btn.classList.add('door-slammed');
        applyState(btn, 'walking2');
        setTimeout(function () {
          btn.classList.add('falling');
          applyState(btn, 'falling1');
        }, 300);
      }, 300);
    }

    setTimeout(function () { submitForm(form); }, SAFETY);
  }, true);
})();
