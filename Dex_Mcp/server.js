#!/usr/bin/env node
/**
 * Dex_Mcp - MCP server bridging Claude to a running Dex++ instance.
 *
 * Two faces:
 *   1. MCP stdio (JSON-RPC, newline delimited)  <- Claude talks here
 *   2. Local HTTP listener on 127.0.0.1:PORT    <- DexBridge.lua talks here
 *
 * Zero npm dependencies. Node 18+.
 *
 * IMPORTANT: stdout is the JSON-RPC channel. All logging goes to stderr.
 */

const http = require("node:http");
const fs = require("node:fs");
const path = require("node:path");

const PORT = Number(process.env.DEX_MCP_PORT || 8790);
const HOLD_MS = Number(process.env.DEX_MCP_HOLD_MS || 1000);
const TIMEOUT_MS = Number(process.env.DEX_MCP_TIMEOUT_MS || 20000);
// A rejoin, a teleport or an executor re-inject takes the in-game half away for a few
// seconds. TIMEOUT_MS is the budget for a bridge that is present and not answering; this is
// the separate, much longer budget for one that is between sessions and expected back.
const OFFLINE_GRACE_MS = Number(process.env.DEX_MCP_OFFLINE_GRACE_MS || 120000);
const TOKEN = process.env.DEX_MCP_TOKEN || "";

// where a relative `file` argument to dex_inject is resolved from
const ROOT = path.resolve(process.env.DEX_MCP_ROOT || process.cwd());
// a source bigger than this is almost certainly a mistake (out.lua itself is ~1 MB)
const MAX_INJECT_BYTES = Number(process.env.DEX_MCP_MAX_INJECT || 4 * 1024 * 1024);
// Daemon mode: the process is started once, by hand or at login, and outlives every Claude
// session. Claude then reaches it over POST /mcp instead of owning it as a child.
const DAEMON = process.argv.includes("--daemon") || process.env.DEX_MCP_DAEMON === "1";
const SERVER_NAME = "dex-mcp";
const SERVER_VERSION = "1.0.0";

const log = (...a) => console.error("[dex-mcp]", ...a);

// ---------------------------------------------------------------------------
// Command queue shared between the MCP side and the HTTP bridge side
// ---------------------------------------------------------------------------

let nextCmdId = 1;
const queue = []; // commands not yet handed to the bridge
const pending = new Map(); // id -> { resolve, reject, timer }
const waiters = []; // long-poll GET /cmd requests parked here
let lastSeen = 0; // last time the bridge touched us

const isConnected = () => Date.now() - lastSeen < 5000;

function flush() {
  while (queue.length && waiters.length) {
    const w = waiters.shift();
    clearTimeout(w.timer);
    if (w.res.writableEnded) continue;
    const cmd = queue.shift();
    w.res.writeHead(200, { "Content-Type": "application/json" });
    w.res.end(JSON.stringify(cmd));
  }
}

const TICK_MS = 500;

function dispatch(op, args) {
  return new Promise((resolve, reject) => {
    const id = nextCmdId++;
    const startedAt = Date.now();
    // Only time spent with the bridge actually connected counts against TIMEOUT_MS, so a
    // command issued in the middle of a rejoin waits for the new session instead of failing
    // against the old one. The wall-clock cap stops it waiting forever.
    let activeMs = 0;

    const timer = setInterval(() => {
      if (isConnected()) activeMs += TICK_MS;

      const waited = Date.now() - startedAt;
      const stalled = activeMs >= TIMEOUT_MS;
      const givenUp = waited >= OFFLINE_GRACE_MS;

      if (!stalled && !givenUp) return;

      clearInterval(timer);
      pending.delete(id);

      const i = queue.findIndex((c) => c.id === id);
      if (i >= 0) queue.splice(i, 1);

      reject(
        new Error(
          stalled
            ? `timeout after ${TIMEOUT_MS}ms of connected time waiting for Dex bridge (op=${op}). ` +
              `The bridge is answering polls but did not return a result.`
            : `gave up after ${Math.round(waited / 1000)}s waiting for the Dex bridge to come back (op=${op}). ` +
              `bridge connected: ${isConnected()}. ` +
              `Is DexBridge.lua running inside your executor?`
        )
      );
    }, TICK_MS);

    pending.set(id, { resolve, reject, timer });
    queue.push({ id, op, args: args || {} });
    flush();
  });
}

