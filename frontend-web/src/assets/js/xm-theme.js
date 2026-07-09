/**
 * XMONEY Theme Manager — light / dark / system with persistence.
 */
const XMTheme = (() => {
  const KEY = 'xmoney_theme';
  const MODES = ['light', 'dark', 'system'];

  function systemPrefersDark() {
    return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
  }

  function resolve(mode) {
    if (mode === 'system') return systemPrefersDark() ? 'dark' : 'light';
    return mode === 'dark' ? 'dark' : 'light';
  }

  function getMode() {
    const saved = localStorage.getItem(KEY);
    return MODES.includes(saved) ? saved : 'system';
  }

  function apply(mode) {
    const resolved = resolve(mode);
    document.documentElement.setAttribute('data-theme', resolved);
    document.documentElement.style.colorScheme = resolved;
    const meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.content = resolved === 'dark' ? '#000000' : '#0B1F3A';
  }

  function setMode(mode) {
    if (!MODES.includes(mode)) return;
    localStorage.setItem(KEY, mode);
    apply(mode);
    document.dispatchEvent(new CustomEvent('xm-theme-change', { detail: { mode } }));
  }

  function mountControls(container) {
    if (!container || container.querySelector('[data-xm-theme]')) return;
    const mode = getMode();
    const wrap = document.createElement('div');
    wrap.className = 'xm-ui-controls';
    wrap.setAttribute('role', 'group');
    wrap.setAttribute('aria-label', 'Theme');
    wrap.innerHTML = `
      <label class="sr-only" for="xmThemeSelect" data-i18n="theme.label">Theme</label>
      <select id="xmThemeSelect" class="xm-ui-select" data-xm-theme aria-label="Theme">
        <option value="light" data-i18n="theme.light">Light</option>
        <option value="dark" data-i18n="theme.dark">Dark</option>
        <option value="system" data-i18n="theme.system">System</option>
      </select>`;
    container.appendChild(wrap);
    const sel = wrap.querySelector('#xmThemeSelect');
    sel.value = mode;
    sel.addEventListener('change', () => setMode(sel.value));
  }

  function init() {
    apply(getMode());
    if (window.matchMedia) {
      window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
        if (getMode() === 'system') apply('system');
      });
    }
    if (localStorage.getItem('xmoney_high_contrast') === '1') {
      document.documentElement.setAttribute('data-contrast', 'high');
    }
  }

  init();
  return { getMode, setMode, apply, mountControls, MODES };
})();
