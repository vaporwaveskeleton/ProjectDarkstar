// Tests for the CLI's pure helpers. Run: node --test tools/automation
"use strict";
const test = require("node:test");
const assert = require("node:assert");
const { parseFlags, checkExtraArgs, gameArgs } = require("./darkstar_auto.js");

test("parseFlags splits extra game args after a bare --", () => {
  const f = parseFlags(["run", "a0_x", "--windowed", "--", "--aether-cine-scale=8", "--can_skip=true"]);
  assert.deepStrictEqual(f._, ["run", "a0_x"]);
  assert.strictEqual(f.windowed, true);
  assert.deepStrictEqual(f.extra, ["--aether-cine-scale=8", "--can_skip=true"]);
});

test("parseFlags without -- has no extra args", () => {
  assert.deepStrictEqual(parseFlags(["run", "a0_x"]).extra, []);
});

test("extra args keep their order, after the scenario's own", () => {
  const ok = checkExtraArgs(["--aether-cine-scale=8", "--flag"]);
  assert.strictEqual(ok.error, "");
  assert.deepStrictEqual(gameArgs("s", "/o", ["--stage=2"], ok.args),
    ["--fixed-fps", "60", "--", "--scenario=s", "--no-save", "--out=/o", "--stage=2", "--aether-cine-scale=8", "--flag"]);
});

test("no extra args leaves the command line as before", () => {
  assert.deepStrictEqual(gameArgs("s", "/o", [], []), ["--fixed-fps", "60", "--", "--scenario=s", "--no-save", "--out=/o"]);
});

test("runner-owned and malformed extra args are refused", () => {
  for (const bad of ["--scenario=other", "--out=/x", "--no-save", "--record=x", "--path", "plain", "-x", "--"]) {
    assert.notStrictEqual(checkExtraArgs([bad]).error, "", bad);
  }
});

test("buildReport writes the scenario, perf and luma tables", () => {
  const { buildReport } = require("./darkstar_auto.js");
  const md = buildReport([
    { id: "ok_one", code: 0, outcome: "pass", frames: 10, wall_s: 1.5, counts: { errors: 0, warnings: 0 },
      result: { screenshots: [{ name: "a", path: "/x/a.png" }],
        perf_windows: [{ name: "act0", frames: 9, p50_ms: 9.5, p95_ms: 12, p99_ms: 14, max_ms: 20, budget_ms: 8, p50_within_budget: false }],
        luma_windows: [{ name: "reveal", frames: 9, ok: true, violation_count: 0, violations: [], max_full_step: 0.01, max_full_step_frame: 2, max_cycles_per_s: 0, soft_steps: 0 },
          { name: "h", skipped: "headless", ok: true }] }, out: "/x" },
    { id: "bad|one", code: 1, outcome: "fail", frames: 3, result: { steps: [{ i: 2, do: "assert", outcome: "fail", detail: "x" }] } },
  ], { generated: "2026-11-19T00:00:00Z", mode: "windowed", machine: "cpu" });
  assert.match(md, /\*\*1 of 2 FAILED\*\*/);
  assert.match(md, /\| ok_one \| act0 \| 9 \| 9.5 \| 12 \| 14 \| 20 \| 8 ms: \*\*OVER\*\* \|/);
  assert.match(md, /\| ok_one \| reveal \| 9 \| ok \|/);
  assert.match(md, /skipped \(headless\)/);
  assert.match(md, /bad\\|one/);          // pipes in cells are escaped
  assert.match(md, /step 2 \(assert\): x/);
  assert.match(md, /- \*\*ok_one\*\* \(\/x\): a/);
});
