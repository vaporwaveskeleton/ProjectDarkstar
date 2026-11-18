#!/usr/bin/env node
// DARKSTAR audio asset report (AUDIO-001 §12.2, change C7). No dependencies.
// Scans assets/audio/generated/sfx/*.wav and prints bytes, channels, rate, bits, duration and
// whether L == R (dual-mono), then totals and the sum of imported .sample sizes (.godot/imported).
// A file that is still a Git LFS pointer is read from the LFS store (<git common dir>/lfs/objects).
// Usage: node tools/audio_report.js [dir]
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const root = path.resolve(__dirname, "..");
const dir = path.resolve(process.argv[2] || path.join(root, "assets/audio/generated/sfx"));

function lfsStore() {
  try {
    const common = execFileSync("git", ["rev-parse", "--git-common-dir"], { cwd: root, encoding: "utf8" }).trim();
    return path.resolve(root, common, "lfs", "objects");
  } catch (e) {
    return path.join(root, ".git", "lfs", "objects");
  }
}

function load(file, store) {
  let buf = fs.readFileSync(file);
  if (buf.length < 400 && buf.toString("latin1", 0, 24).startsWith("version https://git-lfs")) {
    const oid = /oid sha256:([0-9a-f]{64})/.exec(buf.toString("latin1"));
    if (!oid) return null;
    const obj = path.join(store, oid[1].slice(0, 2), oid[1].slice(2, 4), oid[1]);
    if (!fs.existsSync(obj)) return null;
    buf = fs.readFileSync(obj);
  }
  return buf;
}

function parse(buf) {
  if (buf.toString("ascii", 0, 4) !== "RIFF") return null;
  let i = 12, fmt = null, doff = 0, dlen = 0, smpl = false;
  while (i + 8 <= buf.length) {
    const id = buf.toString("ascii", i, i + 4), sz = buf.readUInt32LE(i + 4);
    if (id === "fmt ") fmt = { ch: buf.readUInt16LE(i + 10), rate: buf.readUInt32LE(i + 12), bits: buf.readUInt16LE(i + 22) };
    else if (id === "data") { doff = i + 8; dlen = Math.min(sz, buf.length - doff); }
    else if (id === "smpl") smpl = true;
    i += 8 + sz + (sz & 1);
  }
  if (!fmt) return null;
  const bps = fmt.bits / 8, frames = Math.floor(dlen / (bps * fmt.ch));
  let dual = false;
  if (fmt.ch === 2 && fmt.bits === 16) {
    dual = true;
    for (let k = 0; k < frames; k++) {
      if (buf.readInt16LE(doff + k * 4) !== buf.readInt16LE(doff + k * 4 + 2)) { dual = false; break; }
    }
  }
  return { ...fmt, frames, dur: frames / fmt.rate, dual, smpl };
}

const store = lfsStore();
const files = fs.readdirSync(dir).filter((f) => f.endsWith(".wav")).sort();
const rows = [];
let totalBytes = 0, totalDur = 0, dualBytes = 0, dualN = 0, stereoBytes = 0, stereoN = 0, missing = 0;
console.log("file|bytes|ch|rate|bits|dur_s|L==R|loop");
for (const f of files) {
  const buf = load(path.join(dir, f), store);
  const info = buf && parse(buf);
  if (!info) { console.log(`${f.slice(0, -4)}|UNREADABLE (pointer without LFS object?)`); missing++; continue; }
  totalBytes += buf.length; totalDur += info.dur;
  if (info.ch === 2) { if (info.dual) { dualBytes += buf.length; dualN++; } else { stereoBytes += buf.length; stereoN++; } }
  rows.push({ f, info });
  console.log(`${f.slice(0, -4)}|${buf.length}|${info.ch}|${info.rate}|${info.bits}|${info.dur.toFixed(3)}|${info.ch === 2 ? (info.dual ? "dual-mono" : "stereo") : "mono"}|${info.smpl ? "loop" : ""}`);
}
console.log(`TOTAL ${files.length - missing} files, ${totalBytes} bytes (${(totalBytes / 1048576).toFixed(2)} MiB), ${totalDur.toFixed(2)} s`);
console.log(`Stereo-stored dual-mono (L==R): ${dualN} files, ${dualBytes} bytes (convertible with chirp --mono)`);
console.log(`Genuinely stereo (L!=R): ${stereoN} files, ${stereoBytes} bytes`);
if (missing) console.log(`UNREADABLE: ${missing}`);

const imp = path.join(root, ".godot", "imported");
if (fs.existsSync(imp)) {
  let n = 0, sum = 0;
  for (const f of fs.readdirSync(imp)) {
    if (!f.endsWith(".sample")) continue;
    const m = /^(.*)\.wav-[0-9a-f]+\.sample$/.exec(f);
    if (!m || !fs.existsSync(path.join(dir, m[1] + ".wav"))) continue;
    n++; sum += fs.statSync(path.join(imp, f)).size;
  }
  console.log(`Imported .sample files for these cues: ${n}, ${sum} bytes (${(sum / 1048576).toFixed(2)} MiB)`);
} else {
  console.log("No .godot/imported folder (run the Godot import first); .sample total unavailable.");
}
