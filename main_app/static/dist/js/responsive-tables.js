/* =====================================================================
   Responsive data tables — label injection.

   On phones, wide data tables are reflowed into stacked cards by CSS
   (mobile-adaptive.css). For each stacked row to be readable, every cell
   needs to show which column it belongs to. Rather than editing dozens of
   templates, this copies each column's <th> text onto the matching <td>
   as a data-label attribute, which the CSS renders via ::before.

   Purely additive: no markup is moved or removed, and it is a no-op on
   tablet/desktop where the real <table> is shown.
   ===================================================================== */
(function () {
  'use strict';

  function labelTable(table) {
    // One header row only — skip grouped/multi-row headers we can't map 1:1.
    var thead = table.tHead;
    if (!thead || thead.rows.length !== 1) return;

    var headers = Array.prototype.map.call(
      thead.rows[0].cells,
      function (th) {
        return (th.getAttribute('data-label') || th.textContent || '')
          .replace(/\s+/g, ' ')
          .trim();
      }
    );
    if (!headers.length) return;

    Array.prototype.forEach.call(table.tBodies, function (tbody) {
      Array.prototype.forEach.call(tbody.rows, function (row) {
        // Skip injected full-width rows (e.g. "no results", colspan banners).
        if (row.cells.length !== headers.length) return;
        Array.prototype.forEach.call(row.cells, function (cell, i) {
          if (cell.hasAttribute('data-label')) return;
          var label = headers[i];
          if (!label) return;
          // "Actions" cells are still labeled, but the CSS lets buttons wrap
          // as a touch-friendly row on phones.
          cell.setAttribute('data-label', label);
        });
      });
    });
  }

  function run() {
    var tables = document.querySelectorAll(
      'table.dt, table.data-table, table.table, table.stu-table, table.pg-table, table.sea-tbl'
    );
    Array.prototype.forEach.call(tables, labelTable);
  }

  function watch() {
    if (!('MutationObserver' in window)) return;
    var root = document.querySelector('.content-area') || document.body;
    var pending = false;
    var observer = new MutationObserver(function () {
      if (pending) return;
      pending = true;
      window.requestAnimationFrame(function () {
        pending = false;
        run();
      });
    });
    observer.observe(root, { childList: true, subtree: true });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () {
      run();
      watch();
    });
  } else {
    run();
    watch();
  }
})();
