(function () {
  "use strict";

  function iconFor(type) {
    if (type === "success") return "fa-check-circle";
    if (type === "warning") return "fa-exclamation-triangle";
    if (type === "error" || type === "danger") return "fa-exclamation-circle";
    return "fa-info-circle";
  }

  window.iceShowInlineAlert = function (container, message, type) {
    var target = typeof container === "string" ? document.querySelector(container) : container;
    if (!target) return null;

    var alertType = type || "info";
    var el = document.createElement("div");
    el.className = "ice-inline-alert ice-inline-alert--" + alertType;
    el.setAttribute("role", alertType === "error" || alertType === "danger" ? "alert" : "status");
    el.innerHTML =
      '<i class="fas ' + iconFor(alertType) + '" aria-hidden="true"></i>' +
      "<span></span>";
    el.querySelector("span").textContent = message || "Couldn\u2019t load data. Please try again.";

    target.innerHTML = "";
    target.appendChild(el);
    return el;
  };

  function injectTableLabels(table) {
    var thead = table.tHead;
    if (!thead || thead.rows.length !== 1) return;

    var headers = Array.prototype.map.call(thead.rows[0].cells, function (th) {
      return (th.getAttribute("data-label") || th.textContent || "").replace(/\s+/g, " ").trim();
    });
    if (!headers.length) return;

    Array.prototype.forEach.call(table.tBodies, function (tbody) {
      Array.prototype.forEach.call(tbody.rows, function (row) {
        if (row.cells.length !== headers.length) return;
        Array.prototype.forEach.call(row.cells, function (cell, index) {
          if (cell.hasAttribute("data-label")) return;
          if (!headers[index]) return;
          cell.setAttribute("data-label", headers[index]);
        });
      });
    });
  }

  function setupTables(root) {
    var scope = root || document;
    var tables = scope.querySelectorAll("table.dt, table.data-table, table.table, table.stu-table, table.pg-table, table.sea-tbl, table.ice-manage-table, table.lead-table");
    Array.prototype.forEach.call(tables, injectTableLabels);
  }

  function setupSearch(root) {
    var scope = root || document;
    var controls = scope.querySelectorAll("[data-ice-search]");

    Array.prototype.forEach.call(controls, function (control) {
      if (control.dataset.iceSearchReady === "1") return;
      control.dataset.iceSearchReady = "1";

      var targetSelector = control.getAttribute("data-ice-search");
      var searchScope = targetSelector ? document.querySelector(targetSelector) : control.closest(".ice-mobile-page, .ice-page-shell, [data-ice-search-scope]");
      if (!searchScope) searchScope = document;

      var items = Array.prototype.slice.call(searchScope.querySelectorAll("[data-ice-search-item]"));
      var primaryItems = Array.prototype.slice.call(searchScope.querySelectorAll("[data-ice-search-primary]"));
      var countItems = primaryItems.length ? primaryItems : items;
      var emptyState = searchScope.querySelector("[data-ice-empty-state]");
      var count = searchScope.querySelector("[data-ice-visible-count]");

      function textFor(item) {
        return (item.getAttribute("data-ice-search-text") || item.textContent || "").toLowerCase();
      }

      function filter() {
        var query = (control.value || "").trim().toLowerCase();
        items.forEach(function (item) {
          var matched = !query || textFor(item).indexOf(query) !== -1;
          item.hidden = !matched;
        });

        var visible = countItems.filter(function (item) {
          return !item.hidden;
        }).length;

        if (count) count.textContent = String(visible);
        if (emptyState) emptyState.hidden = !query || visible > 0;
      }

      control.addEventListener("input", filter);
      filter();
    });
  }

  function setupAjaxLoading(root) {
    var scope = root || document;
    Array.prototype.forEach.call(scope.querySelectorAll("[data-ice-loading]"), function (el) {
      if (!el.innerHTML.trim()) {
        el.innerHTML = '<div class="ice-loading-state"><i class="fas fa-spinner fa-spin" aria-hidden="true"></i><strong>Loading</strong><span>Please wait...</span></div>';
      }
    });
  }

  function boot() {
    setupTables();
    setupSearch();
    setupAjaxLoading();

    if ("MutationObserver" in window) {
      var pending = false;
      var observer = new MutationObserver(function () {
        if (pending) return;
        pending = true;
        window.requestAnimationFrame(function () {
          pending = false;
          setupTables();
          setupSearch();
        });
      });
      observer.observe(document.querySelector(".content-area") || document.body, {
        childList: true,
        subtree: true
      });
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }
})();
