/**
 * Shared customer shell: sidebar + topbar + session bootstrap.
 * Include after api.js on authenticated pages.
 */
const XMShell = (() => {
  const NAV = [
    { href: 'dashboard.html', label: 'Overview', icon: '◆' },
    { href: 'transfer.html', label: 'Send money', icon: '↗' },
    { href: 'beneficiaries.html', label: 'Beneficiaries', icon: '◎' },
    { href: 'transactions.html', label: 'Transactions', icon: '☰' },
    { href: 'wallet.html', label: 'Wallet', icon: '◈' },
    { href: 'notifications.html', label: 'Notifications', icon: '◉' },
    { href: 'kyc.html', label: 'KYC', icon: '▣' },
    { href: 'profile.html', label: 'Profile', icon: '☺' },
    { href: 'settings.html', label: 'Settings', icon: '⚙' },
  ];

  function currentPage() {
    const parts = window.location.pathname.split('/');
    return parts[parts.length - 1] || 'dashboard.html';
  }

  function renderNav() {
    const page = currentPage();
    return NAV.map((item) => {
      const active = page === item.href ? ' active' : '';
      return `<a href="${item.href}" class="${active.trim()}"><span class="xm-nav-ico">${item.icon}</span>${item.label}</a>`;
    }).join('');
  }

  async function mount(options = {}) {
    if (!XMONEY.requireAuth()) return null;

    const title = options.title || 'XMONEY';
    document.title = title + ' — XMONEY';

    // Ensure shell structure if page uses data-xm-shell
    const root = document.querySelector('[data-xm-shell]');
    if (root && !root.querySelector('.xm-sidebar')) {
      const mainHtml = root.innerHTML;
      root.classList.add('xm-dash');
      root.innerHTML = `
        <aside class="xm-sidebar">
          <div class="xm-sidebar-brand"><span class="xm-logo-mark">X</span> XMONEY</div>
          <nav class="xm-sidebar-nav">${renderNav()}</nav>
        </aside>
        <div class="xm-dash-content">
          <header class="xm-topbar">
            <div>
              <h1 class="xm-page-title">${options.heading || title}</h1>
              <p class="xm-page-sub" id="xmWelcomeSub">Loading account…</p>
            </div>
            <div class="xm-topbar-actions">
              <a href="notifications.html" class="xm-icon-btn" title="Notifications" id="xmNotifBtn">◉ <span id="xmNotifCount" class="xm-pill" hidden>0</span></a>
              <button type="button" class="xm-btn xm-btn-secondary" id="xmLogoutBtn">Logout</button>
            </div>
          </header>
          <main class="xm-main" id="xmMain">${mainHtml}</main>
        </div>`;
    } else {
      // Legacy pages: inject nav active states if sidebar exists
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

    // Unread notifications badge
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

    return profile;
  }

  return { mount, renderNav, currentPage };
})();
