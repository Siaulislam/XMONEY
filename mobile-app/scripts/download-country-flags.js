/* eslint-disable */
const fs = require('fs');
const path = require('path');
const https = require('https');

const dataPath = path.join(__dirname, '..', 'assets', 'data', 'country_currencies.json');
const flagsDir = path.join(__dirname, '..', 'assets', 'flags');

function get(url) {
  return new Promise((resolve, reject) => {
    https
      .get(url, { headers: { 'User-Agent': 'XMONEY-flag-sync' } }, (res) => {
        if (res.statusCode === 301 || res.statusCode === 302) {
          get(res.headers.location).then(resolve).catch(reject);
          return;
        }
        const chunks = [];
        res.on('data', (c) => chunks.push(c));
        res.on('end', () => {
          if (res.statusCode !== 200) {
            reject(new Error(`HTTP ${res.statusCode} for ${url}`));
            return;
          }
          resolve(Buffer.concat(chunks));
        });
      })
      .on('error', reject);
  });
}

async function main() {
  const json = JSON.parse(fs.readFileSync(dataPath, 'utf8'));
  const codes = [...new Set(json.entries.map((e) => e.countryCode.toUpperCase()))].sort();
  fs.mkdirSync(flagsDir, { recursive: true });

  let ok = 0;
  let skipped = 0;
  for (const cc of codes) {
    const dest = path.join(flagsDir, `${cc}.png`);
    if (fs.existsSync(dest) && fs.statSync(dest).size > 200) {
      skipped++;
      continue;
    }
    const url = `https://flagcdn.com/w80/${cc.toLowerCase()}.png`;
    try {
      const buf = await get(url);
      fs.writeFileSync(dest, buf);
      ok++;
      process.stdout.write('.');
    } catch (err) {
      console.warn(`\nSkip ${cc}: ${err.message}`);
    }
  }
  console.log(`\nFlags ready — downloaded ${ok}, skipped ${skipped}, total ${codes.length}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
