/* ============================================================================
   ICEBERG reliability helpers.
   Progressive enhancement only: real links and forms still work without JS.
   ========================================================================== */
(function () {
  "use strict";

  function csrfToken() {
    var input = document.querySelector("input[name='csrfmiddlewaretoken']");
    if (input && input.value) return input.value;
    var match = document.cookie.match(/(?:^|; )csrftoken=([^;]+)/);
    return match ? decodeURIComponent(match[1]) : "";
  }

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
    window.setTimeout(function () {
      item.style.opacity = "0";
      item.style.transform = "translateY(8px)";
      window.setTimeout(function () { item.remove(); }, 180);
    }, 2600);
  }

  window.iceShowToast = window.iceShowToast || toast;

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

  document.addEventListener("click", function (event) {
    var link = event.target.closest("a[data-confirm-post]");
    if (!link || event.defaultPrevented) return;
    if (event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;

    var message = link.getAttribute("data-confirm-post") || "Continue with this action?";
    if (!window.confirm(message)) {
      event.preventDefault();
      event.stopPropagation();
      if (window.iceLoader) window.iceLoader.stop();
      return;
    }

    event.preventDefault();
    event.stopPropagation();
    link.classList.add("is-loading");
    link.setAttribute("aria-busy", "true");
    if (window.iceLoader) window.iceLoader.start();
    postLink(link);
  }, true);

  document.addEventListener("submit", function (event) {
    var form = event.target;
    if (!form || form.nodeName !== "FORM") return;
    if (form.hasAttribute("data-animated-logout")) return;
    form.classList.add("is-submitting");
  }, true);
})();
