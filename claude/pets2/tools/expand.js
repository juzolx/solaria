// Pets 2: expands spec.tsv into one call's item_descriptions (2 each, then 3rd copies to fill 64)
// and writes raw/call<N>_map.txt (candidate index -> id). usage: node expand.js <call>
// spec.tsv columns: call | id | s (stands) / f (floats) / e (egg) | description
const fs = require('fs'), path = require('path');
const dir = path.join(__dirname, '..');
const call = process.argv[2];
const rows = fs.readFileSync(path.join(dir, 'spec.tsv'), 'utf8').trim().split(/\r?\n/).map(l => l.split('|')).filter(r => r[0] === call);
const items = [], ids = [];
for (const r of rows) for (let k = 0; k < 2; k++) { items.push(r[3]); ids.push(r[1]); }
for (let i = 0; items.length < 64 && i < rows.length; i++) { items.push(rows[i][3]); ids.push(rows[i][1]); }
fs.mkdirSync(path.join(dir, 'raw'), { recursive: true });
fs.writeFileSync(path.join(dir, 'raw', `call${call}_map.txt`), ids.map((d, i) => `${i}\t${d}`).join('\n') + '\n');
console.log(JSON.stringify(items));
