#!/usr/bin/env node
// DARKSTAR scenario CLI (in-process scenario runner, D-09: no sockets). No dependencies.
//   node tools/automation/darkstar_auto.js validate <file|id>
//   node tools/automation/darkstar_auto.js run <id> [--windowed] [--keep] [--godot=<exe>] [--timeout=<s>] [--out=<dir>] [-- <game args>]
//     Anything after a bare "--" is passed to the game after the scenario's own args (dev builds read e.g.
//     --aether-cine-scale=8). Only --name / --name=value tokens; the runner's own (--scenario, --out, --no-save...) are refused.
//   node tools/automation/darkstar_auto.js run|run-all --exe=<exported game exe> [--windowed] [--timeout=<s>]
//     Runs an EXPORTED build directly (no --path). Output goes to <exe dir>/reports/automation/<id>-<stamp>
//     (the game confines --out to user:// or reports/). Against a QA build, a scenario that uses dev-only
//     steps must come back refused (exit 3): reported as "refused (QA profile)", which run-all does not count as a failure.
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
const TOP_KEYS = ["format", "version", "id", "args", "fixtures", "timeout_frames", "steps", "profile", "fail_on_errors", "allow_errors"];
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
  if (sc.fail_on_errors !== undefined && typeof sc.fail_on_errors !== "boolean") errs.push("fail_on_errors must be a bool");
  if (sc.allow_errors !== undefined && !typeOk(sc.allow_errors, "string_array")) errs.push("allow_errors must be an array of strings");
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

/** Names of the dev-only catalog steps a scenario uses (the QA profile refuses these). */
function devStepsUsed(sc) {
  const steps = loadCatalog().steps;
  return [...new Set((sc.steps || []).map((s) => s.do).filter((n) => steps[n] && steps[n].dev))];
}

/**
 * @param {string} arg file path or scenario id
 * @returns {{file: string, scenario: any}}
 */
function loadScenario(arg) {
  const file = fs.existsSync(arg) ? path.resolve(arg) : path.join(scenarioDir, `${arg}.scenario.json`);
  return { file, scenario: JSON.parse(fs.readFileSync(file, "utf8")) };
}

/** Game args the CLI owns; a pass-through arg may not override them. */
const RESERVED_GAME_ARGS = ["--scenario", "--record", "--automation-caps", "--out", "--no-save", "--path", "--headless", "--fixed-fps"];

/**
 * Extra args for the game: everything after a bare `--` on the CLI. Each must be a `--name` or
 * `--name=value` token and may not be one the runner sets itself.
 * @param {string[]} extra
 * @returns {{args: string[], error: string}}
 */
function checkExtraArgs(extra) {
  for (const a of extra) {
    if (!/^--[A-Za-z0-9][A-Za-z0-9_-]*(=.*)?$/.test(a)) return { args: [], error: `extra game arg '${a}' must look like --name or --name=value` };
    if (RESERVED_GAME_ARGS.includes(a.split("=")[0])) return { args: [], error: `extra game arg '${a}' is set by the runner and cannot be passed` };
  }
  return { args: extra, error: "" };
}

/**
 * The command-line tail handed to the game, after the engine's `--`.
 * @param {string} scenarioId @param {string} out @param {string[]} scenarioArgs @param {string[]} extra
 */
function gameArgs(scenarioId, out, scenarioArgs, extra) {
  return ["--fixed-fps", "60", "--", `--scenario=${scenarioId}`, "--no-save", `--out=${out}`, ...scenarioArgs, ...extra];
}

/** @param {string[]} argv @returns {any} `_` = positionals, `extra` = tokens after a bare `--` */
function parseFlags(argv) {
  const flags = { _: [], extra: [] };
  const cut = argv.indexOf("--");
  if (cut >= 0) { flags.extra = argv.slice(cut + 1); argv = argv.slice(0, cut); }
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
  if (!id) { console.error("usage: run <id> [--windowed] [--keep] [--godot=<exe>] [--timeout=<s>] [--out=<dir>] [-- <game args>]"); return 2; }
  return (await runScenario(id, flags, false)).code;
}

