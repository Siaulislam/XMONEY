/**
 * XMONEY live exchange coversheet — XE-style converter + rate board.
 * Refreshes rates from API and updates the UI every second.
 */
const XMExchangeBoard = (() => {
  const META = {
    USD: { name: 'US Dollar', flag: '🇺🇸' },
    EUR: { name: 'Euro', flag: '🇪🇺' },
    GBP: { name: 'British Pound', flag: '🇬🇧' },
    JPY: { name: 'Japanese Yen', flag: '🇯🇵' },
    CAD: { name: 'Canadian Dollar', flag: '🇨🇦' },
    AED: { name: 'UAE Dirham', flag: '🇦🇪' },
    INR: { name: 'Indian Rupee', flag: '🇮🇳' },
    PKR: { name: 'Pakistani Rupee', flag: '🇵🇰' },
    SAR: { name: 'Saudi Riyal', flag: '🇸🇦' },
    QAR: { name: 'Qatari Riyal', flag: '🇶🇦' },
    BDT: { name: 'Bangladeshi Taka', flag: '🇧🇩' },
    PHP: { name: 'Philippine Peso', flag: '🇵🇭' },
  };

  const WATCH = ['EUR', 'GBP', 'JPY', 'CAD', 'INR', 'PKR', 'AED'];

  function meta(code) {
    return META[code] || { name: code, flag: '🌐' };
  }

  function fmtRate(n, decimals = 6) {
    const v = Number(n);
    if (!Number.isFinite(v)) return '—';
    if (v >= 100) return v.toFixed(2);
    if (v >= 1) return v.toFixed(4);
    return v.toFixed(decimals);
  }

  function sparklineSvg(values, positive) {
    if (!values.length) return '';
    const w = 72;
    const h = 28;
    const min = Math.min(...values);
    const max = Math.max(...values);
    const span = max - min || 1;
    const pts = values.map((v, i) => {
      const x = (i / Math.max(values.length - 1, 1)) * w;
      const y = h - ((v - min) / span) * (h - 4) - 2;
      return `${x.toFixed(1)},${y.toFixed(1)}`;
    });
    const color = positive ? '#059669' : '#DC2626';
    return `<svg class="xm-spark" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}" aria-hidden="true"><polyline fill="none" stroke="${color}" stroke-width="1.8" points="${pts.join(' ')}"/></svg>`;
  }

  function buildRateMap(rows) {
    const map = {};
    rows.forEach((r) => {
      const src = r.source_currency;
      const tgt = r.target_currency;
      const rate = Number(r.customer_rate);
      if (!Number.isFinite(rate)) return;
      map[`${src}/${tgt}`] = rate;
      if (rate > 0) map[`${tgt}/${src}`] = 1 / rate;
    });
    return map;
  }

  function resolveRate(map, from, to) {
    if (from === to) return 1;
    if (map[`${from}/${to}`]) return map[`${from}/${to}`];
    const hubs = ['USD', 'AED', 'EUR'];
    for (const hub of hubs) {
      if (hub === from || hub === to) continue;
      const a = map[`${from}/${hub}`];
      const b = map[`${hub}/${to}`];
      if (a && b) return a * b;
    }
    return null;
  }

  function mount(container, options = {}) {
    if (!container) return null;

    const state = {
      rows: [],
      map: {},
      base: options.baseCurrency || 'USD',
      from: options.fromCurrency || 'USD',
      to: options.toCurrency || 'INR',
      amount: 1,
      inverse: false,
      history: {},
      lastUpdated: null,
      countdown: 1,
      timers: [],
    };

    container.innerHTML = `
      <div class="xm-coversheet">
        <div class="xm-coversheet-hero">
          <div class="xm-coversheet-hero-inner">
            <div class="xm-coversheet-copy">
              <h2 class="xm-coversheet-title" data-i18n="dash.liveRatesTitle">Exchange rate &amp; currency converter</h2>
              <p class="xm-coversheet-sub" data-i18n="dash.liveRatesSub">Check live foreign currency exchange rates</p>
            </div>
            <div class="xm-coversheet-balance" id="xmCoverBalance" hidden>
              <span data-i18n="wallet.available">Available balance</span>
              <strong id="xmCoverBalVal">—</strong>
            </div>
          </div>
          <div class="xm-converter-card">
            <div class="xm-converter-row">
              <div class="xm-converter-field">
                <label for="xmFromAmount" data-i18n="dash.from">From</label>
                <div class="xm-converter-input">
                  <input type="number" id="xmFromAmount" min="0" step="any" value="1" inputmode="decimal" />
                  <select id="xmFromCur" class="xm-cur-select" aria-label="From currency"></select>
                </div>
              </div>
              <button type="button" class="xm-swap-btn" id="xmSwapBtn" title="Swap currencies" aria-label="Swap currencies">⇄</button>
              <div class="xm-converter-field">
                <label for="xmToAmount" data-i18n="dash.to">To</label>
                <div class="xm-converter-input">
                  <input type="number" id="xmToAmount" min="0" step="any" readonly tabindex="-1" aria-readonly="true" />
                  <select id="xmToCur" class="xm-cur-select" aria-label="To currency"></select>
                </div>
              </div>
            </div>
            <div class="xm-converter-rate">
              <div class="xm-converter-rate-main" id="xmRateLine">—</div>
              <div class="xm-converter-rate-meta" id="xmRateMeta">Mid-market rate</div>
            </div>
            <div class="xm-converter-actions">
              <a href="transactions.html" class="xm-btn xm-btn-outline xm-btn-converter" data-i18n="dash.trackRates">Track exchange rates</a>
              <a href="transfer.html" class="xm-btn xm-btn-primary xm-btn-converter" data-i18n="nav.send">Send money</a>
            </div>
          </div>
        </div>
        <div class="xm-rates-board">
          <div class="xm-rates-toolbar">
            <label class="xm-inverse-toggle">
              <input type="checkbox" id="xmInverseToggle" />
              <span data-i18n="dash.inverse">Inverse</span>
            </label>
            <div class="xm-rates-cols" aria-hidden="true">
              <span data-i18n="dash.amount">Amount</span>
              <span data-i18n="dash.change24h">Change (24h)</span>
              <span data-i18n="dash.chart24h">Chart (24h)</span>
            </div>
          </div>
          <div class="xm-rates-base" id="xmRatesBase"></div>
          <div class="xm-rates-list" id="xmRatesList"></div>
          <div class="xm-rates-footer">
            <button type="button" class="xm-btn xm-btn-outline xm-add-cur" id="xmRefreshRates" data-i18n="dash.refreshRates">Refresh rates</button>
            <div class="xm-rates-updated">
              <div class="xm-countdown" id="xmCountdown" aria-hidden="true"><span>1</span></div>
              <span id="xmLastUpdated" data-i18n="dash.updating">Updating…</span>
            </div>
          </div>
        </div>
      </div>`;

    const els = {
      fromAmount: container.querySelector('#xmFromAmount'),
      toAmount: container.querySelector('#xmToAmount'),
      fromCur: container.querySelector('#xmFromCur'),
      toCur: container.querySelector('#xmToCur'),
      rateLine: container.querySelector('#xmRateLine'),
      rateMeta: container.querySelector('#xmRateMeta'),
      ratesBase: container.querySelector('#xmRatesBase'),
      ratesList: container.querySelector('#xmRatesList'),
      countdown: container.querySelector('#xmCountdown span'),
      lastUpdated: container.querySelector('#xmLastUpdated'),
      inverse: container.querySelector('#xmInverseToggle'),
      coverBal: container.querySelector('#xmCoverBalance'),
      coverBalVal: container.querySelector('#xmCoverBalVal'),
    };

    function currenciesFromRows() {
      const set = new Set();
      state.rows.forEach((r) => {
        set.add(r.source_currency);
        set.add(r.target_currency);
      });
      ['USD', 'AED', 'EUR', 'GBP', 'INR', 'PKR'].forEach((c) => set.add(c));
      return [...set].sort();
    }

    function fillSelects() {
      const codes = currenciesFromRows();
      const opts = codes.map((c) => {
        const m = meta(c);
        return `<option value="${c}">${m.flag} ${c} — ${m.name}</option>`;
      }).join('');
      els.fromCur.innerHTML = opts;
      els.toCur.innerHTML = opts;
      if (codes.includes(state.from)) els.fromCur.value = state.from;
      else if (codes.length) { state.from = codes[0]; els.fromCur.value = state.from; }
      if (codes.includes(state.to)) els.toCur.value = state.to;
      else if (codes.length > 1) { state.to = codes[1]; els.toCur.value = state.to; }
    }

    function pushHistory(pair, rate) {
      if (!state.history[pair]) state.history[pair] = [];
      const arr = state.history[pair];
      arr.push(rate);
      if (arr.length > 48) arr.shift();
    }

    function changePct(pair) {
      const arr = state.history[pair];
      if (!arr || arr.length < 2) return 0;
      const first = arr[0];
      const last = arr[arr.length - 1];
      if (!first) return 0;
      return ((last - first) / first) * 100;
    }

    function updateConverter() {
      state.from = els.fromCur.value;
      state.to = els.toCur.value;
      state.amount = Math.max(0, Number(els.fromAmount.value) || 0);
      const rate = resolveRate(state.map, state.from, state.to);
      const displayRate = state.inverse && rate ? 1 / rate : rate;
      const converted = rate ? state.amount * rate : null;

      if (converted != null) {
        els.toAmount.value = fmtRate(converted, 4);
        const shown = displayRate != null ? fmtRate(displayRate) : '—';
        els.rateLine.textContent = `${fmtRate(state.amount, 2)} ${state.from} = ${fmtRate(converted)} ${state.to}`;
        els.rateMeta.textContent = `1 ${state.from} = ${shown} ${state.to} · Mid-market rate at ${new Date().toISOString().slice(11, 19)} UTC`;
      } else {
        els.toAmount.value = '';
        els.rateLine.textContent = `Rate unavailable for ${state.from} → ${state.to}`;
        els.rateMeta.textContent = 'Select another currency pair';
      }
    }

    function renderBoard() {
      const base = state.base;
      const bm = meta(base);
      els.ratesBase.innerHTML = `
        <div class="xm-rate-row xm-rate-row--base">
          <div class="xm-rate-currency"><span class="xm-flag">${bm.flag}</span><strong>${bm.name}</strong><span class="xm-code">${base}</span></div>
          <div class="xm-rate-amount">1</div>
          <div class="xm-rate-change">—</div>
          <div class="xm-rate-chart"></div>
          <a href="transfer.html" class="xm-btn xm-btn-primary xm-rate-send" data-i18n="nav.send">Send</a>
        </div>`;

      const targets = WATCH.filter((c) => c !== base && resolveRate(state.map, base, c));
      if (!targets.length) {
        state.rows.forEach((r) => {
          if (r.source_currency === base && !targets.includes(r.target_currency)) {
            targets.push(r.target_currency);
          }
        });
      }

      els.ratesList.innerHTML = targets.map((tgt) => {
        const rate = resolveRate(state.map, base, tgt);
        const pair = `${base}/${tgt}`;
        if (rate) pushHistory(pair, rate);
        const ch = changePct(pair);
        const positive = ch >= 0;
        const hist = state.history[pair] || (rate ? [rate] : []);
        const shown = state.inverse && rate ? 1 / rate : rate;
        const tm = meta(tgt);
        return `
          <div class="xm-rate-row">
            <div class="xm-rate-currency"><span class="xm-flag">${tm.flag}</span><strong>${tm.name}</strong><span class="xm-code">${tgt}</span></div>
            <div class="xm-rate-amount">${shown != null ? fmtRate(shown) : '—'}</div>
            <div class="xm-rate-change ${positive ? 'is-up' : 'is-down'}">${ch >= 0 ? '+' : ''}${ch.toFixed(2)}%</div>
            <div class="xm-rate-chart">${sparklineSvg(hist, positive)}</div>
            <a href="transfer.html" class="xm-btn xm-btn-primary xm-rate-send" data-i18n="nav.send">Send</a>
          </div>`;
      }).join('') || `<div class="xm-empty">No live rates loaded yet.</div>`;
    }

    function updateFooter() {
      els.countdown.textContent = String(state.countdown);
      if (state.lastUpdated) {
        const ts = state.lastUpdated.toLocaleString(undefined, {
          month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit', timeZone: 'UTC', timeZoneName: 'short',
        });
        els.lastUpdated.textContent = `Last updated ${ts}`;
      }
    }

    async function fetchRates() {
      try {
        const res = await XMONEY.api('/v1/rates');
        if (!res.success || !Array.isArray(res.data) || !res.data.length) return;
        state.rows = res.data;
        state.map = buildRateMap(res.data);
        const bases = ['USD', 'AED'];
        state.base = bases.find((b) => state.rows.some((r) => r.source_currency === b)) || state.rows[0].source_currency;
        state.lastUpdated = new Date();
        state.countdown = 1;
        fillSelects();
        updateConverter();
        renderBoard();
        updateFooter();
      } catch (_) { /* keep last good state */ }
    }

    function tick() {
      state.countdown = Math.max(0, state.countdown - 1);
      if (state.countdown === 0) fetchRates();
      updateConverter();
      updateFooter();
    }

    els.fromAmount.addEventListener('input', updateConverter);
    els.fromCur.addEventListener('change', updateConverter);
    els.toCur.addEventListener('change', updateConverter);
    els.inverse.addEventListener('change', () => {
      state.inverse = els.inverse.checked;
      renderBoard();
      updateConverter();
    });
    container.querySelector('#xmSwapBtn').addEventListener('click', () => {
      const f = els.fromCur.value;
      els.fromCur.value = els.toCur.value;
      els.toCur.value = f;
      updateConverter();
      renderBoard();
    });
    container.querySelector('#xmRefreshRates').addEventListener('click', () => {
      state.countdown = 1;
      fetchRates();
    });

    state.timers.push(setInterval(tick, 1000));
    fetchRates();

    return {
      setBalance(amount, currency) {
        if (!amount && amount !== 0) return;
        els.coverBal.hidden = false;
        els.coverBalVal.textContent = typeof XMONEY !== 'undefined' && XMONEY.formatMoney
          ? XMONEY.formatMoney(amount, currency)
          : `${amount} ${currency || ''}`.trim();
      },
      destroy() {
        state.timers.forEach((t) => clearInterval(t));
      },
    };
  }

  return { mount, meta };
})();
