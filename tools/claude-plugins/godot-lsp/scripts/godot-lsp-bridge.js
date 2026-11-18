#!/usr/bin/env node
// stdio <-> TCP bridge to the Godot editor's GDScript language server.
// Claude Code speaks LSP over this process's stdin/stdout; Godot serves it on TCP.
// Host/port: GODOT_LSP_HOST (default 127.0.0.1), GODOT_LSP_PORT (default 6005).
// The Godot editor must be open on this project (Editor Settings > Network > Language Server).
"use strict";
const net = require("net");

const host = process.env.GODOT_LSP_HOST || "127.0.0.1";
const port = Number(process.env.GODOT_LSP_PORT || 6005);

const socket = net.connect({ host, port });

socket.once("connect", () => {
  process.stdin.pipe(socket);
  socket.pipe(process.stdout);
});

socket.on("error", (err) => {
  process.stderr.write(
    `godot-lsp: cannot reach Godot LSP at ${host}:${port} (${err.code || err.message}). ` +
      "Open the Godot editor on this project.\n"
  );
  process.exit(1);
});

socket.on("close", () => process.exit(0));
process.stdin.on("end", () => socket.end());
