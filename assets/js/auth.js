/**
 * EduQuest — Auth Page JavaScript
 * Handles: tab switching, form validation, login/register API calls,
 *          password strength, toast notifications, XP pop animations.
 */

/* ═══════════════════════════════════════════════════
   TOAST SYSTEM
═══════════════════════════════════════════════════ */
const Toast = (() => {
  const container = () => document.getElementById('toastContainer');
  const ICONS = { success: '✅', error: '❌', info: '💡', warning: '⚠️' };

  function show(type, title, message, duration = 4000) {
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.innerHTML = `
      <span class="toast-icon">${ICONS[type] || 'ℹ️'}</span>
      <div class="toast-body">
        <div class="toast-title">${title}</div>
        ${message ? `<div class="toast-msg">${message}</div>` : ''}
      </div>
      <button class="toast-close" aria-label="Close">×</button>
    `;

    toast.querySelector('.toast-close').addEventListener('click', () => dismiss(toast));
    container().appendChild(toast);

    if (duration > 0) setTimeout(() => dismiss(toast), duration);
    return toast;
  }

  function dismiss(toast) {
    if (!toast.parentNode) return;
    toast.classList.add('removing');
    toast.addEventListener('animationend', () => toast.remove(), { once: true });
  }

  return {
    success: (t, m, d) => show('success', t, m, d),
    error:   (t, m, d) => show('error',   t, m, d),
    info:    (t, m, d) => show('info',    t, m, d),
    warning: (t, m, d) => show('warning', t, m, d),
  };
})();

/* ═══════════════════════════════════════════════════
   XP POP ANIMATION
═══════════════════════════════════════════════════ */
function fireXpPop(xp, x, y) {
  const el = document.getElementById('xpPop');
  if (!el) return;
  el.textContent = `+${xp} XP ⚡`;
  el.style.left = `${x}px`;
  el.style.top  = `${y}px`;
  el.className = 'xp-pop';
  void el.offsetWidth; // reflow
  el.classList.add('firing');
  el.addEventListener('animationend', () => { el.className = 'xp-pop'; }, { once: true });
}

/* ═══════════════════════════════════════════════════
   API HELPER
═══════════════════════════════════════════════════ */
async function apiPost(endpoint, data) {
  const res = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
    credentials: 'same-origin',
  });
  return res.json();
}

/* ═══════════════════════════════════════════════════
   FORM STATE HELPERS
═══════════════════════════════════════════════════ */
function setLoading(btnId, isLoading) {
  const btn    = document.getElementById(btnId);
  const text   = btn?.querySelector('.btn-text');
  const loader = btn?.querySelector('.btn-loader');
  if (!btn) return;
  btn.disabled = isLoading;
  text?.classList.toggle('hidden', isLoading);
  loader?.classList.toggle('hidden', !isLoading);
}

function showFormError(errorId, message) {
  const el = document.getElementById(errorId);
  if (!el) return;
  el.textContent = message;
  el.style.display = 'block';
}

function clearFormError(errorId) {
  const el = document.getElementById(errorId);
  if (el) { el.textContent = ''; el.style.display = 'none'; }
}

/* ═══════════════════════════════════════════════════
   PASSWORD STRENGTH METER
═══════════════════════════════════════════════════ */
function checkPasswordStrength(password) {
  let score = 0;
  if (password.length >= 8)  score++;
  if (password.length >= 12) score++;
  if (/[A-Z]/.test(password)) score++;
  if (/[0-9]/.test(password)) score++;
  if (/[^a-zA-Z0-9]/.test(password)) score++;

  const levels = [
    { label: '',          color: '',            pct: 0   },
    { label: 'Too weak',  color: '#f87171',     pct: 20  },
    { label: 'Weak',      color: '#fb923c',     pct: 40  },
    { label: 'Fair',      color: '#fbbf24',     pct: 60  },
    { label: 'Strong',    color: '#34d399',     pct: 80  },
    { label: '💪 Excellent!', color: '#a78bfa', pct: 100 },
  ];

  return levels[Math.min(score, 5)];
}

