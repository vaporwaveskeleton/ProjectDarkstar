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
