/**
 * XMONEY Frontend API Client — production session management
 *
 * - JWT access + rotating refresh tokens
 * - Stable device UUID (X-Device-Id)
 * - Silent refresh on 401
 * - Toast helpers + auth gate with /v1/me validation
 */
const XMONEY = (() => {
  const runtime = (typeof window !== 'undefined' && window.XMONEY_RUNTIME) ? window.XMONEY_RUNTIME : {};
  const API_BASE = localStorage.getItem('xm_api_base')
    || runtime.apiBaseUrl
    || 'http://localhost:8080';

  const KEYS = {
    access: 'xm_access_token',
    refresh: 'xm_refresh_token',
    user: 'xm_user',
    device: 'xm_device_uuid',
  };

  let refreshPromise = null;

  function t(key, fallback) {
    return (typeof XMI18n !== 'undefined' && XMI18n.t) ? XMI18n.t(key, fallback) : fallback;
  }

  function getLocale() {
    return localStorage.getItem('xmoney_lang') || 'en';
  }

  function getToken() {
    return localStorage.getItem(KEYS.access);
  }

  function getRefreshToken() {
    return localStorage.getItem(KEYS.refresh);
  }

  function getDeviceId() {
    let id = localStorage.getItem(KEYS.device);
    if (!id) {
      id = (crypto.randomUUID ? crypto.randomUUID() : ('web-' + Date.now() + '-' + Math.random().toString(16).slice(2)));
      localStorage.setItem(KEYS.device, id);
    }
    return id;
  }

  function setSession(data) {
    if (data.access_token) localStorage.setItem(KEYS.access, data.access_token);
    if (data.refresh_token) localStorage.setItem(KEYS.refresh, data.refresh_token);
    if (data.user) localStorage.setItem(KEYS.user, JSON.stringify(data.user));
    if (data.device_uuid) localStorage.setItem(KEYS.device, data.device_uuid);
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

  async function refreshSession() {
    const refresh = getRefreshToken();
    if (!refresh) return false;
    if (refreshPromise) return refreshPromise;

    refreshPromise = (async () => {
      try {
        const res = await fetch(`${API_BASE}/v1/auth/refresh`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Accept: 'application/json',
            'X-Device-Id': getDeviceId(),
          },
          body: JSON.stringify({ refresh_token: refresh }),
        });
        const payload = await res.json().catch(() => ({ success: false }));
        if (!res.ok || !payload.success) {
          clearSession();
          return false;
        }
        setSession(payload.data);
        return true;
      } catch {
        clearSession();
        return false;
      } finally {
        refreshPromise = null;
      }
    })();

    return refreshPromise;
  }

  async function api(path, options = {}) {
    const isForm = options.body instanceof FormData;
    const headers = Object.assign(
      { Accept: 'application/json', 'X-Device-Id': getDeviceId(), 'X-Locale': getLocale() },
      isForm ? {} : { 'Content-Type': 'application/json' },
      options.headers || {}
    );

    const token = getToken();
    if (token) headers.Authorization = `Bearer ${token}`;

    const buildBody = () => {
      if (!options.body) return undefined;
      if (isForm) return options.body;
      if (typeof options.body === 'object') return JSON.stringify(options.body);
      return options.body;
    };

    const doFetch = () => fetch(`${API_BASE}${path}`, {
      ...options,
      headers,
      body: buildBody(),
    });

    let res = await doFetch();
    let payload;
    try {
      payload = await res.json();
    } catch {
      payload = { success: false, message: t('common.invalidServer', 'Invalid server response') };
    }

    const skipRefresh = path.includes('/auth/login')
      || path.includes('/auth/register')
      || path.includes('/auth/refresh')
      || path.includes('/auth/logout');

    if (res.status === 401 && !skipRefresh && !options._retried) {
      const ok = await refreshSession();
      if (ok) {
        return api(path, { ...options, _retried: true });
      }
      clearSession();
      if (!window.location.pathname.includes('login')) {
        window.location.href = 'login.html';
      }
    }

    return { ok: res.ok, status: res.status, ...payload };
  }

  async function ensureSession() {
    if (!requireAuth()) return null;
    const me = await api('/v1/me');
    if (!me.success) {
      clearSession();
      window.location.href = 'login.html';
      return null;
    }
    const cached = getUser() || {};
    setSession({
      user: {
        ...cached,
        email: me.data.email,
        status: me.data.status,
        kyc_status: me.data.kyc_status,
        full_name: me.data.full_name,
      },
    });
    return me.data;
  }

  async function logout() {
    const refresh = getRefreshToken();
    try {
      await api('/v1/auth/logout', {
        method: 'POST',
        body: { refresh_token: refresh },
      });
    } catch (_) { /* ignore */ }
    clearSession();
    window.location.href = 'login.html';
  }

  function showAlert(el, message, type = 'error') {
    if (!el) return;
    el.className = `xm-alert xm-alert-${type}`;
    el.textContent = message;
    el.hidden = false;
  }

  function toast(message, type = 'info') {
    let host = document.getElementById('xm-toast-host');
    if (!host) {
      host = document.createElement('div');
      host.id = 'xm-toast-host';
      host.className = 'xm-toast-host';
      document.body.appendChild(host);
    }
    const el = document.createElement('div');
    el.className = `xm-toast xm-toast-${type}`;
    el.textContent = message;
    host.appendChild(el);
    requestAnimationFrame(() => el.classList.add('show'));
    setTimeout(() => {
      el.classList.remove('show');
      setTimeout(() => el.remove(), 280);
    }, 3200);
  }

  function statusBadge(status) {
    const map = {
      completed: 'success', approved: 'success', active: 'success', verified: 'success', sent: 'success',
      pending: 'warning', pending_payment: 'warning', processing: 'info', under_review: 'warning', queued: 'warning',
      created: 'muted', failed: 'danger', rejected: 'danger', cancelled: 'muted', refunded: 'info',
      blocked: 'danger', expired: 'danger', none: 'muted', read: 'muted',
    };
    const cls = map[status] || 'muted';
    const label = t(`status.${status}`, String(status).replace(/_/g, ' '));
    return `<span class="xm-badge xm-badge-${cls}">${label}</span>`;
  }

  function formatMoney(amount, currency) {
    const n = Number(amount);
    if (Number.isNaN(n)) return '—';
    return `${n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })} ${currency || ''}`.trim();
  }

  function setLoading(btn, loading, label) {
    if (!btn) return;
    if (loading) {
      btn.dataset.label = btn.textContent;
      btn.disabled = true;
      btn.innerHTML = `<span class="xm-spinner"></span> ${label || t('common.pleaseWait', 'Please wait…')}`;
    } else {
      btn.disabled = false;
      btn.textContent = btn.dataset.label || label || t('common.submit', 'Submit');
    }
  }

  function listData(res) {
    if (!res || !res.success) return [];
    const d = res.data;
    return Array.isArray(d) ? d : (d?.rows || []);
  }

  return {
    API_BASE, api, setSession, clearSession, requireAuth, ensureSession, logout,
    getToken, getRefreshToken, getDeviceId, getUser, refreshSession,
    showAlert, toast, statusBadge, formatMoney, setLoading, listData,
  };
})();
