/**
 * XMONEY i18n — English, Arabic, Urdu with RTL/LTR auto-switch.
 */
const XMI18n = (() => {
  const KEY = 'xmoney_lang';
  const RTL = new Set(['ar', 'ur']);
  const SUPPORTED = ['en', 'ar', 'ur'];
  let catalog = {};
  let lang = 'en';

  function basePath() {
    const scripts = document.querySelectorAll('script[src*="xm-i18n"]');
    const src = scripts.length ? scripts[scripts.length - 1].getAttribute('src') : 'src/assets/js/xm-i18n.js';
    return src.replace(/js\/xm-i18n\.js.*$/, 'i18n/');
  }

  async function loadLocale(code) {
    const res = await fetch(`${basePath()}${code}.json`, { cache: 'no-cache' });
    if (!res.ok) throw new Error(`Locale ${code} not found`);
    return res.json();
  }

  function t(key, fallback) {
    return catalog[key] ?? fallback ?? key;
  }

  function applyDom() {
    document.querySelectorAll('[data-i18n]').forEach((el) => {
      const key = el.getAttribute('data-i18n');
      const val = t(key, el.textContent);
      if (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA') {
        if (el.hasAttribute('placeholder')) el.placeholder = val;
      } else {
        el.textContent = val;
      }
    });
    document.querySelectorAll('[data-i18n-placeholder]').forEach((el) => {
      el.placeholder = t(el.getAttribute('data-i18n-placeholder'), el.placeholder);
    });
    document.querySelectorAll('[data-i18n-title]').forEach((el) => {
      el.title = t(el.getAttribute('data-i18n-title'), el.title);
    });
    document.querySelectorAll('[data-i18n-aria]').forEach((el) => {
      el.setAttribute('aria-label', t(el.getAttribute('data-i18n-aria'), el.getAttribute('aria-label') || ''));
    });
  }

  function applyDirection(code) {
    const dir = RTL.has(code) ? 'rtl' : 'ltr';
    document.documentElement.setAttribute('dir', dir);
    document.documentElement.setAttribute('lang', code);
  }

  async function setLang(code) {
    if (!SUPPORTED.includes(code)) return;
    catalog = await loadLocale(code);
    lang = code;
    localStorage.setItem(KEY, code);
    applyDirection(code);
    applyDom();
    document.dispatchEvent(new CustomEvent('xm-lang-change', { detail: { lang: code } }));
  }

  async function init() {
    const saved = localStorage.getItem(KEY);
    const browser = (navigator.language || 'en').slice(0, 2);
    const initial = SUPPORTED.includes(saved) ? saved : (SUPPORTED.includes(browser) ? browser : 'en');
    await setLang(initial);
  }

  function mountControls(container) {
    if (!container || container.querySelector('[data-xm-lang]')) return;
    const wrap = document.createElement('div');
    wrap.className = 'xm-ui-controls';
    wrap.innerHTML = `
      <label class="sr-only" for="xmLangSelect" data-i18n="lang.label">Language</label>
      <select id="xmLangSelect" class="xm-ui-select" data-xm-lang aria-label="Language">
        <option value="en" data-i18n="lang.en">English</option>
        <option value="ar" data-i18n="lang.ar">Arabic</option>
        <option value="ur" data-i18n="lang.ur">Urdu</option>
      </select>`;
    container.appendChild(wrap);
    const sel = wrap.querySelector('#xmLangSelect');
    sel.value = lang;
    sel.addEventListener('change', () => setLang(sel.value));
  }

  return { init, setLang, t, getLang: () => lang, mountControls, applyDom, SUPPORTED };
})();