/**
 * Runs one scenario. quiet = print only failures (used by run-all).
 * @returns {Promise<{code: number, frames: number, outcome: string}>}
 */
async function runScenario(id, flags, quiet) {
  const { scenario } = loadScenario(id);
  const errs = validate(scenario);
  if (errs.length) { console.error(errs.join("\n")); return { code: 2, frames: 0, outcome: "invalid" }; }
  const exe = typeof flags.exe === "string" ? path.resolve(flags.exe) : "";
  if (flags.exe && !exe) { console.error("--exe needs a path"); return { code: 2, frames: 0, outcome: "invalid" }; }
  if (exe && !fs.existsSync(exe)) { console.error(`exported exe not found: ${exe}`); return { code: 2, frames: 0, outcome: "invalid" }; }
  const godot = exe || findGodot(flags);
  const outBase = exe ? path.join(path.dirname(exe), "reports", "automation") : path.join(root, "reports", "automation");
  const out = path.resolve(typeof flags.out === "string" ? flags.out : path.join(outBase, `${scenario.id}-${stamp()}`)).replace(/\\/g, "/");
  fs.mkdirSync(out, { recursive: true });
  // An exported build resolves res://reports to <exe dir>/reports (verified); an absolute --out is refused there.
  let gameOut = out;
  if (exe) {
    const rel = path.relative(path.join(path.dirname(exe), "reports"), out).split(path.sep).join("/");
    if (rel.startsWith("..") || path.isAbsolute(rel)) { console.error(`--out must be under ${path.join(path.dirname(exe), "reports")} for an exported exe`); return { code: 2, frames: 0, outcome: "invalid" }; }
    gameOut = `res://reports/${rel}`;
  }
  const extra = checkExtraArgs(flags.extra || []);
  if (extra.error) { console.error(extra.error); return { code: 2, frames: 0, outcome: "invalid" }; }
  const game = gameArgs(scenario.id, gameOut, scenario.args || [], extra.args);
  const args = exe ? [...(flags.windowed ? [] : ["--headless"]), ...game]
    : ["--path", root, ...(flags.windowed ? [] : ["--headless"]), ...game];
  const log = fs.createWriteStream(path.join(out, "console.log"));
  const child = spawn(godot, args, { cwd: exe ? path.dirname(exe) : root, stdio: ["ignore", "pipe", "pipe"] });
  child.stdout.pipe(log, { end: false });
  child.stderr.pipe(log, { end: false });
  const limit = (Number(flags.timeout) || 120) * 1000;
  let watchdog = false;
  const timer = setTimeout(() => { watchdog = true; child.kill(); }, limit);
  const code = await new Promise((resolve) => child.on("close", (c) => resolve(c === null ? -1 : c)));
  clearTimeout(timer);
  log.end();
  if (watchdog) { console.error(`watchdog: killed after ${limit / 1000}s (output in ${out})`); return { code: 4, frames: 0, outcome: "watchdog" }; }
  const resultPath = path.join(out, "result.json");
  if (!fs.existsSync(resultPath)) { console.error(`no result.json produced (exit ${code}); see ${path.join(out, "console.log")}`); return { code: 5, frames: 0, outcome: "crash" }; }
  const result = JSON.parse(fs.readFileSync(resultPath, "utf8"));
  // A QA build must refuse a scenario that uses dev steps: that is the expected outcome, not a failure.
  const dev = devStepsUsed(scenario);
  const expectedRefusal = Boolean(exe) && code === 3 && result.outcome === "refused" && result.profile === "qa"
    && (result.build || {}).profile === "qa" && dev.length > 0;
  if (expectedRefusal) {
    console.log(`  refused (QA profile): dev steps ${dev.join(", ")} (expected; exit 3)`);
    fs.rmSync(out, { recursive: true, force: true });
    return { code, frames: result.frames, outcome: "refused", expectedRefusal: true };
  }
  if (!quiet || code !== 0) console.log(summarise(out, result, code));
  const shots = (result.screenshots || []).some((x) => x.path);
  if (code === 0 && !flags.keep && !shots && typeof flags.out !== "string") {
    fs.rmSync(out, { recursive: true, force: true });
    if (!quiet) console.log("  output: removed (clean pass, no screenshots; use --keep to retain)");
  } else if (!quiet || code !== 0) {
    console.log(`  output: ${out}`);
  }
  return { code, frames: result.frames, outcome: result.outcome };
}

