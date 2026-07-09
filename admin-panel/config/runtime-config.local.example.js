/**
 * Local development runtime override.
 * Copy to runtime-config.js for local testing, or set in browser:
 *   localStorage.setItem('xm_api_base', 'http://localhost:8080');
 */
window.XMONEY_RUNTIME = {
  appName: 'XMONEY',
  apiBaseUrl: 'http://localhost:8080',
  webBasePath: '/',
  adminBasePath: '/admin/',
};
