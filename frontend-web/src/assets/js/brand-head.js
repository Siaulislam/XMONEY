/**
 * Injects XMONEY favicon, PWA, and social meta tags when not already present.
 */
(() => {
  const base = document.currentScript?.src.replace(/\/js\/brand-head\.js.*$/, '') || 'src/assets/branding';
  const tags = [
    ['link', { rel: 'icon', href: 'favicon.ico', sizes: 'any' }],
    ['link', { rel: 'icon', type: 'image/png', sizes: '32x32', href: `${base}/favicon-32x32.png` }],
    ['link', { rel: 'icon', type: 'image/png', sizes: '16x16', href: `${base}/favicon-16x16.png` }],
    ['link', { rel: 'apple-touch-icon', href: `${base}/apple-touch-icon.png` }],
    ['link', { rel: 'manifest', href: 'manifest.webmanifest' }],
    ['meta', { name: 'theme-color', content: '#000000' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:image', content: `${base}/og-image.png` }],
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
    ['meta', { name: 'twitter:image', content: `${base}/social-sharing.png` }],
  ];
  const head = document.head;
  tags.forEach(([name, attrs]) => {
    const key = attrs.rel || attrs.name || attrs.property;
    const exists = head.querySelector(`[rel="${attrs.rel}"], [name="${attrs.name}"], [property="${attrs.property}"]`);
    if (exists && (attrs.rel === 'icon' || attrs.name === 'theme-color')) return;
    if (exists) return;
    const el = document.createElement(name);
    Object.entries(attrs).forEach(([k, v]) => el.setAttribute(k, v));
    head.appendChild(el);
  });
})();
