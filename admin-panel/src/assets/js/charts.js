/**
 * XMONEY Admin chart helpers
 */
const XMCharts = (() => {
  function barChart(container, labels, values, color = 'var(--xm-teal)') {
    if (!container) return;
    const max = Math.max(...values, 1);
    container.innerHTML = `<div class="xm-chart-bars">${labels.map((label, i) => {
      const h = Math.round((values[i] / max) * 100);
      return `<div class="xm-chart-bar-wrap" title="${label}: ${values[i]}">
        <div class="xm-chart-bar" style="height:${h}%;background:${color}"></div>
        <span class="xm-chart-label">${label}</span>
      </div>`;
    }).join('')}</div>`;
  }
  return { barChart };
})();