// ---------------------------------------------------------------------------
// HTTP bridge
// ---------------------------------------------------------------------------

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    req.on("data", (c) => {
      size += c.length;
      if (size > 32 * 1024 * 1024) {
        reject(new Error("body too large"));
        req.destroy();
        return;
      }
      chunks.push(c);
    });
    req.on("end", () => resolve(Buffer.concat(chunks).toString("utf8")));
    req.on("error", reject);
  });
}

// One JSON-RPC message in, one response out. Notifications get no response, matching stdio.
function handleHttpRpc(msg) {
  return new Promise((resolve) => {
    let answered = false;
    const send = (out) => {
      if (!answered) {
        answered = true;
        resolve(out);
      }
    };
    handleMessage(msg, send)
      .then(() => send(null))
      .catch((e) => {
        log("http handler crashed:", e.stack || e.message);
        send(
          msg && msg.id !== undefined && msg.id !== null
            ? { jsonrpc: "2.0", id: msg.id, error: { code: -32603, message: String(e.message || e) } }
            : null
        );
      });
  });
}

const httpServer = http.createServer(async (req, res) => {
  const path = (req.url || "").split("?")[0];
  const isMcp = path === "/mcp";

  // The bridge authenticates with X-Dex-Token; an MCP client has no such header and sends
  // Authorization: Bearer instead, so both spellings are accepted.
  if (TOKEN) {
    const bearer = String(req.headers["authorization"] || "").replace(/^Bearer /i, "");
    if (req.headers["x-dex-token"] !== TOKEN && bearer !== TOKEN) {
      res.writeHead(401, { "Content-Type": "text/plain" });
      res.end("bad token");
      return;
    }
  }

  if (isMcp) {
    // Claude talking is not evidence the game-side bridge is alive, so /mcp must not touch
    // lastSeen -- doing so would make every command look connected and time out short.
    if (req.method === "POST") {
      let body;
      try {
        body = JSON.parse(await readBody(req));
      } catch (e) {
        res.writeHead(400, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ jsonrpc: "2.0", error: { code: -32700, message: "parse error: " + e.message } }));
        return;
      }

      const batch = Array.isArray(body);
      const msgs = batch ? body : [body];
      const out = [];
      for (const m of msgs) {
        const r = await handleHttpRpc(m);
        if (r) out.push(r);
      }

      if (!out.length) {
        res.writeHead(202);
        res.end();
        return;
      }
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify(batch ? out : out[0]));
      return;
    }

    // No server-initiated stream and no session state to tear down.
    res.writeHead(req.method === "DELETE" ? 200 : 405, { "Content-Type": "text/plain" });
    res.end(req.method === "DELETE" ? "ok" : "method not allowed");
    return;
  }

  lastSeen = Date.now();

  if (req.method === "GET" && path === "/cmd") {
    if (queue.length) {
      const cmd = queue.shift();
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify(cmd));
      return;
    }
    const waiter = { res, timer: null };
    waiter.timer = setTimeout(() => {
      const i = waiters.indexOf(waiter);
      if (i >= 0) waiters.splice(i, 1);
      if (!res.writableEnded) {
        res.writeHead(204);
        res.end();
      }
    }, HOLD_MS);
    req.on("close", () => {
      const i = waiters.indexOf(waiter);
      if (i >= 0) waiters.splice(i, 1);
      clearTimeout(waiter.timer);
    });
    waiters.push(waiter);
    return;
  }

  if (req.method === "POST" && path === "/result") {
    let payload;
    try {
      payload = JSON.parse(await readBody(req));
    } catch (e) {
      res.writeHead(400, { "Content-Type": "text/plain" });
      res.end("bad json: " + e.message);
      return;
    }
    const entry = pending.get(payload.id);
    if (entry) {
      pending.delete(payload.id);
      clearInterval(entry.timer);
      if (payload.ok) entry.resolve(payload.data);
      else entry.reject(new Error(String(payload.data)));
    } else {
      log("result for unknown/expired command id", payload.id);
    }
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end('{"ok":true}');
    return;
  }

  if (path === "/ping") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ ok: true, server: SERVER_NAME, version: SERVER_VERSION }));
    return;
  }

  res.writeHead(404, { "Content-Type": "text/plain" });
  res.end("not found");
});

