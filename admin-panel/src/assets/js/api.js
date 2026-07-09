/**
 * XMONEY Admin API Client — production session management
 */
const XMONEY = (() => {
  const runtime = (typeof window !== 'undefined' && window.XMONEY_RUNTIME) ? window.XMONEY_RUNTIME : {};
  const API_BASE = localStorage.getItem('xm_api_base')
    || runtime.apiBaseUrl
    || 'http://localhost:8080';

  const KEYS = {
    access: 'xm_admin_access_token',
    refresh: 'xm_admin_refresh_token',
    user: 'xm_admin',
    device: 'xm_admin_device_uuid',
  };

  let refreshPromise = null;

  function getToken() { return localStorage.getItem(KEYS.access); }
  function getRefreshToken() { return localStorage.getItem(KEYS.refresh); }

  function getDeviceId() {
    let id = localStorage.getItem(KEYS.device);
    if (!id) {
      id = (crypto.randomUUID ? crypto.randomUUID() : ('admin-' + Date.now()));
      localStorage.setItem(KEYS.device, id);
    }
    return id;
  }

  function setSession(data) {
    if (data.access_token) localStorage.setItem(KEYS.access, data.access_token);
    if (data.refresh_token) localStorage.setItem(KEYS.refresh, data.refresh_token);
    if (data.user) localStorage.setItem(KEYS.user, JSON.stringify(data.user));
    if (data.admin) localStorage.setItem(KEYS.user, JSON.stringify(data.admin));
  }

  function clearSession() {
    localStorage.removeItem(KEYS.access);
    localStorage.removeItem(KEYS.refresh);
    localStorage.removeItem(KEYS.user);
  }

  function getUser() {
    try {
      return JSON.parse(localStorage.getItem(KEYS.user) || 'null');
    } catch {
      return null;
    }
  }

  function requireAuth() {
    if (!getToken() && !getRefreshToken()) {
      window.location.href = 'login.html';
      return false;
    }
    return true;
  }

  async function ensureSession() {
    if (!requireAuth()) return null;
    const res = await api('/v1/admin/dashboard');
    if (!res.success) {
      clearSession();
      if (!window.location.pathname.includes('login')) window.location.href = 'login.html';
      return null;
    }
    return getUser();
  }

  async function refreshSession() {
    const refresh = getRefreshToken();
    if (!refresh) return false;
    if (refreshPromise) return refreshPromise;
    refreshPromise = (async () => {
      try {
        const res = await fetch(`${API_BASE}/v1/admin/auth/refresh`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
          body: JSON.stringify({ refresh_token: refresh }),
        });
        const payload = await res.json().catch(() => ({ success: false }));
        if (!res.ok || !payload.success) { clearSession(); return false; }
        setSession(payload.data);
        return true;
      } catch { clearSession(); return false; }
      finally { refreshPromise = null; }
    })();
    return refreshPromise;
  }

  async function api(path, options = {}) {
    const headers = Object.assign(
      { 'Content-Type': 'application/json', Accept: 'application/json', 'X-Device-Id': getDeviceId() },
      options.headers || {}
    );
    const token = getToken();
    if (token) headers.Authorization = `Bearer ${token}`;

    const res = await fetch(`${API_BASE}${path}`, {
      ...options,
      headers,
      body: options.body && typeof options.body === 'object'
        ? JSON.stringify(options.body)
        : options.body,
    });

    let payload;
    try { payload = await res.json(); }
    catch { payload = { success: false, message: 'Invalid server response' }; }

    const skip = path.includes('/auth/login') || path.includes('/auth/refresh') || path.includes('/auth/logout');
    if (res.status === 401 && !skip && !options._retried) {
      const ok = await refreshSession();
      if (ok) return api(path, { ...options, _retried: true });
      clearSession();
      if (!window.location.pathname.includes('login')) window.location.href = 'login.html';
    }

    return { ok: res.ok, status: res.status, ...payload };
  }

  async function logout() {
    try {
      await api('/v1/admin/auth/logout', { method: 'POST', body: { refresh_token: getRefreshToken() } });
    } catch (_) {}
    clearSession();
    window.location.href = 'login.html';
  }

  function showAlert(el, message, type = 'error') {
    if (!el) return;
    el.className = `xm-alert xm-alert-${type}`;
    el.textContent = message;
    el.hidden = false;
  }

  function statusBadge(status) {
    const map = {
      completed: 'success', approved: 'success', active: 'success', verified: 'success',
      pending: 'warning', pending_payment: 'warning', processing: 'info', under_review: 'warning',
      created: 'muted', failed: 'danger', rejected: 'danger', cancelled: 'muted', refunded: 'info',
      blocked: 'danger', expired: 'danger', none: 'muted',
    };
    return `<span class="xm-badge xm-badge-${map[status] || 'muted'}">${String(status).replace(/_/g, ' ')}</span>`;
  }

  function formatMoney(amount, currency) {
    const n = Number(amount);
    if (Number.isNaN(n)) return '—';
    return `${n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })} ${currency || ''}`.trim();
  }

  function formatDate(value) {
    if (!value) return '—';
    const d = new Date(value);
    return Number.isNaN(d.getTime()) ? '—' : d.toLocaleString();
  }

  function toast(message, type = 'info') {
    let el = document.getElementById('xm-admin-toast');
    if (!el) {
      el = document.createElement('div');
      el.id = 'xm-admin-toast';
      el.style.cssText = 'position:fixed;bottom:1.25rem;right:1.25rem;z-index:9999;max-width:320px';
      document.body.appendChild(el);
    }
    const item = document.createElement('div');
    item.className = `xm-alert xm-alert-${type === 'success' ? 'success' : type === 'error' ? 'error' : 'info'}`;
    item.style.marginTop = '0.5rem';
    item.textContent = message;
    el.appendChild(item);
    setTimeout(() => item.remove(), 4000);
  }

  return {
    API_BASE, api, setSession, clearSession, requireAuth, ensureSession, logout, getToken, getRefreshToken, getUser,
    showAlert, statusBadge, formatMoney, formatDate, toast,
  };
})();
