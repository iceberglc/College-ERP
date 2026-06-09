/* ============================================================================
   ICEBERG reliability helpers — safe-actions.js
   Progressive enhancement only: real links and forms still work without JS.
   ========================================================================== */
(function () {
  "use strict";

  /* ── Inject modal styles once ─────────────────────────────────────────── */
  (function injectStyles() {
    if (document.getElementById("ice-confirm-styles")) return;
    var s = document.createElement("style");
    s.id = "ice-confirm-styles";
    s.textContent = [
      ".ice-confirm-overlay{position:fixed;inset:0;z-index:200000;display:flex;",
      "align-items:center;justify-content:center;padding:20px;",
      "background:rgba(7,26,82,.55);backdrop-filter:blur(6px);",
      "-webkit-backdrop-filter:blur(6px);opacity:0;",
      "transition:opacity .18s ease;}",

      ".ice-confirm-overlay--open{opacity:1;}",

      ".ice-confirm-box{display:flex;flex-direction:column;align-items:center;",
      "gap:16px;width:100%;max-width:380px;padding:28px 24px;border-radius:24px;",
      "background:#fff;color:#0f172a;",
      "box-shadow:0 32px 80px rgba(7,26,82,.22),0 2px 8px rgba(0,0,0,.08);",
      "transform:scale(.92) translateY(12px);opacity:0;",
      "transition:transform .22s cubic-bezier(.34,1.56,.64,1),opacity .18s ease;",
      "text-align:center;}",

      ".ice-confirm-overlay--open .ice-confirm-box{transform:scale(1) translateY(0);opacity:1;}",

      "[data-theme=dark] .ice-confirm-box,.dark-mode .ice-confirm-box{",
      "background:#0f172a;color:#e5eef8;",
      "box-shadow:0 32px 80px rgba(0,0,0,.5);}",

      ".ice-confirm-ico{width:56px;height:56px;border-radius:50%;flex:0 0 56px;",
      "display:flex;align-items:center;justify-content:center;",
      "background:rgba(220,38,38,.12);color:#dc2626;font-size:22px;}",

      ".ice-confirm-ttl{font-size:17px;font-weight:900;margin:0;line-height:1.25;color:inherit;}",

      ".ice-confirm-msg{font-size:13.5px;line-height:1.55;color:#64748b;margin:0;max-width:300px;}",
      "[data-theme=dark] .ice-confirm-msg,.dark-mode .ice-confirm-msg{color:#9aa9bc;}",

      ".ice-confirm-btns{display:grid;grid-template-columns:1fr 1fr;gap:10px;width:100%;}",

      ".ice-confirm-cancel{min-height:46px;border-radius:14px;",
      "border:1.5px solid rgba(148,163,184,.35);background:transparent;",
      "color:inherit;font-size:14px;font-weight:800;cursor:pointer;",
      "transition:background .13s;}",
      ".ice-confirm-cancel:hover{background:rgba(148,163,184,.12);}",

      ".ice-confirm-ok{min-height:46px;border-radius:14px;border:0;",
      "background:linear-gradient(135deg,#b91c1c,#dc2626);",
      "color:#fff;font-size:14px;font-weight:900;cursor:pointer;",
      "box-shadow:0 8px 20px rgba(220,38,38,.28);",
      "transition:filter .13s;}",
      ".ice-confirm-ok:hover{filter:brightness(1.09);}",

      "@media(max-width:400px){.ice-confirm-btns{grid-template-columns:1fr;}}",

      "@media(prefers-reduced-motion:reduce){",
      ".ice-confirm-overlay,.ice-confirm-box{transition:none !important;}}",
    ].join("");
    (document.head || document.documentElement).appendChild(s);
  })();

  /* ── Confirmation modal ───────────────────────────────────────────────── */
  function showConfirmModal(rawMessage, onConfirm) {
    var existing = document.getElementById("ice-confirm-modal");
    if (existing) existing.remove();

    // Split on first "? " to get title / body
    var qIdx = rawMessage.indexOf("? ");
    var title = qIdx >= 0 ? rawMessage.slice(0, qIdx + 1) : "Are you sure?";
    var body  = qIdx >= 0 ? rawMessage.slice(qIdx + 2) : rawMessage;

    var overlay = document.createElement("div");
    overlay.id = "ice-confirm-modal";
    overlay.className = "ice-confirm-overlay";
    overlay.setAttribute("role", "dialog");
    overlay.setAttribute("aria-modal", "true");
    overlay.setAttribute("aria-labelledby", "ice-confirm-ttl-el");

    overlay.innerHTML =
      '<div class="ice-confirm-box">' +
        '<div class="ice-confirm-ico"><i class="fas fa-trash" aria-hidden="true"></i></div>' +
        '<p class="ice-confirm-ttl" id="ice-confirm-ttl-el">' + _esc(title) + "</p>" +
        (body
          ? '<p class="ice-confirm-msg">' + _esc(body) + "</p>"
          : "") +
        '<div class="ice-confirm-btns">' +
          '<button type="button" class="ice-confirm-cancel">Cancel</button>' +
          '<button type="button" class="ice-confirm-ok">Delete</button>' +
        "</div>" +
      "</div>";

    document.body.appendChild(overlay);

    var closed = false;
    function close(e) {
      if (closed) return;
      closed = true;
      if (e && typeof e.stopPropagation === "function") {
        e.stopPropagation();
        e.preventDefault();
      }
      // Cancelled (or about to confirm — confirm restarts it): never leave
      // a stuck "Preparing your page…" overlay behind.
      if (window.iceLoader) window.iceLoader.stop();
      overlay.classList.remove("ice-confirm-overlay--open");
      overlay.addEventListener("transitionend", function() { overlay.remove(); }, { once: true });
      // Safety fallback — remove after 400 ms even if transitionend never fires
      setTimeout(function() { if (overlay.parentNode) overlay.remove(); }, 400);
      document.removeEventListener("keydown", onKey, true);
    }

    function onKey(e) {
      if (e.key === "Escape") { close(e); return; }
      if (e.key === "Tab") {
        e.preventDefault();
        var focusable = overlay.querySelectorAll(".ice-confirm-cancel,.ice-confirm-ok");
        var cur = document.activeElement;
        var idx = Array.prototype.indexOf.call(focusable, cur);
        var next = focusable[(idx + 1) % focusable.length];
        if (next) next.focus();
      }
    }

    overlay.addEventListener("click", function(e) { if (e.target === overlay) close(e); });
    overlay.querySelector(".ice-confirm-cancel").addEventListener("click", close);
    overlay.querySelector(".ice-confirm-ok").addEventListener("click", function(e) {
      close(e);
      onConfirm();
    });
    document.addEventListener("keydown", onKey, true);

    // Double-rAF: ensure the element is in the DOM before adding the open class
    requestAnimationFrame(function() {
      requestAnimationFrame(function() {
        overlay.classList.add("ice-confirm-overlay--open");
        var cancel = overlay.querySelector(".ice-confirm-cancel");
        if (cancel) cancel.focus();
      });
    });
  }

  function _esc(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  /* ── CSRF token ───────────────────────────────────────────────────────── */
  function csrfToken() {
    var input = document.querySelector("input[name='csrfmiddlewaretoken']");
    if (input && input.value) return input.value;
    var match = document.cookie.match(/(?:^|; )csrftoken=([^;]+)/);
    return match ? decodeURIComponent(match[1]) : "";
  }

  /* ── Toast helper ─────────────────────────────────────────────────────── */
  function toast(message, type) {
    var stack = document.querySelector(".ice-toast-stack");
    if (!stack) {
      stack = document.createElement("div");
      stack.className = "ice-toast-stack";
      stack.setAttribute("aria-live", "polite");
      stack.setAttribute("aria-atomic", "true");
      document.body.appendChild(stack);
    }
    var item = document.createElement("div");
    item.className = "ice-toast ice-toast--" + (type || "info");
    item.setAttribute("role", type === "danger" || type === "error" ? "alert" : "status");
    item.innerHTML = '<i class="fas fa-info-circle" aria-hidden="true"></i><span></span>';
    item.querySelector("span").textContent = message || "Done";
    stack.appendChild(item);
    window.setTimeout(function() {
      item.style.opacity = "0";
      item.style.transform = "translateY(8px)";
      window.setTimeout(function() { item.remove(); }, 180);
    }, 2600);
  }

  window.iceShowToast = window.iceShowToast || toast;

  /* ── POST-form helper ─────────────────────────────────────────────────── */
  function postLink(link) {
    var href = link.getAttribute("href");
    if (!href) return;
    var url;
    try { url = new URL(href, window.location.href); } catch (_) { return; }
    if (url.origin !== window.location.origin) return;
    var form = document.createElement("form");
    form.method = "post";
    form.action = url.pathname + url.search + url.hash;
    form.hidden = true;
    var csrf = csrfToken();
    if (csrf) {
      var token = document.createElement("input");
      token.type = "hidden";
      token.name = "csrfmiddlewaretoken";
      token.value = csrf;
      form.appendChild(token);
    }
    document.body.appendChild(form);
    form.submit();
  }

  /* ── data-confirm-post click handler ─────────────────────────────────── */
  document.addEventListener("click", function(event) {
    var link = event.target.closest("a[data-confirm-post]");
    if (!link || event.defaultPrevented) return;
    if (event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;

    event.preventDefault();
    event.stopPropagation();

    // Belt-and-braces: if any global click handler already kicked off the
    // page loader, kill it — we're showing a modal, not navigating.
    if (window.iceLoader) window.iceLoader.stop();

    var message = link.getAttribute("data-confirm-post") || "Are you sure? This cannot be undone.";
    showConfirmModal(message, function() {
      link.classList.add("is-loading");
      link.setAttribute("aria-busy", "true");
      if (window.iceLoader) window.iceLoader.start();
      postLink(link);
    });
  }, true);

  /* ── Form submitting state ────────────────────────────────────────────── */
  document.addEventListener("submit", function(event) {
    var form = event.target;
    if (!form || form.nodeName !== "FORM") return;
    if (form.hasAttribute("data-animated-logout")) return;
    form.classList.add("is-submitting");
  }, true);
})();
