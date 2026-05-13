#!/usr/bin/env bash
# Validate every v1/*.json against the schema and the cross-field invariant.
# Requires: node (>= 18), npx. No global install needed.
set -euo pipefail

cd "$(dirname "$0")/.."

SCHEMA="schema/app_config.schema.json"
FILES=(v1/*.json)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "no config files under v1/" >&2
  exit 1
fi

echo "==> Schema validation"
npx --yes ajv-cli@5 validate \
  --spec=draft2020 \
  -s "$SCHEMA" \
  -d "v1/*.json" \
  --strict=true

echo "==> Invariant: min_version <= recommended_version"
node - <<'JS'
const fs = require('node:fs');
const path = require('node:path');

function cmpSemver(a, b) {
  const parse = (v) => v.split(/[-+]/, 1)[0].split('.').map(Number);
  const [a1, a2, a3] = parse(a);
  const [b1, b2, b3] = parse(b);
  if (a1 !== b1) return a1 - b1;
  if (a2 !== b2) return a2 - b2;
  return a3 - b3;
}

const files = fs.readdirSync('v1').filter((f) => f.endsWith('.json'));
let failed = 0;
for (const f of files) {
  const cfg = JSON.parse(fs.readFileSync(path.join('v1', f), 'utf8'));
  if (0 < cmpSemver(cfg.min_version, cfg.recommended_version)) {
    console.error(`FAIL ${f}: min_version ${cfg.min_version} > recommended_version ${cfg.recommended_version}`);
    failed++;
  } else {
    console.log(`ok   ${f}: ${cfg.min_version} <= ${cfg.recommended_version}`);
  }
}
process.exit(failed === 0 ? 0 : 1);
JS

echo "==> All checks passed"
