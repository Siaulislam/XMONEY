/**
 * Premium XMONEY web loading splash — black background, centered official logo.
 */
(() => {
  const id = 'xmoney-app-loader';
  if (document.getElementById(id)) return;

  const style = document.createElement('style');
  style.textContent = `
    #${id} {
      position: fixed; inset: 0; z-index: 99999;
      display: grid; place-items: center;
      background: #000000;
      transition: opacity 0.35s ease, visibility 0.35s ease;
    }
    #${id}.xm-hide { opacity: 0; visibility: hidden; pointer-events: none; }
    #${id} img { width: min(320px, 72vw); height: auto; }
  `;
  document.head.appendChild(style);

  const wrap = document.createElement('div');
  wrap.id = id;
  wrap.setAttribute('role', 'status');
  wrap.setAttribute('aria-label', 'Loading XMONEY');
  const img = document.createElement('img');
  img.src = 'src/assets/branding/xmoney-logo-nav.png';
  img.alt = 'XMONEY';
  wrap.appendChild(img);
  document.body.prepend(wrap);

  function hide() {
    wrap.classList.add('xm-hide');
    setTimeout(() => wrap.remove(), 400);
  }
  if (document.readyState === 'complete') hide();
  else window.addEventListener('load', hide, { once: true });
})();