/* ═══════════════════════════════════════════════════
   USERNAME AVAILABILITY CHECK (debounced)
═══════════════════════════════════════════════════ */
let usernameTimer = null;
function onUsernameInput(e) {
  const val  = e.target.value.trim();
  const hint = document.getElementById('usernameHint');
  if (!hint) return;

  clearTimeout(usernameTimer);

  if (!val) { hint.textContent = ''; hint.className = 'input-hint'; return; }

  if (!/^[a-zA-Z0-9_]{3,30}$/.test(val)) {
    hint.textContent = '3-30 chars, letters/numbers/underscore only';
    hint.className = 'input-hint invalid';
    return;
  }

  hint.textContent = 'Checking…';
  hint.className   = 'input-hint';

  usernameTimer = setTimeout(async () => {
    // Simple client-side format check (server will do real check on submit)
    hint.textContent = '✓ Looks good!';
    hint.className   = 'input-hint valid';
  }, 500);
}

/* ═══════════════════════════════════════════════════
   PASSWORD TOGGLE VISIBILITY
═══════════════════════════════════════════════════ */
function initPasswordToggles() {
  document.querySelectorAll('.pw-toggle').forEach(btn => {
    btn.addEventListener('click', () => {
      const input = btn.previousElementSibling;
      if (!input) return;
      const show = input.type === 'password';
      input.type = show ? 'text' : 'password';
      btn.textContent = show ? '🙈' : '👁';
    });
  });
}

/* ═══════════════════════════════════════════════════
   TAB SWITCHING
═══════════════════════════════════════════════════ */
function initTabs() {
  const tabs  = document.querySelectorAll('.auth-tab');
  const forms = document.querySelectorAll('.auth-form');

  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      const target = tab.dataset.tab;

      tabs.forEach(t => t.classList.toggle('active', t.dataset.tab === target));
      forms.forEach(f => {
        const isActive = f.dataset.tabForm === target;
        f.classList.toggle('active', isActive);
        if (isActive) {
          f.style.animation = 'none';
          void f.offsetWidth;
          f.style.animation = '';
        }
      });

      // Clear errors
      clearFormError('loginError');
      clearFormError('registerError');
    });
  });
}

/* ═══════════════════════════════════════════════════
   LOGIN HANDLER
═══════════════════════════════════════════════════ */
async function handleLogin(e) {
  e.preventDefault();
  clearFormError('loginError');

  const form = document.getElementById('loginForm');
  const data = {
    action:     'login',
    identifier: form.identifier.value.trim(),
    password:   form.password.value,
    remember:   form.remember?.checked ?? false,
  };

  if (!data.identifier || !data.password) {
    showFormError('loginError', 'Please fill in all fields.');
    return;
  }

  setLoading('loginBtn', true);

  try {
    const res = await apiPost('api/auth.php?action=login', data);

    if (res.success) {
      // Show streak notification
      if (res.data?.streak?.is_new_day) {
        const streak = res.data.streak;
        Toast.success(
          `🔥 Day ${streak.streak} Streak!`,
          streak.bonus_xp > 0 ? `+${streak.bonus_xp} XP bonus earned!` : 'Keep it up!',
          5000
        );
      }

      Toast.success('Welcome back! 👋', res.message, 2000);

      // XP pop animation
      const btn = document.getElementById('loginBtn');
      const rect = btn.getBoundingClientRect();
      if (res.data?.streak?.bonus_xp > 0) {
        fireXpPop(res.data.streak.bonus_xp, rect.left + rect.width / 2, rect.top);
      }

      // Store auth data
      if (res.data?.user) {
        sessionStorage.setItem('eq_user', JSON.stringify(res.data.user));
      }

      setTimeout(() => {
        window.location.href = res.data?.redirect || 'dashboard.php';
      }, 800);
    } else {
      showFormError('loginError', res.message || 'Login failed. Please try again.');
      setLoading('loginBtn', false);
    }
  } catch (err) {
    showFormError('loginError', 'Network error. Please check your connection.');
    setLoading('loginBtn', false);
  }
}