httpServer.on("error", (e) => {
  log("HTTP listener error:", e.message);
  if (e.code === "EADDRINUSE") {
    log(`port ${PORT} already in use. Set DEX_MCP_PORT to something else.`);
    process.exit(1);
  }
});

httpServer.listen(PORT, "127.0.0.1", () => {
  log(`bridge listening on http://127.0.0.1:${PORT} (hold=${HOLD_MS}ms, timeout=${TIMEOUT_MS}ms)`);
});

// ---------------------------------------------------------------------------
// Tool definitions
// ---------------------------------------------------------------------------

const TOOLS = [
  {
    name: "dex_status",
    description:
      "Check whether the Dex++ bridge inside Roblox is currently connected, and report game/place info. Call this first if other tools time out.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
  },
  {
    name: "dex_tree",
    description:
      "Walk the Roblox instance tree from a path. Returns names, class names and child counts. Depth is capped at 5 and total nodes at 2000 to keep output small.",
    inputSchema: {
      type: "object",
      properties: {
        path: {
          type: "string",
          description:
            'Dot path, e.g. "game.Workspace" or "Workspace.Baseplate". Omit or use "game" for the root. If a name contains a dot, pass path_parts instead.',
        },
        path_parts: {
          type: "array",
          items: { type: "string" },
          description: 'Unambiguous path as segments, e.g. ["Workspace","My.Weird.Name"].',
        },
        depth: { type: "number", description: "How many levels of children to expand. Default 2, max 5." },
      },
      additionalProperties: false,
    },
  },
  {
    name: "dex_props",
    description:
      "Read every property of one instance, using the Roblox API dump Dex++ already loaded. Includes inherited properties. Values are serialized to JSON-safe forms.",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string", description: 'Dot path to the instance, e.g. "Workspace.Baseplate".' },
        path_parts: { type: "array", items: { type: "string" } },
        filter: { type: "string", description: "Only return properties whose name contains this substring (case-insensitive)." },
        include_hidden: { type: "boolean", description: "Include hidden / deprecated / non-scriptable properties. Default false." },
      },
      additionalProperties: false,
    },
  },
  {
    name: "dex_decompile",
    description:
      "Decompile a LocalScript / ModuleScript / Script using whichever decompiler Dex++ is configured for (built-in, Konstant, Shiny, or Advanced Decompiler). Can take several seconds.",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string", description: 'Dot path to the script instance.' },
        path_parts: { type: "array", items: { type: "string" } },
      },
      additionalProperties: false,
    },
  },
  {
    name: "dex_exec",
    description:
      "Run a chunk of Luau inside the game client and return whatever it returns. Runs with the executor's full permissions. Return a value to get it back; runtime errors come back as a tool error.",
    inputSchema: {
      type: "object",
      properties: { code: { type: "string", description: "Luau source. Use `return ...` to send data back." } },
      required: ["code"],
      additionalProperties: false,
    },
  },
  {
    name: "dex_select",
    description:
      "Scroll the Dex++ explorer window to an instance and expand its ancestors so a human can see it. Note: Dex++ exposes no public selection setter, so this reveals the node rather than highlighting it.",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        path_parts: { type: "array", items: { type: "string" } },
      },
      additionalProperties: false,
    },
  },
  {
    name: "dex_inject",
    description:
      "Inject a whole Luau script into the running game client the way an executor would, from a local file, a URL, or inline source. " +
      "Unlike dex_exec this runs the chunk on its own thread (so a script that yields forever is fine), tears down the previous injection first, " +
      "and streams back whatever the script printed or errored during the capture window. Use it to test an edit to a script in this repo without leaving the chat.",
    inputSchema: {
      type: "object",
      properties: {
        file: {
          type: "string",
          description: `Path to a .lua/.luau file. Relative paths resolve from ${ROOT}. Exactly one of file / url / code is required.`,
        },
        url: { type: "string", description: "Fetch the source from this URL (raw text) and inject it." },
        code: { type: "string", description: "Inline Luau source." },
        chunk_name: {
          type: "string",
          description: "Name shown in error tracebacks. Defaults to the file name, or DexMcpInject.",
        },
        capture_ms: {
          type: "number",
          description: "How long to collect console output after starting the script. Default 1500, max 10000.",
        },
        cleanup: {
          type: "string",
          description:
            'Name of a getgenv() function to call before injecting, so re-injecting does not stack two copies. Default "ValkyrieCleanup". Pass "" to skip.',
        },
      },
      additionalProperties: false,
    },
  },
  {
    name: "dex_spy",
    description:
      "Remote spy: record every FireServer / InvokeServer this client makes, from any script, with the calling script named. " +
      "Use it when something happens server-side (a kick, a refusal, a silent failure) and you need to know what actually left the client, " +
      "including calls made by the game's own scripts rather than yours. Optionally also records server -> client RemoteEvent traffic. " +
      'Call with action "start", let the game run, then action "read".',
    inputSchema: {
      type: "object",
      properties: {
        action: {
          type: "string",
          enum: ["start", "stop", "read", "clear", "status"],
          description:
            'start = install hooks and begin recording (clears the buffer); read = return recorded calls (default); stop = keep the hooks but stop recording; clear = empty the buffer; status = what the spy is doing.',
        },
        incoming: {
          type: "boolean",
          description:
            "start only: also record server -> client RemoteEvent traffic. Every RemoteEvent under ReplicatedStorage, ReplicatedFirst, Workspace and Lighting is listened to, whatever the folder is called, and remotes the game creates later are picked up as they appear. Noisy; default false.",
        },
        max: { type: "number", description: "start only: how many calls to keep in the ring buffer. Default 600, min 50, max 2000." },
        limit: { type: "number", description: "read only: how many calls to return, newest last. Default 50, max 300." },
        direction: {
          type: "string",
          enum: ["out", "in", "both"],
          description: 'read only: "out" = calls this client made, "in" = events the server sent. Default both.',
        },
        filter: { type: "string", description: "read only: only calls whose remote name, arguments or calling script contain this substring (case-insensitive)." },
        since: { type: "number", description: "read only: only calls with a sequence number above this. Pass the Latest value from a previous read to poll for new traffic." },
      },
      additionalProperties: false,
    },
  },
  {
    name: "dex_console",
    description:
      "Read the Roblox client console backlog (LogService history): prints, warnings and errors from every script, not only injected ones. Call it after dex_inject when an error landed after the capture window closed.",
    inputSchema: {
      type: "object",
      properties: {
        count: { type: "number", description: "How many of the most recent lines to return. Default 50, max 300." },
        filter: { type: "string", description: "Only lines containing this substring (case-insensitive)." },
        errors_only: { type: "boolean", description: "Only warnings and errors. Default false." },
      },
      additionalProperties: false,
    },
  },
];

