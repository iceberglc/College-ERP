/* ════════════════════════════════════════════════════════════════════
   Iceberg Trend Chart — premium line graph helper
   Usage:
     IcebergTrend.line({
       canvas: 'myChart',
       labels: ['Sep 5', 'Sep 12', ...],
       series: [
         { name: 'Score', data: [85, 90, ...], color: '#06B6D4' },
       ],
       suffix: '%',
       yMax: 100,
     });
══════════════════════════════════════════════════════════════════════ */
(function (global) {
  'use strict';

  var PALETTE = {
    navy: '#071A52',
    ocean: '#0B4F8A',
    cyan: '#00CFE8',
    softCyan: '#67E8F9',
    ice: '#EAF8FF',
    green: '#22C55E',
    amber: '#F59E0B',
    red: '#EF4444'
  };
  var activeTrendConfigs = global.icebergTrendConfigs || {};
  global.icebergTrendConfigs = activeTrendConfigs;

  function isDark() {
    return document.documentElement.getAttribute('data-theme') === 'dark' ||
      document.documentElement.classList.contains('dark-mode') ||
      document.body.classList.contains('dark-mode');
  }

  function isMobile() {
    return global.matchMedia && global.matchMedia('(max-width: 767.98px)').matches;
  }

  function isTablet() {
    return global.matchMedia && global.matchMedia('(min-width: 768px) and (max-width: 1023.98px)').matches;
  }

  function pointLimit(cfg) {
    if (cfg.pointLimit) return cfg.pointLimit;
    if (isMobile()) return cfg.mobileLimit || 6;
    if (isTablet()) return cfg.tabletLimit || 9;
    return cfg.desktopLimit || 14;
  }

  function compact(cfg) {
    var labels = cfg.labels || [];
    var series = cfg.series || [];
    var limit = pointLimit(cfg);
    if (!limit || labels.length <= limit) {
      return { labels: labels, series: series };
    }
    return {
      labels: labels.slice(-limit),
      series: series.map(function (s) {
        var copy = {};
        Object.keys(s).forEach(function (key) { copy[key] = s[key]; });
        copy.data = (s.data || []).slice(-limit);
        return copy;
      }),
    };
  }

  function showState(canvas, message) {
    var parent = canvas && canvas.parentElement;
    if (!parent) return;
    canvas.hidden = true;
    if (!parent.querySelector('.ice-chart-state')) {
      var state = document.createElement('div');
      state.className = 'ice-chart-state';
      state.textContent = message || 'Chart data is unavailable right now.';
      parent.appendChild(state);
    }
  }

  function resetState(canvas) {
    var parent = canvas && canvas.parentElement;
    if (!parent) return;
    canvas.hidden = false;
    parent.querySelectorAll('.ice-chart-state').forEach(function (node) { node.remove(); });
  }

  function cloneConfig(cfg, canvas) {
    var clone = {};
    Object.keys(cfg).forEach(function (key) {
      if (key !== '_recreating') clone[key] = cfg[key];
    });
    clone.canvas = canvas.id;
    return clone;
  }

  function rememberConfig(cfg, canvas) {
    if (cfg._recreating || cfg.recreate === false || !canvas || !canvas.id) return;
    activeTrendConfigs[canvas.id] = cloneConfig(cfg, canvas);
    if (!global.icebergTrendRecreationRegistered && global.registerChartRecreation) {
      global.icebergTrendRecreationRegistered = true;
      global.registerChartRecreation(function () {
        Object.keys(activeTrendConfigs).forEach(function (id) {
          var stored = activeTrendConfigs[id];
          if (!stored || !document.getElementById(id)) return;
          var next = cloneConfig(stored, { id: id });
          next._recreating = true;
          line(next);
        });
      });
    }
  }

  function makeGradient(ctx, color, height) {
    var rgb = hexToRgb(color);
    var g = ctx.createLinearGradient(0, 0, 0, height);
    g.addColorStop(0,   'rgba(' + rgb + ', 0.26)');
    g.addColorStop(0.55, 'rgba(' + rgb + ', 0.08)');
    g.addColorStop(1,   'rgba(' + rgb + ', 0.0)');
    return g;
  }

  function hexToRgb(hex) {
    var h = hex.replace('#', '');
    if (h.length === 3) h = h.split('').map(function (c) { return c + c; }).join('');
    var n = parseInt(h, 16);
    return ((n >> 16) & 255) + ', ' + ((n >> 8) & 255) + ', ' + (n & 255);
  }

  function line(cfg) {
    var canvas = typeof cfg.canvas === 'string'
      ? document.getElementById(cfg.canvas)
      : cfg.canvas;
    if (!canvas) return null;
    rememberConfig(cfg, canvas);
    resetState(canvas);
    if (typeof Chart === 'undefined') {
      showState(canvas, 'Charts are unavailable right now. The rest of the page is still usable.');
      return null;
    }

    var ctx = canvas.getContext('2d');
    var height = canvas.offsetHeight || canvas.height || 300;
    var dark = isDark();
    var mobile = isMobile();
    var reducedMotion = global.matchMedia && global.matchMedia('(prefers-reduced-motion: reduce)').matches;
    var data = compact(cfg);

    if (!data.labels.length || !data.series.length) {
      showState(canvas, cfg.emptyMessage || 'Chart data will appear here once records exist.');
      return null;
    }

    var datasets = data.series.map(function (s, index) {
      var c = s.color || [PALETTE.cyan, PALETTE.ocean, PALETTE.green, PALETTE.amber, PALETTE.red][index % 5];
      var points = s.data || [];
      return {
        label: s.name || '',
        data: points,
        borderColor: c,
        backgroundColor: cfg.fill === false ? 'transparent' : makeGradient(ctx, c, height),
        borderWidth: mobile ? 2 : 2.5,
        fill: cfg.fill !== false,
        tension: 0.42,
        cubicInterpolationMode: 'monotone',
        pointRadius: points.map(function (v) { return v !== null && !mobile ? 3.25 : 0; }),
        pointBackgroundColor: c,
        pointHoverRadius: mobile ? 4 : 6,
        pointHoverBackgroundColor: '#fff',
        pointHoverBorderColor: c,
        pointHoverBorderWidth: 3,
        spanGaps: true,
      };
    });

    var suffix = cfg.suffix || '';
    var prefix = cfg.prefix || '';
    var yMax = cfg.yMax || (cfg.suffix === '%' ? 100 : undefined);
    var yMin = cfg.yMin || 0;

    var chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: data.labels,
        datasets: datasets,
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: {
          duration: reducedMotion ? 0 : 650,
          easing: 'easeOutQuart',
        },
        layout: {
          padding: mobile
            ? { top: 8, bottom: 0, left: 2, right: 2 }
            : { top: 12, bottom: 6, left: 8, right: 8 },
        },
        interaction: {
          mode: 'index',
          intersect: false,
        },
        plugins: {
          legend: {
            display: data.series.length > 1 && !(mobile && cfg.hideLegendOnMobile !== false),
            position: mobile ? 'top' : 'bottom',
            labels: {
              boxWidth: 8,
              boxHeight: 8,
              usePointStyle: true,
              pointStyle: 'circle',
              color: dark ? '#9CB3CF' : '#64748B',
              font: { size: 11, weight: '600', family: 'Inter, sans-serif' },
              padding: mobile ? 8 : 14,
            },
          },
          tooltip: {
            backgroundColor: dark ? 'rgba(7,15,28,0.96)' : 'rgba(7,26,82,0.95)',
            titleColor: '#fff',
            titleFont: { size: 11, weight: '600', family: 'Inter, sans-serif' },
            titleMarginBottom: 6,
            bodyColor: PALETTE.softCyan,
            bodyFont: { size: mobile ? 12 : 14, weight: '800', family: 'Inter, sans-serif' },
            bodySpacing: 4,
            padding: mobile ? 10 : 12,
            cornerRadius: 12,
            displayColors: data.series.length > 1,
            caretSize: 6,
            caretPadding: 8,
            borderColor: 'rgba(0,207,232,0.32)',
            borderWidth: 1,
            callbacks: {
              label: function (item) {
                var name = item.dataset.label ? item.dataset.label + ': ' : '';
                return name + prefix + item.parsed.y + suffix;
              },
            },
          },
        },
        scales: {
          x: {
            offset: true,
            grid: { display: false },
            ticks: {
              color: dark ? '#6F87A7' : '#64748B',
              font: { size: mobile ? 9 : 10, weight: '600', family: 'Inter, sans-serif' },
              maxRotation: 0,
              autoSkip: true,
              autoSkipPadding: mobile ? 8 : 14,
              maxTicksLimit: mobile ? 4 : 8,
            },
            border: { display: false },
          },
          y: {
            beginAtZero: true,
            min: yMin,
            max: yMax,
            grid: {
              color: dark ? 'rgba(234,248,255,0.08)' : 'rgba(7,26,82,0.08)',
              drawBorder: false,
            },
            ticks: {
              color: dark ? '#6F87A7' : '#64748B',
              font: { size: mobile ? 9 : 10, weight: '600', family: 'Inter, sans-serif' },
              padding: mobile ? 4 : 8,
              callback: function (v) { return prefix + v + suffix; },
              maxTicksLimit: mobile ? 4 : 5,
            },
            border: { display: false },
          },
        },
      },
    });
    global.chartInstances = global.chartInstances || [];
    global.chartInstances.push(chart);
    return chart;
  }

  global.IcebergTrend = { line: line, palette: PALETTE };
})(window);
