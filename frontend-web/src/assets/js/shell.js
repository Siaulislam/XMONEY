/**
 * Shared customer shell: sidebar + topbar + session bootstrap.
 * Include after api.js on authenticated pages.
 */
const XMShell = (() => {
  const NAV = [
    { href: 'dashboard.html', labelKey: 'nav.overview', label: 'Overview', icon: '◆' },
    { href: 'transfer.html', labelKey: 'nav.send', label: 'Send money', icon: '↗' },
    { href: 'beneficiaries.html', labelKey: 'nav.beneficiaries', label: 'Beneficiaries', icon: '◎' },
    { href: 'transactions.html', labelKey: 'nav.transactions', label: 'Transactions', icon: '☰' },
    { href: 'wallet.html', labelKey: 'nav.wallet', label: 'Wallet', icon: '◈' },
    { href: 'notifications.html', labelKey: 'nav.notifications', label: 'Notifications', icon: '◉' },
    { href: 'kyc.html', labelKey: 'nav.kyc', label: 'KYC', icon: '▣' },
    { href: 'profile.html', labelKey: 'nav.profile', label: 'Profile', icon: '☺' },
    { href: 'settings.html', labelKey: 'nav.settings', label: 'Settings', icon: '⚙' },
  ];

  function t(key, fallback) {
    return (typeof XMI18n !== 'undefined' && XMI18n.t) ? XMI18n.t(key, fallback) : fallback;
  }

  function currentPage() {
    const parts = window.location.pathname.split('/');
    return parts[parts.length - 1] || 'dashboard.html';
  }

  function renderNav() {
    const page = currentPage();
    return NAV.map((item) => {
      const active = page === item.href ? ' active' : '';
      const label = t(item.labelKey, item.label);
      return `<a href="${item.href}" class="${active.trim()}"><span class="xm-nav-ico" aria-hidden="true">${item.icon}</span><span data-i18n="${item.labelKey}">${label}</span></a>`;
    }).join('');
  }

  async function mount(options = {}) {
    if (!XMONEY.requireAuth()) return null;

    const title = options.title || 'XMONEY';
    document.title = `${title} — XMONEY`;

    const root = document.querySelector('[data-xm-shell]');
    if (root && !root.querySelector('.xm-sidebar')) {
      const mainHtml = root.innerHTML;
      root.classList.add('xm-dash');
      root.innerHTML = `
        <aside class="xm-sidebar" aria-label="Main navigation">
          <div class="xm-sidebar-brand"><img src="src/assets/branding/xmoney-logo-nav.png" alt="XMONEY" class="xm-logo-img xm-logo-img--sidebar" width="132" height="36" /></div>
          <nav class="xm-sidebar-nav">${renderNav()}</nav>
        </aside>
        <div class="xm-dash-content">
          <header class="xm-topbar">
            <div>
              <h1 class="xm-page-title">${options.heading || title}</h1>
              <p class="xm-page-sub" id="xmWelcomeSub">${t('loading', 'Loading…')}</p>
            </div>
            <div class="xm-topbar-actions">
              <a href="notifications.html" class="xm-icon-btn" data-i18n-title="nav.notifications" title="Notifications" id="xmNotifBtn" aria-label="Notifications">◉ <span id="xmNotifCount" class="xm-pill" hidden>0</span></a>
              <button type="button" class="xm-btn xm-btn-secondary" id="xmLogoutBtn" data-i18n="nav.logout">Logout</button>
            </div>
          </header>
          <main class="xm-main" id="xmMainContent">${mainHtml}</main>
        </div>`;
      if (typeof XMResponsive !== 'undefined') XMResponsive.mountDashboardShell();
    } else {
      document.querySelectorAll('.xm-sidebar a').forEach((a) => {
        if (a.getAttribute('href') === currentPage()) a.classList.add('active');
      });
      const logout = document.getElementById('logoutBtn') || document.getElementById('xmLogoutBtn');
      if (logout) logout.onclick = () => XMONEY.logout();
    }

    const logoutBtn = document.getElementById('xmLogoutBtn');
    if (logoutBtn) logoutBtn.onclick = () => XMONEY.logout();

    const profile = await XMONEY.ensureSession();
    if (!profile) return null;

    const sub = document.getElementById('xmWelcomeSub') || document.getElementById('welcomeSub');
    if (sub) sub.textContent = `${profile.full_name} · ${profile.email}`;

    try {
      const n = await XMONEY.api('/v1/notifications?limit=1');
      if (n.success && n.data.unread_count > 0) {
        const pill = document.getElementById('xmNotifCount');
        if (pill) {
          pill.hidden = false;
          pill.textContent = String(n.data.unread_count);
        }
      }
    } catch (_) { /* optional */ }

    document.addEventListener('xm-lang-change', () => {
      const nav = document.querySelector('.xm-sidebar-nav');
      if (nav) nav.innerHTML = renderNav();
      if (typeof XMI18n !== 'undefined') XMI18n.applyDom();
    });

    return profile;
  }

  return { mount, renderNav, currentPage, NAV };
})();
