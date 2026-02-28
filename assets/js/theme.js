/**
 * EduQuest — Theme Manager
 * Handles Dark/Light mode toggle with localStorage persistence.
 * Load this FIRST (before other scripts) to prevent flash.
 */

const ThemeManager = (() => {
  const KEY  = 'eduquest_theme';
  const root = document.documentElement;

  const icons = { dark: '🌙', light: '☀️' };

  function getStored()  { return localStorage.getItem(KEY); }
  function getCurrent() { return root.getAttribute('data-theme') || 'dark'; }

  function apply(theme) {
    root.setAttribute('data-theme', theme);
    localStorage.setItem(KEY, theme);
    updateToggleIcon(theme);
  }

  function updateToggleIcon(theme) {
    const btn  = document.getElementById('themeToggle');
    const icon = document.querySelector('#themeToggle .theme-icon');
    if (!icon) return;
    icon.textContent = icons[theme === 'dark' ? 'light' : 'dark'];
    btn?.setAttribute('aria-label', `Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`);
  }

  function toggle() {
    const next = getCurrent() === 'dark' ? 'light' : 'dark';
    apply(next);
    // Micro-animation
    const btn = document.getElementById('themeToggle');
    btn?.animate([
      { transform: 'scale(1) rotate(0deg)' },
      { transform: 'scale(.85) rotate(180deg)' },
      { transform: 'scale(1) rotate(360deg)' },
    ], { duration: 400, easing: 'cubic-bezier(0.34,1.56,0.64,1)' });
  }

  function init() {
    // Apply saved theme (or system preference)
    const stored = getStored();
    if (stored) {
      apply(stored);
    } else {
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      apply(prefersDark ? 'dark' : 'light');
    }

    // Bind toggle button
    document.addEventListener('DOMContentLoaded', () => {
      document.getElementById('themeToggle')?.addEventListener('click', toggle);
      updateToggleIcon(getCurrent());
    });
  }

  // Run immediately to avoid FOUC
  init();

  return { toggle, apply, getCurrent };
})();