const TOOL_OPS = {
  dex_status: "status",
  dex_tree: "tree",
  dex_props: "props",
  dex_decompile: "decompile",
  dex_exec: "exec",
  dex_select: "select",
  dex_inject: "inject",
  dex_spy: "spy",
  dex_console: "console",
};

// ---------------------------------------------------------------------------
// dex_inject: the source is resolved here, on the Node side, so the game never
// needs filesystem access to the repo and the bridge only ever sees plain text.
// ---------------------------------------------------------------------------

async function prepareInject(args) {
  const given = ["file", "url", "code"].filter((k) => typeof args[k] === "string" && args[k] !== "");
  if (given.length !== 1) {
    throw new Error(`dex_inject needs exactly one of file / url / code (got ${given.length ? given.join(" + ") : "none"})`);
  }

  let source;
  let origin;
  let name = args.chunk_name;

  if (args.file) {
    const full = path.resolve(ROOT, args.file);
    if (!fs.existsSync(full)) throw new Error(`file not found: ${full}`);
    source = fs.readFileSync(full, "utf8");
    origin = full;
    name = name || path.basename(full);
  } else if (args.url) {
    const res = await fetch(args.url);
    if (!res.ok) throw new Error(`fetch ${args.url} failed: HTTP ${res.status}`);
    source = await res.text();
    origin = args.url;
    name = name || args.url.split("/").pop();
  } else {
    source = args.code;
    origin = "inline";
  }

  const bytes = Buffer.byteLength(source, "utf8");
  if (bytes > MAX_INJECT_BYTES) {
    throw new Error(`source is ${bytes} bytes, over the ${MAX_INJECT_BYTES} byte cap (raise DEX_MCP_MAX_INJECT if intended)`);
  }
  if (!source.trim()) throw new Error(`source from ${origin} is empty`);

  return {
    info: { Origin: origin, Bytes: bytes },
    args: {
      source,
      chunk_name: name || "DexMcpInject",
      capture_ms: Math.min(Math.max(Number(args.capture_ms) || 1500, 0), 10000),
      cleanup: args.cleanup === undefined ? "ValkyrieCleanup" : String(args.cleanup),
    },
  };
}

