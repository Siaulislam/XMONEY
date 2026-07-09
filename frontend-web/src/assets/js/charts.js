/**
 * XMONEY lightweight chart helpers (no external dependencies)
 */
const XMCharts = (() => {
  function barChart(container, labels, values, options = {}) {
    if (!container) return;
    const max = Math.max(...values, 1);
    const color = options.color || 'var(--xm-teal)';
    container.innerHTML = `<div class="xm-chart-bars">${labels.map((label, i) => {
      const h = Math.round((values[i] / max) * 100);
      return `<div class="xm-chart-bar-wrap" title="${label}: ${values[i]}">
        <div class="xm-chart-bar" style="height:${h}%;background:${color}"></div>
        <span class="xm-chart-label">${label}</span>
      </div>`;
    }).join('')}</div>`;
  }

  function statGrid(container, items) {
    if (!container) return;
    container.innerHTML = items.map((item) =>
      `<div class="xm-stat"><div class="label">${item.label}</div><div class="value">${item.value}</div></div>`
    ).join('');
  }

  return { barChart, statGrid };
})();
