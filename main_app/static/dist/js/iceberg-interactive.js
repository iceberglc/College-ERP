/* =====================================================
   ICEBERG STUDY CENTER — Interactivity layer
   Progressive enhancement, vanilla JS, no dependencies.
   - Live search + click-to-sort on data tables
   - Count-up animation on dashboard stats
   - Reveal-on-scroll for cards
   - Ripple on buttons
   All features degrade gracefully and respect
   prefers-reduced-motion.
   ===================================================== */
(function () {
  'use strict';

  var REDUCED = window.matchMedia &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var HAS_IO = 'IntersectionObserver' in window;

  function ready(fn) {
    if (document.readyState !== 'loading') fn();
    else document.addEventListener('DOMContentLoaded', fn);
  }

  /* ── 1. Button ripple ──────────────────────────────── */
  function initRipple() {
    if (REDUCED) return;
    document.addEventListener('click', function (e) {
      var btn = e.target.closest('.btn, .quick-action-btn');
      if (!btn) return;
      var rect = btn.getBoundingClientRect();
      var size = Math.max(rect.width, rect.height);
      var ink = document.createElement('span');
      ink.className = 'ripple-ink';
      ink.style.width = ink.style.height = size + 'px';
      ink.style.left = (e.clientX - rect.left - size / 2) + 'px';
      ink.style.top = (e.clientY - rect.top - size / 2) + 'px';
      btn.appendChild(ink);
      setTimeout(function () { ink.remove(); }, 600);
    });
  }

  /* ── 2. Count-up on stats ──────────────────────────── */
  function countUp(el) {
    var raw = (el.textContent || '').trim();
    var target = parseInt(raw.replace(/[, ]/g, ''), 10);
    if (isNaN(target) || !/^\d[\d,\s]*$/.test(raw)) return; // only plain integers
    if (REDUCED || target === 0) { el.textContent = target; return; }
    var dur = 1100, start = null;
    function step(ts) {
      if (start === null) start = ts;
      var p = Math.min((ts - start) / dur, 1);
      var eased = 1 - Math.pow(1 - p, 3); // easeOutCubic
      el.textContent = Math.round(eased * target).toLocaleString();
      if (p < 1) requestAnimationFrame(step);
      else el.textContent = target.toLocaleString();
    }
    requestAnimationFrame(step);
  }

  function initCountUp() {
    var nodes = document.querySelectorAll('.stat-number, .small-box .inner h3');
    if (!nodes.length) return;
    if (!HAS_IO) { nodes.forEach(countUp); return; }
    var io = new IntersectionObserver(function (entries, obs) {
      entries.forEach(function (en) {
        if (en.isIntersecting) { countUp(en.target); obs.unobserve(en.target); }
      });
    }, { threshold: 0.4 });
    nodes.forEach(function (n) { io.observe(n); });
  }

  /* ── 3. Reveal on scroll ───────────────────────────── */
  function initReveal() {
    if (REDUCED || !HAS_IO) return;
    var targets = document.querySelectorAll(
      '.erpnext-card, .stat-card, .small-box, .content-area > .card, .content-area .row > [class*="col"] > .card'
    );
    if (!targets.length) return;
    targets.forEach(function (el, i) {
      el.classList.add('ice-reveal');
      el.style.transitionDelay = Math.min(i * 60, 360) + 'ms';
    });
    var io = new IntersectionObserver(function (entries, obs) {
      entries.forEach(function (en) {
        if (en.isIntersecting) { en.target.classList.add('ice-in'); obs.unobserve(en.target); }
      });
    }, { threshold: 0.08 });
    targets.forEach(function (t) { io.observe(t); });
    // Safety: reveal anything still hidden after 1.4s (e.g. off-screen tall pages)
    setTimeout(function () {
      targets.forEach(function (t) { t.classList.add('ice-in'); });
    }, 1400);
  }

  /* ── 4. Data-table enhancement (search + sort) ─────── */
  var SKIP_HEADER = /^(actions?|avatar|image|photo|edit|delete|select|#)?$/i;

  function isDataTable(table) {
    if (table.closest('.login-card')) return false;
    var thead = table.querySelector('thead');
    var tbody = table.querySelector('tbody');
    if (!thead || !tbody) return false;
    if (table.tHead.rows.length !== 1) return false;        // skip complex/grouped headers
    if (tbody.querySelectorAll('tr').length < 2) return false;
    // skip interactive forms (attendance / result entry tables)
    if (table.querySelector('input, select, textarea')) return false;
    return true;
  }

  function cellValue(row, i) {
    var c = row.cells[i];
    return c ? (c.textContent || '').trim() : '';
  }

  function enhanceTable(table) {
    if (table.dataset.iceEnhanced) return;
    table.dataset.iceEnhanced = '1';

    var tbody = table.tBodies[0];
    var headers = Array.prototype.slice.call(table.tHead.rows[0].cells);
    var colCount = headers.length;

    /* toolbar */
    var toolbar = document.createElement('div');
    toolbar.className = 'ice-table-toolbar';
    toolbar.innerHTML =
      '<div class="ice-search-wrap"><i class="fas fa-search"></i>' +
      '<input type="text" class="ice-search" placeholder="Search…" aria-label="Search table"></div>' +
      '<span class="ice-row-count"></span>';
    table.parentNode.insertBefore(toolbar, table);

    var search = toolbar.querySelector('.ice-search');
    var counter = toolbar.querySelector('.ice-row-count');

    /* empty-state row */
    var emptyRow = document.createElement('tr');
    emptyRow.className = 'ice-no-results';
    emptyRow.style.display = 'none';
    emptyRow.innerHTML = '<td colspan="' + colCount + '">No matching records found</td>';
    tbody.appendChild(emptyRow);

    function dataRows() {
      return Array.prototype.filter.call(tbody.rows, function (r) {
        return !r.classList.contains('ice-no-results');
      });
    }

    function updateCount() {
      var rows = dataRows();
      var visible = rows.filter(function (r) { return r.style.display !== 'none'; }).length;
      counter.textContent = visible + ' of ' + rows.length;
    }

    /* search */
    search.addEventListener('input', function () {
      var q = search.value.toLowerCase().trim();
      var any = false;
      dataRows().forEach(function (r) {
        var match = !q || r.textContent.toLowerCase().indexOf(q) !== -1;
        r.style.display = match ? '' : 'none';
        if (match) any = true;
      });
      emptyRow.style.display = any ? 'none' : '';
      updateCount();
    });

    /* sort */
    headers.forEach(function (th, idx) {
      if (SKIP_HEADER.test((th.textContent || '').trim())) return;
      th.classList.add('ice-sortable');
      th.addEventListener('click', function () {
        var asc = !th.classList.contains('ice-asc');
        headers.forEach(function (h) { h.classList.remove('ice-asc', 'ice-desc'); });
        th.classList.add(asc ? 'ice-asc' : 'ice-desc');

        var rows = dataRows();
        rows.sort(function (a, b) {
          var x = cellValue(a, idx), y = cellValue(b, idx);
          var nx = parseFloat(x.replace(/[^0-9.\-]/g, '')),
              ny = parseFloat(y.replace(/[^0-9.\-]/g, ''));
          var bothNum = !isNaN(nx) && !isNaN(ny) && x !== '' && y !== '';
          var cmp = bothNum ? nx - ny : x.localeCompare(y, undefined, { numeric: true });
          return asc ? cmp : -cmp;
        });
        rows.forEach(function (r) { tbody.appendChild(r); });
        tbody.appendChild(emptyRow);
      });
    });

    updateCount();
  }

  function initTables() {
    document.querySelectorAll('table').forEach(function (t) {
      try { if (isDataTable(t)) enhanceTable(t); } catch (e) { /* never break the page */ }
    });
  }

  ready(function () {
    initRipple();
    initCountUp();
    initReveal();
    initTables();
  });
})();
