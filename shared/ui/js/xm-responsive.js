/**
 * XMONEY Responsive UI — mobile nav drawer, sidebar toggle, skip link, controls bar.
 */
const XMResponsive = (() => {
  function ensureSkipLink() {
    if (document.querySelector('.skip-link')) return;
    const a = document.createElement('a');
    a.href = '#xmMainContent';
    a.className = 'skip-link';
    a.setAttribute('data-i18n', 'a11y.skip');
    a.textContent = 'Skip to main content';
    document.body.prepend(a);
  }

  function mountPublicNav() {
    const inner = document.querySelector('.xm-nav-inner');
    if (!inner || inner.querySelector('[data-xm-nav-toggle]')) return;

    const links = inner.querySelector('.xm-nav-links');
    if (!links) return;

    const toggle = document.createElement('button');
    toggle.type = 'button';
    toggle.className = 'xm-nav-toggle';
    toggle.setAttribute('data-xm-nav-toggle', '1');
    toggle.setAttribute('data-i18n-aria', 'a11y.menu');
    toggle.setAttribute('aria-label', 'Open menu');
    toggle.setAttribute('aria-expanded', 'false');
    toggle.innerHTML = '☰';

    const backdrop = document.createElement('div');
    backdrop.className = 'xm-nav-drawer-backdrop';
    backdrop.hidden = true;

    const drawer = document.createElement('nav');
    drawer.className = 'xm-nav-drawer';
    drawer.setAttribute('aria-label', 'Mobile navigation');
    drawer.innerHTML = links.innerHTML;

    const controls = document.createElement('div');
    controls.className = 'xm-ui-bar';
    controls.style.display = 'flex';
    controls.style.gap = '0.5rem';
    controls.style.alignItems = 'center';
    controls.style.marginLeft = 'auto';

    inner.insertBefore(toggle, links);
    inner.appendChild(controls);
    document.body.appendChild(backdrop);
    document.body.appendChild(drawer);

    XMTheme.mountControls(controls);
    XMI18n.mountControls(controls);

    function close() {
      drawer.classList.remove('is-open');
      backdrop.classList.remove('is-open');
      backdrop.hidden = true;
      toggle.setAttribute('aria-expanded', 'false');
    }

    toggle.addEventListener('click', () => {
      const open = drawer.classList.toggle('is-open');
      backdrop.classList.toggle('is-open', open);
      backdrop.hidden = !open;
      toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
    backdrop.addEventListener('click', close);
    drawer.querySelectorAll('a').forEach((a) => a.addEventListener('click', close));
  }

  function mountDashboardShell() {
    const dash = document.querySelector('.xm-dash');
    if (!dash) return;

    const sidebar = dash.querySelector('.xm-sidebar');
    const topbar = dash.querySelector('.xm-topbar');
    const main = dash.querySelector('.xm-main') || dash.querySelector('#xmMain');
    if (main && !main.id) main.id = 'xmMainContent';

    if (topbar && !topbar.querySelector('[data-xm-sidebar-toggle]')) {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'xm-sidebar-toggle';
      btn.setAttribute('data-xm-sidebar-toggle', '1');
      btn.setAttribute('data-i18n-aria', 'a11y.sidebar');
      btn.setAttribute('aria-label', 'Open navigation');
      btn.innerHTML = '☰';
      topbar.prepend(btn);

      let overlay = document.querySelector('.xm-sidebar-overlay');
      if (!overlay) {
        overlay = document.createElement('div');
        overlay.className = 'xm-sidebar-overlay';
        document.body.appendChild(overlay);
      }

      const controls = document.createElement('div');
      controls.className = 'xm-ui-bar';
      controls.style.display = 'flex';
      controls.style.gap = '0.5rem';
      controls.style.marginLeft = 'auto';
      const actions = topbar.querySelector('.xm-topbar-actions');
      if (actions) actions.prepend(controls);
      else topbar.appendChild(controls);
      XMTheme.mountControls(controls);
      XMI18n.mountControls(controls);

      function closeSidebar() {
        sidebar?.classList.remove('is-open');
        overlay.classList.remove('is-open');
      }
      btn.addEventListener('click', () => {
        sidebar?.classList.toggle('is-open');
        overlay.classList.toggle('is-open');
      });
      overlay.addEventListener('click', closeSidebar);
      sidebar?.querySelectorAll('a').forEach((a) => a.addEventListener('click', closeSidebar));
    }
  }

  function init() {
    ensureSkipLink();
    mountPublicNav();
    mountDashboardShell();
    document.addEventListener('xm-lang-change', () => {
      if (typeof XMI18n !== 'undefined') XMI18n.applyDom?.();
    });
  }

  return { init, ensureSkipLink, mountPublicNav, mountDashboardShell };
})();
