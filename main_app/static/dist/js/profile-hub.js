/* ============================================================================
   ICEBERG · profile-hub.js
   Tiny progressive enhancements for the profile/settings hub.
   No dependencies. If it fails, the <details> edit panel still toggles
   natively and every row is a real link.
   ========================================================================== */
(function () {
  'use strict';

  var prefersReduced = window.matchMedia &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  var AVATARS = [
    '🧑‍🎓', '👨‍🎓', '👩‍🎓', '🧑‍💻', '👨‍💻', '👩‍💻',
    '🧑‍🏫', '👨‍🏫', '👩‍🏫', '🤓', '😊', '😎',
    '💡', '📚', '🏆', '⭐', '💪', '🎯',
    '🌟', '🦉', '🌍', '✏️', '🎨', '🔬'
  ];
  var BG = [
    '#1B3F7A', '#0C1F45', '#7C3AED', '#0891B2', '#1F2937', '#6D28D9',
    '#BE185D', '#B45309', '#C2410C', '#15803D', '#0284C7', '#4338CA',
    '#A16207', '#7C2D12', '#B45309', '#EA580C', '#B91C1C', '#991B1B',
    '#4F46E5', '#65A30D', '#0D9488', '#6B7280', '#DB2777', '#0891B2'
  ];

  function hub() {
    return document.querySelector('[data-profile-hub]');
  }

  // Rows that open the collapsible "Edit Profile" panel and scroll to it.
  document.addEventListener('click', function (e) {
    var trigger = e.target.closest('[data-open-details]');
    if (!trigger) return;
    var panel = document.getElementById(trigger.getAttribute('data-open-details'));
    if (!panel) return;                       // fall through to normal anchor
    e.preventDefault();
    panel.open = true;
    var focusSel = trigger.getAttribute('data-focus');
    panel.scrollIntoView({ behavior: prefersReduced ? 'auto' : 'smooth', block: 'start' });
    if (focusSel) {
      var f = panel.querySelector(focusSel);
      if (f) setTimeout(function () { try { f.focus(); } catch (_) {} }, 320);
    }
  });

  // Password change notice (warns the session will end).
  document.addEventListener('DOMContentLoaded', function () {
    var pw = document.getElementById('id_password');
    var notice = document.getElementById('pw-notice');
    if (pw && notice) {
      pw.addEventListener('input', function () {
        notice.style.display = pw.value ? 'block' : 'none';
      });
    }
  });

  // Avatar picker. Uses the existing save_avatar endpoint; if JS fails, only
  // this optional sticker flow is lost. The real profile form still works.
  var currentAvatar = '';
  var pendingAvatar = '';

  function applyAvatar(avId) {
    var inner = document.getElementById('profile-avatar-inner');
    var wrap = document.getElementById('profile-avatar-display');
    var idx = parseInt(avId, 10) - 1;
    if (!inner || !wrap || idx < 0 || idx >= AVATARS.length) return;
    inner.textContent = AVATARS[idx];
    inner.style.fontSize = '40px';
    wrap.style.background = BG[idx];
    wrap.classList.add('profile-avatar-sticker');
  }

  function buildAvatarGrid() {
    var grid = document.getElementById('avatar-grid');
    if (!grid) return;
    grid.innerHTML = '';
    AVATARS.forEach(function (emoji, i) {
      var option = document.createElement('button');
      option.type = 'button';
      option.className = 'avatar-option' + (currentAvatar === String(i + 1) ? ' selected' : '');
      option.style.background = BG[i];
      option.textContent = emoji;
      option.dataset.avatarValue = String(i + 1);
      option.setAttribute('aria-label', 'Avatar option ' + String(i + 1));
      option.addEventListener('click', function () {
        grid.querySelectorAll('.avatar-option').forEach(function (node) {
          node.classList.remove('selected');
        });
        option.classList.add('selected');
        pendingAvatar = option.dataset.avatarValue;
      });
      grid.appendChild(option);
    });
  }

  window.openAvatarModal = function () {
    var modal = document.getElementById('avatar-modal');
    if (!modal) return;
    pendingAvatar = currentAvatar;
    buildAvatarGrid();
    modal.classList.add('open');
    modal.setAttribute('aria-hidden', 'false');
  };

  window.closeAvatarModal = function () {
    var modal = document.getElementById('avatar-modal');
    if (!modal) return;
    modal.classList.remove('open');
    modal.setAttribute('aria-hidden', 'true');
  };

  window.saveAvatar = function () {
    var root = hub();
    if (!root || !pendingAvatar) return;
    var url = root.dataset.avatarSaveUrl;
    var csrf = root.dataset.csrf;
    if (!url || !csrf) return;
    fetch(url, {
      method: 'POST',
      headers: {
        'X-CSRFToken': csrf,
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: 'avatar=' + encodeURIComponent(pendingAvatar)
    }).then(function (response) {
      return response.json();
    }).then(function (data) {
      if (data.status !== 'ok') return;
      currentAvatar = pendingAvatar;
      applyAvatar(currentAvatar);
      window.closeAvatarModal();
      var toast = document.getElementById('avatar-toast');
      if (toast) {
        toast.classList.add('show');
        setTimeout(function () { toast.classList.remove('show'); }, 2200);
      }
    }).catch(function () {});
  };

  document.addEventListener('click', function (e) {
    if (e.target.closest('[data-open-avatar]')) {
      e.preventDefault();
      window.openAvatarModal();
      return;
    }
    if (e.target.closest('[data-close-avatar]')) {
      e.preventDefault();
      window.closeAvatarModal();
      return;
    }
    if (e.target.closest('[data-save-avatar]')) {
      e.preventDefault();
      window.saveAvatar();
    }
  });

  document.addEventListener('DOMContentLoaded', function () {
    var root = hub();
    if (!root) return;
    currentAvatar = root.dataset.currentAvatar || '';
    pendingAvatar = currentAvatar;
    if (currentAvatar) applyAvatar(currentAvatar);
    var modal = document.getElementById('avatar-modal');
    if (modal) {
      modal.addEventListener('click', function (e) {
        if (e.target === modal) window.closeAvatarModal();
      });
    }
  });

  // Theme selector. Students persist to the existing DB-backed endpoint.
  // Admins/teachers use the existing localStorage theme mechanism.
  function resolveSystemTheme() {
    return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches
      ? 'dark'
      : 'bright';
  }

  function applyThemeChoice(choice) {
    var resolved = choice === 'system' ? resolveSystemTheme() : choice;
    if (window.iceApplyThemeState) {
      window.iceApplyThemeState(resolved);
    } else {
      document.documentElement.setAttribute('data-theme', resolved);
      document.documentElement.classList.toggle('dark-mode', resolved === 'dark');
      document.documentElement.classList.toggle('bright-mode', resolved === 'bright');
      document.body.classList.toggle('dark-mode', resolved === 'dark');
      document.body.classList.toggle('bright-mode', resolved === 'bright');
    }
  }

  function setActiveThemeButton(choice) {
    document.querySelectorAll('[data-theme-choice]').forEach(function (btn) {
      btn.classList.toggle('active', btn.dataset.themeChoice === choice);
    });
  }

  function currentThemeChoice(root) {
    var userType = (document.body && document.body.dataset && document.body.dataset.userType) || '';
    if (root.dataset.themeSaveUrl) return root.dataset.currentTheme || 'system';
    try {
      return localStorage.getItem('ice_ui_theme') || 'system';
    } catch (_) {
      return userType ? 'system' : (root.dataset.currentTheme || 'system');
    }
  }

  document.addEventListener('DOMContentLoaded', function () {
    var root = hub();
    if (!root) return;
    setActiveThemeButton(currentThemeChoice(root));
  });

  document.addEventListener('click', function (e) {
    var btn = e.target.closest('[data-theme-choice]');
    if (!btn) return;
    var root = hub();
    if (!root) return;
    var choice = btn.dataset.themeChoice || 'system';
    setActiveThemeButton(choice);
    applyThemeChoice(choice);

    if (root.dataset.themeSaveUrl) {
      fetch(root.dataset.themeSaveUrl, {
        method: 'POST',
        headers: {
          'X-CSRFToken': root.dataset.csrf,
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: 'theme=' + encodeURIComponent(choice)
      }).catch(function () {});
    } else {
      try { localStorage.setItem('ice_ui_theme', choice); } catch (_) {}
    }

    var msg = document.getElementById('theme-msg');
    if (msg) {
      msg.style.display = 'block';
      setTimeout(function () { msg.style.display = 'none'; }, 2200);
    }
  });
})();
