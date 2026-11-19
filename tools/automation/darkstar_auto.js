#!/usr/bin/env node
// DARKSTAR scenario CLI (in-process scenario runner, D-09: no sockets). No dependencies.
//   node tools/automation/darkstar_auto.js validate <file|id>
//   node tools/automation/darkstar_auto.js run <id> [--windowed] [--keep] [--godot=<exe>] [--timeout=<s>] [--out=<dir>]
// Steps marked "dev": true in the catalog are valid here; the game refuses them in the QA profile.
// Step names and argument shapes come from core/automation/step_catalog.json (shared with the
// GDScript validator). Exit codes: game's own (0 pass, 1 fail/timeout, 2 invalid, 3 refused),
// 4 watchdog, 5 no result.json (crash).
"use strict";
const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");

const root = path.resolve(__dirname, "..", "..");
const catalogPath = path.join(root, "core", "automation", "step_catalog.json");
const scenarioDir = path.join(root, "tests", "scenarios");
const NAME_RE = /^[a-z0-9_]+$/;
const COMPARATORS = ["eq", "ne", "lt", "lte", "gt", "gte", "in"];
const TOP_KEYS = ["format", "version", "id", "args", "fixtures", "timeout_frames", "steps", "profile"];
const MAX_STEPS = 2000; // engineering-only limits, mirror scenario_schema.gd
const MAX_TIMEOUT_FRAMES = 216000;
const MAX_SCREENSHOTS = 100;

/** @typedef {{args?: Object<string,string>, optional?: Object<string,string>, comment?: string}} StepDef */
/** @typedef {{version: number, steps: Object<string, StepDef>}} Catalog */

/** @returns {Catalog} */
function loadCatalog() {
  return JSON.parse(fs.readFileSync(catalogPath, "utf8"));
}

/**
 * @param {unknown} v
 * @param {string} type
 * @returns {boolean}
 */
function typeOk(v, type) {
  const scalar = (x) => ["string", "number", "boolean"].includes(typeof x);
  switch (type) {
    case "string": return typeof v === "string";
    case "int": return Number.isInteger(v);
    case "number": return typeof v === "number" && Number.isFinite(v);
    case "bool": return typeof v === "boolean";
    case "string_array": return Array.isArray(v) && v.every((e) => typeof e === "string");
    case "scalar": return scalar(v);
    case "array": return Array.isArray(v) && v.every(scalar);
    default: return false;
  }
}

/**
 * Structure-only validation (the game re-validates fully, including actions and keycodes).
 * @param {any} sc
 * @returns {string[]}
 */
function validate(sc) {
  const errs = [];
  const steps = loadCatalog().steps;
  if (typeof sc !== "object" || sc === null || Array.isArray(sc)) return ["scenario must be an object"];
  for (const k of Object.keys(sc)) if (!TOP_KEYS.includes(k)) errs.push(`unknown top-level key '${k}'`);
  if (sc.format !== "darkstar.scenario") errs.push("format must be 'darkstar.scenario'");
  if (sc.version !== 1) errs.push("version must be 1");
  if (typeof sc.id !== "string" || !NAME_RE.test(sc.id)) errs.push("id must match ^[a-z0-9_]+$");
  if (sc.profile !== undefined && !["qa", "dev"].includes(sc.profile)) errs.push("profile must be 'qa' or 'dev'");
  if (sc.args !== undefined && !typeOk(sc.args, "string_array")) errs.push("args must be an array of strings");
  if (sc.fixtures !== undefined && (typeof sc.fixtures !== "object" || sc.fixtures === null || Array.isArray(sc.fixtures))) errs.push("fixtures must be an object");
  if (!Number.isInteger(sc.timeout_frames) || sc.timeout_frames < 1 || sc.timeout_frames > MAX_TIMEOUT_FRAMES) errs.push(`timeout_frames must be an int in 1..${MAX_TIMEOUT_FRAMES}`);
  if (!Array.isArray(sc.steps) || sc.steps.length === 0) { errs.push("steps must be a non-empty array"); return errs; }
  if (sc.steps.length > MAX_STEPS) { errs.push(`too many steps (${sc.steps.length} > ${MAX_STEPS})`); return errs; }
  let shots = 0;
  sc.steps.forEach((s, i) => {
    if (typeof s !== "object" || s === null) { errs.push(`step ${i}: must be an object`); return; }
    const def = steps[s.do];
    if (!def) { errs.push(`step ${i}: unknown step '${s.do}'`); return; }
    if (s.do === "screenshot") shots++;
    const req = def.args || {};
    const opt = def.optional || {};
    for (const k of Object.keys(req)) if (!(k in s)) errs.push(`step ${i} (${s.do}): missing arg '${k}'`);
    for (const k of Object.keys(s)) {
      if (k === "do") continue;
      const t = req[k] || opt[k];
      if (!t) errs.push(`step ${i} (${s.do}): unknown arg '${k}'`);
      else if (!typeOk(s[k], t)) errs.push(`step ${i} (${s.do}): arg '${k}' must be ${t}`);
    }
    const cmps = COMPARATORS.filter((c) => c in s);
    if (s.do === "wait_until" && cmps.length !== 1) errs.push(`step ${i} (wait_until): exactly one comparator of ${COMPARATORS.join(", ")} required`);
    if (s.do === "assert") {
      if ("exists" in s) { if ("prop" in s || cmps.length) errs.push(`step ${i} (assert): exists cannot combine with prop or a comparator`); }
      else if (!("prop" in s) || cmps.length !== 1) errs.push(`step ${i} (assert): needs exists, or prop plus exactly one comparator`);
    }
  });
  if (shots > MAX_SCREENSHOTS) errs.push(`too many screenshots (${shots} > ${MAX_SCREENSHOTS})`);
  return errs;
}

