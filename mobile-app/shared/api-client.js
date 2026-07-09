/**
 * XMONEY Mobile API Client (shared contract)
 * Use in Flutter WebView bridge, React Native, or Capacitor shell.
 */
export function createXmoneyClient(config = {}) {
  const API_BASE = (config.apiBaseUrl || '').replace(/\/$/, '');
  const storage = config.storage || {
    get: (k) => (typeof localStorage !== 'undefined' ? localStorage.getItem(k) : null),
    set: (k, v) => { if (typeof localStorage !== 'undefined') localStorage.setItem(k, v); },
    remove: (k) => { if (typeof localStorage !== 'undefined') localStorage.removeItem(k); },
  };

  const KEYS = {
    access: 'xm_access_token',
    refresh: 'xm_refresh_token',
    device: 'xm_device_uuid',
  };

  function deviceId() {
    let id = storage.get(KEYS.device);
    if (!id) {
      id = (globalThis.crypto?.randomUUID?.() || `mob-${Date.now()}`);
      storage.set(KEYS.device, id);
    }
    return id;
  }

  async function api(path, options = {}) {
    const headers = {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      'X-Device-Id': deviceId(),
      ...(options.headers || {}),
    };
    const token = storage.get(KEYS.access);
    if (token) headers.Authorization = `Bearer ${token}`;

    const res = await fetch(`${API_BASE}${path}`, {
      ...options,
      headers,
      body: options.body ? JSON.stringify(options.body) : undefined,
    });
    return { ...(await res.json().catch(() => ({ success: false }))), status: res.status, ok: res.ok };
  }

  return {
    api,
    login: (email, password) => api('/v1/auth/login', { method: 'POST', body: { email, password } }),
    register: (payload) => api('/v1/auth/register', { method: 'POST', body: payload }),
    me: () => api('/v1/me'),
    quoteTransfer: (body) => api('/v1/transfers/quote', { method: 'POST', body }),
    createTransfer: (body) => api('/v1/transfers', { method: 'POST', body }),
    confirmTransfer: (uuid, body) => api(`/v1/transfers/${uuid}/confirm`, { method: 'POST', body }),
    beneficiaries: () => api('/v1/beneficiaries'),
    wallet: () => api('/v1/wallet'),
    notifications: () => api('/v1/notifications'),
    publicSettings: () => api('/v1/settings/public'),
    setSession(tokens) {
      if (tokens.access_token) storage.set(KEYS.access, tokens.access_token);
      if (tokens.refresh_token) storage.set(KEYS.refresh, tokens.refresh_token);
    },
    clearSession() {
      storage.remove(KEYS.access);
      storage.remove(KEYS.refresh);
    },
  };
}

// CommonJS fallback for Node tooling
if (typeof module !== 'undefined') module.exports = { createXmoneyClient };
