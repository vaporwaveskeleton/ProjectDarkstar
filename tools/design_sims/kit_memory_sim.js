#!/usr/bin/env node
// Kit-memory threshold simulation (design proposal check, not game code).
// Deterministic: seeded mulberry32. Usage:
//   node tools/design_sims/kit_memory_sim.js [--chronicles=400] [--runs=50] [--seed=1] [--reserve]
// Models ZONES-001 §3 (kit pool, Seam slots), §2.2 (biome iterations), §4.4 (variety rules)
// and LOOP-001 §9.5 (runs per Iteration, won/died mix). A "visit" = the kit is a Seam's
// primary kit and the player enters that Seam. Every modelling assumption is marked ASSUME.

'use strict';

const args = Object.fromEntries(process.argv.slice(2).map(a => {
  const [k, v] = a.replace(/^--/, '').split('=');
  return [k, v === undefined ? true : v];
}));
const CHRONICLES = Number(args.chronicles || 400);
const RUNS = Number(args.runs || 50);
const SEED = Number(args.seed || 1);
const RESERVE = Boolean(args.reserve); // proposal §3.2.3: 4 kits held until Act 2

function mulberry32(a) {
  return function () {
    a |= 0; a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// ZONES-001 §3 / §3.7: id, biome, Seam slots (5 = Seam-5 gate kit; §3.7 lists five: OB-05, LT-02, GR-02, DO-05, BK-01).
const KITS = [
  ['PM-01', 'PM', [1]], ['PM-02', 'PM', [1, 2]], ['PM-03', 'PM', [1, 2]], ['PM-04', 'PM', [2]],
  ['PM-05', 'PM', [2]], ['PM-06', 'PM', [2, 3]],
  ['OB-01', 'OB', [1]], ['OB-02', 'OB', [2]], ['OB-03', 'OB', [2, 3]], ['OB-04', 'OB', [1, 2]],
  ['OB-05', 'OB', [2, 3, 5]], ['OB-06', 'OB', [2, 4]],
  ['LT-01', 'LT', [2, 3, 4]], ['LT-02', 'LT', [3, 5]], ['LT-03', 'LT', [3]], ['LT-04', 'LT', [3, 4]],
  ['LT-05', 'LT', [4]], ['LT-06', 'LT', [3, 4]],
  ['GR-01', 'GR', [2]], ['GR-02', 'GR', [3, 5]], ['GR-03', 'GR', [2, 3]], ['GR-04', 'GR', [3]],
  ['GR-05', 'GR', [4]],
  ['DO-01', 'DO', [2, 3]], ['DO-02', 'DO', [3]], ['DO-03', 'DO', [3]], ['DO-04', 'DO', [3, 4]],
  ['DO-05', 'DO', [4, 5]],
  ['BK-01', 'BK', [3, 4, 5]], ['BK-02', 'BK', [3, 4]], ['BK-03', 'BK', [4]], ['BK-04', 'BK', [3, 4]],
].map(([id, biome, slots]) => ({ id, biome, slots }));

// ZONES-001 §2.2: first Iteration each biome appears in.
const BIOME_FROM_ITER = { PM: 1, OB: 1, LT: 2, GR: 3, DO: 3, BK: 4 };

// ASSUME (proposal §3.2.3): one reserve kit from each biome with >= 5 kits, held until Act 2.
// FINDING: OB-06 is the only Seam-4 kit in Iteration 1, so it cannot be held back. Chosen so
// every Seam slot keeps an alternative: PM-05, OB-02, LT-04, GR-03.
const RESERVE_KITS = new Set(['PM-05', 'OB-02', 'LT-04', 'GR-03']);

// LOOP-001 §9.5 table: Iteration -> [runs, wins, act]. ASSUME Iterations 7+ repeat Iteration 6
// (Act 4 is out of the model; the sim only needs enough runs to reach run 50).
const ITERS = [[5, 2, 1], [6, 3, 2], [6, 4, 2], [6, 4, 2], [7, 5, 3], [7, 5, 3]];
function iterPlan(i) { return ITERS[Math.min(i, ITERS.length - 1)]; }

function pick(rng, arr) { return arr[Math.floor(rng() * arr.length)]; }
function shuffle(rng, arr) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(rng() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; }
  return a;
}

// Assemble a 5-Seam run under §4.4: no repeated kit; <= 2 Seams per biome; Act 1 exactly 2
// biomes (Pale Marches always in, §2.2); Act 2+ 3-4 biomes; same kit never at the same
// ordinal as last run. Rejection sampling; returns array of 5 kits or null.
function assembleRun(rng, iter, act, prevOrdinals) {
  const avail = KITS.filter(k => BIOME_FROM_ITER[k.biome] <= iter + 1 &&
    !(RESERVE && act < 2 && RESERVE_KITS.has(k.id)));
  const biomes = [...new Set(avail.map(k => k.biome))];
  for (let attempt = 0; attempt < 200; attempt++) {
    let chosen;
    if (act === 1) {
      chosen = ['PM', pick(rng, biomes.filter(b => b !== 'PM'))];
    } else {
      const n = Math.min(biomes.length, rng() < 0.5 ? 3 : 4);
      chosen = shuffle(rng, biomes).slice(0, n);
    }
    // FINDING: §4.4 rule 3 (<= 2 Seams per biome, Act 1 = exactly 2 biomes) cannot cover 5 Seams.
    // ASSUME: the Seam 5 gate kit is exempt from the biome cap and biome count (it is drawn
    // from the gate list regardless of the run's biomes).
    const used = new Set(); const perBiome = {}; const run = [];
    let ok = true; let relaxed = false;
    for (let s = 1; s <= 5; s++) {
      const gate = s === 5;
      const base = avail.filter(k => (gate || chosen.includes(k.biome)) && k.slots.includes(s) &&
        !used.has(k.id) && (gate || (perBiome[k.biome] || 0) < 2));
      let cands = base.filter(k => prevOrdinals[s] !== k.id);
      // FINDING: in Iteration 1 only OB-06 fits Seam 4 and only OB-05 fits Seam 5, so §4.4
      // rule 7 (no same kit at the same ordinal in consecutive runs) cannot hold.
      // ASSUME: rule 7 is relaxed only when no other candidate exists; counted.
      if (cands.length === 0 && base.length > 0 && attempt >= 100) { cands = base; relaxed = true; }
      if (cands.length === 0) { ok = false; break; }
      const k = pick(rng, cands);
      used.add(k.id); if (!gate) perBiome[k.biome] = (perBiome[k.biome] || 0) + 1; run.push(k);
    }
    if (!ok) continue;
    const runBiomes = new Set(run.slice(0, 4).map(k => k.biome)).size;
    if (act >= 2 && runBiomes < 3) continue;
    if (act === 1 && runBiomes !== 2) continue;
    if (relaxed) stats.rule7Relaxed++;
    return run;
  }
  return null;
}
const stats = { rule7Relaxed: 0 };

function simulateChronicle(seed) {
  const rng = mulberry32(seed);
  const visits = Object.fromEntries(KITS.map(k => [k.id, 0]));
  const history = []; // history[r] = snapshot of visits after run r+1
  let prevOrdinals = {};
  let failures = 0;
  let r = 0;
  for (let iter = 0; r < RUNS; iter++) {
    const [runs, wins, act] = iterPlan(iter);
    // ASSUME: wins and deaths are shuffled within an Iteration.
    const outcomes = shuffle(rng, Array.from({ length: runs }, (_, i) => i < wins));
    for (const won of outcomes) {
      if (r >= RUNS) break;
      const run = assembleRun(rng, iter, act, prevOrdinals);
      if (!run) { failures++; history.push({ ...visits }); r++; continue; }
      // ASSUME: a died run ends at a Seam drawn uniformly from 1..5 (that Seam is entered).
      const seamsEntered = won ? 5 : 1 + Math.floor(rng() * 5);
      for (let s = 0; s < seamsEntered; s++) visits[run[s].id]++;
      prevOrdinals = Object.fromEntries(run.map((k, i) => [i + 1, k.id]));
      history.push({ ...visits });
      r++;
    }
  }
  return { history, failures };
}

function median(a) { const s = a.slice().sort((x, y) => x - y); return s[Math.floor(s.length / 2)]; }
function pct(a, p) { const s = a.slice().sort((x, y) => x - y); return s[Math.min(s.length - 1, Math.floor(s.length * p))]; }

const results = [];
let totalFailures = 0;
for (let c = 0; c < CHRONICLES; c++) {
  const res = simulateChronicle(SEED * 100003 + c);
  results.push(res.history); totalFailures += res.failures;
}

console.log(`kit_memory_sim: chronicles=${CHRONICLES} runs=${RUNS} seed=${SEED} reserve=${RESERVE} assembly_failures=${totalFailures} rule7_relaxed_runs=${stats.rule7Relaxed}`);

// 1) Visit distribution per kit at checkpoints (median over Chronicles of per-kit stats).
for (const at of [10, 20, 30, 40, 50].filter(x => x <= RUNS)) {
  const perChron = results.map(h => Object.values(h[at - 1]));
  const medKit = median(perChron.map(v => median(v)));
  const p25Kit = median(perChron.map(v => pct(v, 0.25)));
  const p75Kit = median(perChron.map(v => pct(v, 0.75)));
  const maxKit = median(perChron.map(v => Math.max(...v)));
  const seen = median(perChron.map(v => v.filter(x => x > 0).length));
  console.log(`run ${String(at).padStart(2)}: kits seen ${seen}/32; visits per kit p25 ${p25Kit}, median ${medKit}, p75 ${p75Kit}, max ${maxKit}`);
}

// 2) For candidate thresholds: median run at which the FIRST kit reaches it, and how many kits
//    have reached it by runs 20, 30, 40 (median over Chronicles).
console.log('\nthreshold | first kit reaches it (median run) | kits at/over it by run 20 / 30 / 40 / 50');
for (const t of [2, 3, 4, 5, 6, 7, 8, 10, 12, 15]) {
  const firsts = results.map(h => {
    const i = h.findIndex(snap => Object.values(snap).some(v => v >= t));
    return i === -1 ? Infinity : i + 1;
  });
  const counts = [20, 30, 40, 50].filter(x => x <= RUNS)
    .map(at => median(results.map(h => Object.values(h[at - 1]).filter(v => v >= t).length)));
  const f = median(firsts);
  console.log(`${String(t).padStart(9)} | ${String(f === Infinity ? 'never' : f).padStart(33)} | ${counts.join(' / ')}`);
}
