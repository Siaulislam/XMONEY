/**
 * XMONEY Admin shared layout — sidebar, active link, logout, i18n.
 */
const XMONEY_ADMIN_SHELL = (() => {
  const LINKS = [
    ['index.html', 'admin.dashboard', 'Dashboard'],
    ['users.html', 'admin.users', 'Users'],
    ['kyc.html', 'admin.kyc', 'KYC review'],
    ['transactions.html', 'admin.transactions', 'Transactions'],
    ['payments.html', 'admin.payments', 'Payments'],
    ['rates.html', 'admin.rates', 'Rates'],
    ['fees.html', 'admin.fees', 'Fees'],
    ['currencies.html', 'admin.currencies', 'Currencies'],
    ['settings.html', 'nav.settings', 'Settings'],
    ['reports.html', 'admin.reports', 'Reports'],
    ['audit.html', 'admin.audit', 'Audit logs'],
  ];

  function t(key, fallback) {
    return (typeof XMI18n !== 'undefined' && XMI18n.t) ? XMI18n.t(key, fallback) : fallback;
  }

  function mount(activeHref) {
    const active = activeHref || location.pathname.split('/').pop() || 'index.html';
    document.querySelectorAll('.xm-sidebar').forEach((aside) => {
      const brand = aside.querySelector('.xm-sidebar-brand');
      const brandHtml = brand ? brand.outerHTML : `<div class="xm-sidebar-brand"><img src="src/assets/branding/xmoney-logo-nav.png" alt="XMONEY" class="xm-logo-img xm-logo-img--sidebar" width="132" height="36" /><span class="xm-logo-admin-tag" data-i18n="admin.tag">Admin</span></div>`;
      aside.innerHTML = brandHtml + LINKS.map(([href, key, label]) =>
        `<a href="${href}" class="${href === active ? 'active' : ''}"><span data-i18n="${key}">${t(key, label)}</span></a>`
      ).join('');
    });

    const navInner = document.querySelector('.xm-nav-inner');
    if (navInner && !navInner.querySelector('[data-admin-logout]')) {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'xm-btn xm-btn-outline';
      btn.style.marginLeft = 'auto';
      btn.dataset.adminLogout = '1';
      btn.setAttribute('data-i18n', 'nav.logout');
      btn.textContent = t('nav.logout', 'Logout');
      btn.onclick = () => XMONEY.logout();
      navInner.style.display = 'flex';
      navInner.style.alignItems = 'center';
      navInner.style.gap = '1rem';
      navInner.appendChild(btn);
    }

    if (typeof XMResponsive !== 'undefined') XMResponsive.mountDashboardShell();

    document.addEventListener('xm-lang-change', () => mount(active));
  }

  return { mount, LINKS };
})();
