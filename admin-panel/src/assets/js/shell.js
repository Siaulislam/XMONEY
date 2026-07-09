/**
 * XMONEY Admin shared layout — sidebar, active link, logout.
 */
const XMONEY_ADMIN_SHELL = (() => {
  const LINKS = [
    ['index.html', 'Dashboard'],
    ['users.html', 'Users'],
    ['kyc.html', 'KYC review'],
    ['transactions.html', 'Transactions'],
    ['payments.html', 'Payments'],
    ['rates.html', 'Rates'],
    ['fees.html', 'Fees'],
    ['currencies.html', 'Currencies'],
    ['settings.html', 'Settings'],
    ['reports.html', 'Reports'],
    ['audit.html', 'Audit logs'],
  ];

  function mount(activeHref) {
    const active = activeHref || location.pathname.split('/').pop() || 'index.html';
    document.querySelectorAll('.xm-sidebar').forEach((aside) => {
      const brand = aside.querySelector('.xm-sidebar-brand');
      const brandHtml = brand ? brand.outerHTML : `<div class="xm-sidebar-brand"><img src="src/assets/branding/xmoney-logo-nav.png" alt="XMONEY" class="xm-logo-img xm-logo-img--sidebar" width="132" height="36" /><span class="xm-logo-admin-tag">Admin</span></div>`;
      aside.innerHTML = brandHtml + LINKS.map(([href, label]) =>
        `<a href="${href}" class="${href === active ? 'active' : ''}">${label}</a>`
      ).join('');
    });

    const navInner = document.querySelector('.xm-nav-inner');
    if (navInner && !navInner.querySelector('[data-admin-logout]')) {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'xm-btn xm-btn-outline';
      btn.style.marginLeft = 'auto';
      btn.dataset.adminLogout = '1';
      btn.textContent = 'Logout';
      btn.onclick = () => XMONEY.logout();
      navInner.style.display = 'flex';
      navInner.style.alignItems = 'center';
      navInner.style.gap = '1rem';
      navInner.appendChild(btn);
    }
  }

  return { mount, LINKS };
})();
