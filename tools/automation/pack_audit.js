#!/usr/bin/env node
// Audits a Godot 4 .pck (from `--export-pack`) against the DARKSTAR release / QA content rules.
//   node tools/automation/pack_audit.js <file.pck> --profile release|qa
// Zero dependencies. Exit 0 = PASS, 1 = FAIL, 2 = usage/parse error.
// Path normalisation: ".remap" suffixes are stripped (scripts/scenes are stored as foo.gd.remap);
// ".import" files are dropped (importer metadata, the imported .ctex lives under .godot/).
"use strict";
const fs = require("fs");

/** @param {Buffer} buf @returns {string[]} */
function listPaths(buf) {
  if (buf.toString("latin1", 0, 4) !== "GDPC") throw new Error("not a Godot pack (no GDPC magic)");
  const fmt = buf.readUInt32LE(4);
  if (fmt < 2) throw new Error(`unsupported pack format ${fmt}`);
  let dirOffset;
  let p;
  if (fmt >= 3) {
    const flags = buf.readUInt32LE(20);
    if (flags & 1) throw new Error("pack directory is encrypted");
    dirOffset = Number(buf.readBigUInt64LE(32));
  } else {
    throw new Error("only pack format 3+ supported");
  }
  p = dirOffset;
  const count = buf.readUInt32LE(p); p += 4;
  const paths = [];
  for (let i = 0; i < count; i++) {
    const len = buf.readUInt32LE(p); p += 4;
    const raw = buf.toString("utf8", p, p + len).replace(/\0+$/, "");
    p += len;
    p += 8 + 8 + 16 + 4; // offset, size, md5, flags
    paths.push(raw);
  }
  return paths;
}

/** @param {string[]} raw @returns {string[]} */
function normalise(raw) {
  const out = new Set();
  for (let p of raw) {
    p = p.replace(/^res:\/\//, "");
    if (p.endsWith(".import")) continue;
    if (p.endsWith(".remap")) p = p.slice(0, -".remap".length);
    out.add(p);
  }
  return [...out].sort();
}

const RELEASE_BANNED = [
  [/^core\/automation\//, "core/automation/"],
  [/^features\/[^/]+\/automation\//, "features/*/automation/"],
  [/(^|\/)tests\//, "a tests/ folder"],
  [/^scenes\/dev\//, "scenes/dev/ (dev routes)"],
  [/^data\/routes\/dev_/, "data/routes/dev_* (dev route tables)"],
  [/^addons\/gdUnit4/, "addons/gdUnit4"],
  [/^addons\/godot_ai/, "addons/godot_ai"],
];
const QA_BANNED = [
  [/^addons\/gdUnit4/, "addons/gdUnit4"],
  [/^addons\/godot_ai/, "addons/godot_ai"],
  [/(^|\/)tests\/test_[^/]*\.gd/, "test code (tests/test_*.gd)"],
  [/^core\/automation\/tests\//, "core/automation/tests/"],
  [/^(core\/[^/]+|features\/[^/]+|scenes)\/tests\//, "a feature/core/scenes tests/ folder"],
  [/^tests\/support\//, "tests/support/"],
];

/** @param {string[]} files @param {string} profile @returns {{ok: boolean, line: string}[]} */
function audit(files, profile) {
  const res = [];
  const banned = profile === "release" ? RELEASE_BANNED : QA_BANNED;
  for (const [re, label] of banned) {
    const hit = files.filter((f) => re.test(f));
    res.push({ ok: hit.length === 0, line: `no ${label}${hit.length ? ` (found ${hit.length}: ${hit.slice(0, 3).join(", ")})` : ""}` });
  }
  if (profile === "release") {
    for (const [re, label] of [[/^tests\/scenarios/, "tests/scenarios"], [/^tests\/fixtures/, "tests/fixtures"]]) {
      const hit = files.filter((f) => re.test(f));
      res.push({ ok: hit.length === 0, line: `no ${label}${hit.length ? ` (found ${hit.length})` : ""}` });
    }
    const data = files.filter((f) => f.startsWith("data/") && f.endsWith(".tres")).length;
    res.push({ ok: data > 0, line: `loose data/*.tres shipped (${data})` });
  } else {
    for (const need of ["core/automation/scenario_runner.gd", "core/automation/step_catalog.json", "tests/fixtures/saves/approved.json"]) {
      res.push({ ok: files.includes(need), line: `contains ${need}` });
    }
    res.push({ ok: files.some((f) => /^tests\/scenarios\/[^/]+\.scenario\.json$/.test(f)), line: "contains tests/scenarios/*.scenario.json" });
  }
  return res;
}

function main() {
  const argv = process.argv.slice(2);
  const file = argv.find((a) => !a.startsWith("--"));
  const profile = (argv.find((a) => a.startsWith("--profile=")) || "").slice(10) || argv[argv.indexOf("--profile") + 1];
  if (!file || !["release", "qa"].includes(profile)) {
    console.error("usage: pack_audit.js <file.pck> --profile release|qa");
    return 2;
  }
  let raw;
  try { raw = listPaths(fs.readFileSync(file)); } catch (e) { console.error(String(e.message)); return 2; }
  const files = normalise(raw);
  console.log(`${file}: ${raw.length} entries, ${files.length} after normalising (.remap stripped, .import dropped)`);
  const res = audit(files, profile);
  for (const r of res) console.log(`${r.ok ? "PASS" : "FAIL"}  ${r.line}`);
  const ok = res.every((r) => r.ok);
  console.log(ok ? `RESULT: PASS (${profile})` : `RESULT: FAIL (${profile})`);
  return ok ? 0 : 1;
}
process.exit(main());