/**
 * @param {string} arg file path or scenario id
 * @returns {{file: string, scenario: any}}
 */
function loadScenario(arg) {
  const file = fs.existsSync(arg) ? path.resolve(arg) : path.join(scenarioDir, `${arg}.scenario.json`);
  return { file, scenario: JSON.parse(fs.readFileSync(file, "utf8")) };
}

/** @param {string[]} argv */
function parseFlags(argv) {
  const flags = { _: [] };
  for (const a of argv) {
    const m = /^--([a-z]+)(?:=(.*))?$/.exec(a);
    if (m) flags[m[1]] = m[2] === undefined ? true : m[2];
    else flags._.push(a);
  }
  return flags;
}

function findGodot(flags) {
  const exe = flags.godot || process.env.DARKSTAR_GODOT || path.join(root, "tools", "godot", "Godot_v4.7.2-stable_win64_console.exe");
  if (!fs.existsSync(exe)) {
    // A git worktree has no tools/godot; try the main checkout next to .claude/worktrees.
    const main = path.resolve(root, "..", "..", "..", "tools", "godot", path.basename(exe));
    if (!flags.godot && !process.env.DARKSTAR_GODOT && fs.existsSync(main)) return main;
    throw new Error(`Godot not found at ${exe}. Pass --godot=<exe> or set DARKSTAR_GODOT.`);
  }
  return exe;
}

function stamp() {
  const d = new Date();
  const p = (n) => String(n).padStart(2, "0");
  return `${d.getFullYear()}${p(d.getMonth() + 1)}${p(d.getDate())}-${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`;
}

function summarise(out, result, code) {
  const lines = [`outcome: ${result.outcome}  exit: ${code}  frames: ${result.frames}`];
  for (const s of result.steps || []) if (s.outcome !== "pass") lines.push(`  FAIL step ${s.i} (${s.do}): ${s.detail}`);
  for (const c of result.checkpoints || []) lines.push(`  checkpoint ${c.name} @ frame ${c.frame}`);
  for (const s of result.screenshots || []) lines.push(s.skipped ? `  screenshot ${s.name}: skipped (${s.skipped})` : `  screenshot ${s.name}: ${s.path} (${s.width}x${s.height})`);
  try {
    const log = fs.readFileSync(path.join(out, "console.log"), "utf8").split(/\r?\n/);
    const e = log.filter((l) => /^(SCRIPT )?ERROR/.test(l)).length;
    const w = log.filter((l) => /^(SCRIPT )?WARNING/.test(l)).length;
    lines.push(`  console.log: ${e} ERROR, ${w} WARNING lines`);
  } catch (_) { /* no log */ }
  return lines.join("\n");
}

/** @param {any} flags */
async function run(flags) {
  const id = flags._[1];
  if (!id) { console.error("usage: run <id> [--windowed] [--keep] [--godot=<exe>] [--timeout=<s>] [--out=<dir>]"); return 2; }
  const { scenario } = loadScenario(id);
  const errs = validate(scenario);
  if (errs.length) { console.error(errs.join("\n")); return 2; }
  const godot = findGodot(flags);
  const out = path.resolve(typeof flags.out === "string" ? flags.out : path.join(root, "reports", "automation", `${scenario.id}-${stamp()}`)).replace(/\\/g, "/");
  fs.mkdirSync(out, { recursive: true });
  const args = ["--path", root, ...(flags.windowed ? [] : ["--headless"]), "--fixed-fps", "60", "--",
    `--scenario=${scenario.id}`, "--no-save", `--out=${out}`, ...(scenario.args || [])];
  const log = fs.createWriteStream(path.join(out, "console.log"));
  const child = spawn(godot, args, { cwd: root, stdio: ["ignore", "pipe", "pipe"] });
  child.stdout.pipe(log, { end: false });
  child.stderr.pipe(log, { end: false });
  const limit = (Number(flags.timeout) || 120) * 1000;
  let watchdog = false;
  const timer = setTimeout(() => { watchdog = true; child.kill(); }, limit);
  const code = await new Promise((resolve) => child.on("close", (c) => resolve(c === null ? -1 : c)));
  clearTimeout(timer);
  log.end();
  if (watchdog) { console.error(`watchdog: killed after ${limit / 1000}s (output in ${out})`); return 4; }
  const resultPath = path.join(out, "result.json");
  if (!fs.existsSync(resultPath)) { console.error(`no result.json produced (exit ${code}); see ${path.join(out, "console.log")}`); return 5; }
  const result = JSON.parse(fs.readFileSync(resultPath, "utf8"));
  console.log(summarise(out, result, code));
  const shots = (result.screenshots || []).some((x) => x.path);
  if (code === 0 && !flags.keep && !shots && typeof flags.out !== "string") {
    fs.rmSync(out, { recursive: true, force: true });
    console.log("  output: removed (clean pass, no screenshots; use --keep to retain)");
  } else {
    console.log(`  output: ${out}`);
  }
  return code;
}

async function main() {
  const flags = parseFlags(process.argv.slice(2));
  const cmd = flags._[0];
  try {
    if (cmd === "validate" && flags._[1]) {
      const errs = validate(loadScenario(flags._[1]).scenario);
      console.log(errs.length ? errs.join("\n") : "valid");
      return errs.length ? 2 : 0;
    }
    if (cmd === "run") return await run(flags);
  } catch (e) {
    console.error(String(e.message || e));
    return 2;
  }
  console.error("commands: validate <file|id> | run <id> [--windowed] [--keep] [--godot=<exe>] [--timeout=<s>] [--out=<dir>]");
  return 2;
}

main().then((code) => process.exit(code));