/** @param {any} flags */
async function runAll(flags) {
  const ids = fs.readdirSync(scenarioDir).filter((f) => f.endsWith(".scenario.json")).map((f) => f.replace(".scenario.json", "")).sort()
    .filter((id) => typeof flags.only !== "string" || id.includes(flags.only));
  if (!ids.length) { console.error("no scenarios match"); return 2; }
  const rows = [];
  for (const id of ids) {
    const r = await runScenario(id, { ...flags, out: undefined }, true);
    rows.push({ id, ...r });
  }
  const w = Math.max(...rows.map((r) => r.id.length));
  console.log("\n" + "scenario".padEnd(w + 1) + " outcome   exit  frames");
  for (const r of rows) console.log(`${r.id.padEnd(w + 1)} ${String(r.outcome).padEnd(9)} ${String(r.code).padEnd(5)} ${r.frames}${r.expectedRefusal ? "  (expected: QA profile)" : ""}`);
  const refused = rows.filter((r) => r.expectedRefusal).length;
  const bad = rows.filter((r) => r.code !== 0 && !r.expectedRefusal).length;
  const passed = rows.filter((r) => r.code === 0).length;
  const tail = refused ? ` (${passed} passed, ${refused} refused by the QA profile as expected)` : "";
  console.log(bad ? `${bad} of ${rows.length} FAILED${tail}` : (refused ? `no failures${tail}` : `all ${rows.length} passed`));
  return bad ? 1 : 0;
}

/** @param {any} flags */
async function caps(flags) {
  const godot = findGodot(flags);
  const out = path.join(root, "reports", "automation", `caps-${stamp()}`).replace(/\\/g, "/");
  fs.mkdirSync(out, { recursive: true });
  const args = ["--path", root, ...(flags.windowed ? [] : ["--headless"]), "--", "--automation-caps", "--no-save", `--out=${out}`];
  const code = await new Promise((resolve) => {
    const c = spawn(godot, args, { cwd: root, stdio: "ignore" });
    const t = setTimeout(() => c.kill(), (Number(flags.timeout) || 60) * 1000);
    c.on("close", (x) => { clearTimeout(t); resolve(x === null ? -1 : x); });
  });
  const file = path.join(out, "caps.json");
  if (!fs.existsSync(file)) { console.error(`no caps.json produced (exit ${code}); is this a build without automation?`); return 5; }
  const c = JSON.parse(fs.readFileSync(file, "utf8"));
  console.log(`profile: ${c.profile}  protocol: ${c.protocol}  godot: ${c.build.godot}  game: ${c.build.game_version}`);
  console.log(`steps (${c.steps.length}): ${c.steps.map((s) => s.name + (s.dev ? "*" : "")).join(" ")}   (* = dev only)`);
  console.log(`comparators: ${c.comparators.join(" ")}   screenshot targets: ${c.screenshot_targets.join(" ")}`);
  for (const [route, pr] of Object.entries(c.probes)) {
    console.log(`probe ${route}:`);
    console.log(`  ids: ${pr.ids.join(" ")}`);
    console.log(`  events: ${pr.events.join(" ")}`);
    console.log(`  dev ops: ${pr.dev_ops.join(" ")}`);
  }
  console.log(`fixtures: ${c.fixtures.join(" ")}`);
  fs.rmSync(out, { recursive: true, force: true });
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
    if (cmd === "run-all") return await runAll(flags);
    if (cmd === "caps") return await caps(flags);
  } catch (e) {
    console.error(String(e.message || e));
    return 2;
  }
  console.error("commands: validate <file|id> | caps [--windowed] | run-all [--only=<substr>] [--exe=<exported exe>] | run <id> [--windowed] [--keep] [--godot=<exe>] [--timeout=<s>] [--out=<dir>] [--exe=<exported exe>] [-- <game args>]");
  return 2;
}

if (require.main === module) main().then((code) => process.exit(code));
module.exports = { parseFlags, checkExtraArgs, gameArgs, validate };