// ---------------------------------------------------------------------------
// MCP stdio (JSON-RPC 2.0, newline delimited)
// ---------------------------------------------------------------------------

// Two transports carry the same JSON-RPC: stdio (Claude spawns us as a child) and
// POST /mcp (Claude connects to a server that was already running). The second one is the
// reason this split exists -- a stdio child dies with the Claude session, taking the bridge
// listener with it, so Dex reports Failed the moment the session closes.
const stdioSend = (msg) => process.stdout.write(JSON.stringify(msg) + "\n");

function toolText(obj) {
  const text = typeof obj === "string" ? obj : JSON.stringify(obj, null, 2);
  return { content: [{ type: "text", text }] };
}

async function handleMessage(msg, send) {
  const reply = (id, result) => send({ jsonrpc: "2.0", id, result });
  const replyError = (id, code, message) =>
    send({ jsonrpc: "2.0", id, error: { code, message } });

  const { id, method, params } = msg;
  const isNotification = id === undefined || id === null;

  switch (method) {
    case "initialize":
      reply(id, {
        protocolVersion: (params && params.protocolVersion) || "2024-11-05",
        capabilities: { tools: {} },
        serverInfo: { name: SERVER_NAME, version: SERVER_VERSION },
      });
      return;

    case "notifications/initialized":
    case "initialized":
      return; // notification, no response

    case "ping":
      if (!isNotification) reply(id, {});
      return;

    case "tools/list":
      reply(id, { tools: TOOLS });
      return;

    case "tools/call": {
      const name = params && params.name;
      const op = TOOL_OPS[name];
      if (!op) {
        replyError(id, -32602, `unknown tool: ${name}`);
        return;
      }
      try {
        let callArgs = (params && params.arguments) || {};
        let info = null;

        if (name === "dex_inject") {
          const prepared = await prepareInject(callArgs);
          callArgs = prepared.args;
          info = prepared.info;
        }

        const data = await dispatch(op, callArgs);
        reply(id, toolText(info && data && typeof data === "object" ? { ...info, ...data } : data));
      } catch (e) {
        reply(id, { content: [{ type: "text", text: `ERROR: ${e.message}` }], isError: true });
      }
      return;
    }

    default:
      if (!isNotification) replyError(id, -32601, `method not found: ${method}`);
  }
}

// In daemon mode nobody speaks JSON-RPC on stdin, and stdin reaching EOF must not be read
// as "the client hung up, exit".
if (DAEMON) {
  log(`daemon mode: stdio JSON-RPC disabled, MCP served at http://127.0.0.1:${PORT}/mcp`);
} else {

let stdinBuffer = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => {
  stdinBuffer += chunk;
  let nl;
  while ((nl = stdinBuffer.indexOf("\n")) >= 0) {
    const line = stdinBuffer.slice(0, nl).trim();
    stdinBuffer = stdinBuffer.slice(nl + 1);
    if (!line) continue;
    let msg;
    try {
      msg = JSON.parse(line);
    } catch (e) {
      log("bad JSON-RPC line:", e.message);
      continue;
    }
    handleMessage(msg, stdioSend).catch((e) => log("handler crashed:", e.stack || e.message));
  }
});

process.stdin.on("end", () => {
  log("stdin closed, exiting");
  process.exit(0);
});

}
