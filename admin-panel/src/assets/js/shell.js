/**
 * XMONEY Admin shared layout — sidebar, active link, logout.
 */
const XMONEY_ADMIN_SHELL = (() => {
  const LINKS = [
    ['index.html', 'Dashboard'],
    ['users.html', 'Users'],
    ['kyc.html', 'KYC review'],
    ['transactions.html', 'Transactions'],
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
      aside.innerHTML = LINKS.map(([href, label]) =>
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
