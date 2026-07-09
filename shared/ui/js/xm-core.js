/**
 * XMONEY Core UI bootstrap — theme, i18n, responsive shell.
 * Load after xm-theme.js and xm-i18n.js.
 */
(async () => {
  if (typeof XMTheme !== 'undefined') XMTheme.init?.();
  if (typeof XMI18n !== 'undefined') await XMI18n.init();
  if (typeof XMResponsive !== 'undefined') XMResponsive.init();
  document.addEventListener('xm-lang-change', () => {
    if (typeof XMI18n !== 'undefined') {
      document.querySelectorAll('[data-xm-theme]').forEach((sel) => {
        const opt = sel.querySelector(`option[value="${XMTheme.getMode()}"]`);
        if (opt && sel.value !== XMTheme.getMode()) sel.value = XMTheme.getMode();
      });
    }
  });
})();