/* ═══════════════════════════════════════════════════
   REGISTER HANDLER
═══════════════════════════════════════════════════ */
async function handleRegister(e) {
  e.preventDefault();
  clearFormError('registerError');

  const form = document.getElementById('registerForm');
  const data = {
    action:      'register',
    full_name:   form.full_name.value.trim(),
    username:    form.username.value.trim(),
    email:       form.email.value.trim(),
    grade_level: parseInt(form.grade_level.value),
    password:    form.password.value,
  };

  // Client-side validation
  if (!data.full_name || !data.username || !data.email || !data.grade_level || !data.password) {
    showFormError('registerError', 'Please fill in all required fields.');
    return;
  }
  if (!/^[a-zA-Z0-9_]{3,30}$/.test(data.username)) {
    showFormError('registerError', 'Username: 3-30 characters, letters/numbers/underscore only.');
    return;
  }
  if (data.password.length < 8) {
    showFormError('registerError', 'Password must be at least 8 characters.');
    return;
  }

  setLoading('registerBtn', true);

  try {
    const res = await apiPost('api/auth.php?action=register', data);

    if (res.success) {
      Toast.success('Account created! 🎉', 'Welcome to EduQuest!', 3000);

      if (res.data?.user) {
        sessionStorage.setItem('eq_user', JSON.stringify(res.data.user));
      }

      // XP pop
      const btn = document.getElementById('registerBtn');
      const rect = btn.getBoundingClientRect();
      fireXpPop(10, rect.left + rect.width / 2, rect.top);

      setTimeout(() => {
        window.location.href = res.data?.redirect || 'dashboard.php';
      }, 1000);
    } else {
      showFormError('registerError', res.message || 'Registration failed. Please try again.');
      setLoading('registerBtn', false);
    }
  } catch (err) {
    showFormError('registerError', 'Network error. Please check your connection.');
    setLoading('registerBtn', false);
  }
}

/* ═══════════════════════════════════════════════════
   DEMO LOGIN
═══════════════════════════════════════════════════ */
async function handleDemoLogin() {
  const form = document.getElementById('loginForm');
  form.identifier.value = 'alex_ng';
  form.password.value   = 'Password123!';

  Toast.info('Demo Mode', 'Logging in as Alex Ng (top student)…', 3000);

  // Small delay for UX
  await new Promise(r => setTimeout(r, 600));
  document.getElementById('loginForm').dispatchEvent(new Event('submit'));
}

/* ═══════════════════════════════════════════════════
   INIT
═══════════════════════════════════════════════════ */
document.addEventListener('DOMContentLoaded', () => {
  // Tabs
  initTabs();

  // Password toggles
  initPasswordToggles();

  // Login form
  document.getElementById('loginForm')?.addEventListener('submit', handleLogin);

  // Register form
  document.getElementById('registerForm')?.addEventListener('submit', handleRegister);

  // Demo login
  document.getElementById('demoLoginBtn')?.addEventListener('click', handleDemoLogin);

  // Username check
  document.getElementById('reg_username')?.addEventListener('input', onUsernameInput);

  // Password strength meter
  document.getElementById('reg_password')?.addEventListener('input', e => {
    const pw    = e.target.value;
    const bar   = document.getElementById('pwStrengthBar');
    const label = document.getElementById('pwStrengthLabel');
    if (!bar || !label) return;

    const { pct, color, label: lbl } = checkPasswordStrength(pw);
    bar.style.width      = pw ? `${pct}%` : '0%';
    bar.style.background = color;
    label.textContent    = pw ? lbl : '';
    label.style.color    = color;
  });

  // Auto-focus first input
  document.querySelector('.auth-form.active .form-input')?.focus();

  // Check URL params (e.g., ?tab=register from a redirect)
  const params = new URLSearchParams(window.location.search);
  if (params.get('tab') === 'register') {
    document.querySelector('[data-tab="register"]')?.click();
  }
  if (params.get('msg') === 'session_expired') {
    Toast.warning('Session Expired', 'Please sign in again.', 5000);
  }
});

/* ═══════════════════════════════════════════════════
   Global Toast export (used by other pages too)
═══════════════════════════════════════════════════ */
window.Toast    = Toast;
window.fireXpPop = fireXpPop;
window.apiPost  = apiPost;
