#!/usr/bin/env node

import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import os from "node:os";

const home = os.homedir();
const omxSessionFile = join(home, ".omx", "state", "session.json");
const codexSessionsRoot = join(home, ".codex", "sessions");

function readJson(filePath) {
  if (!existsSync(filePath)) return null;
  try {
    return JSON.parse(readFileSync(filePath, "utf8"));
  } catch {
    return null;
  }
}

function findSessionFile(rootDir, sessionId) {
  if (!sessionId || !existsSync(rootDir)) return null;

  const stack = [rootDir];
  while (stack.length > 0) {
    const current = stack.pop();
    if (!current) continue;

    for (const entry of readdirSync(current, { withFileTypes: true })) {
      const nextPath = join(current, entry.name);
      if (entry.isDirectory()) {
        stack.push(nextPath);
        continue;
      }
      if (entry.isFile() && entry.name.includes(sessionId) && entry.name.endsWith(".jsonl")) {
        return nextPath;
      }
    }
  }

  return null;
}

function findLatestSessionFile(rootDir) {
  if (!existsSync(rootDir)) return null;

  const stack = [rootDir];
  let latestPath = null;
  let latestMtime = -1;

  while (stack.length > 0) {
    const current = stack.pop();
    if (!current) continue;

    for (const entry of readdirSync(current, { withFileTypes: true })) {
      const nextPath = join(current, entry.name);
      if (entry.isDirectory()) {
        stack.push(nextPath);
        continue;
      }
      if (!entry.isFile() || !entry.name.endsWith(".jsonl")) continue;

      const mtime = statSync(nextPath).mtimeMs;
      if (mtime > latestMtime) {
        latestMtime = mtime;
        latestPath = nextPath;
      }
    }
  }

  return latestPath;
}

function humanizeRemainingSeconds(totalSeconds) {
  const seconds = Math.max(0, Math.round(Number(totalSeconds) || 0));
  if (seconds < 60) return "<1m";

  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const parts = [];

  if (days > 0) parts.push(`${days}d`);
  if (hours > 0) parts.push(`${hours}h`);
  if (days === 0 && minutes > 0) parts.push(`${minutes}m`);
  if (parts.length === 0) parts.push("0m");

  return parts.join("");
}

function clampPercent(value) {
  const numeric = Number(value);
  if (!Number.isFinite(numeric)) return null;
  return Math.max(0, Math.min(999, Math.round(numeric)));
}

function parseSession(sessionFile) {
  const raw = readFileSync(sessionFile, "utf8");
  const lines = raw.split("\n").filter(Boolean);

  let latestTokenCount = null;

  for (const line of lines) {
    try {
      const event = JSON.parse(line);
      if (event?.type === "event_msg" && event?.payload?.type === "token_count") {
        latestTokenCount = event;
      }
    } catch {
      // Ignore malformed lines in the rolling session log.
    }
  }

  return { latestTokenCount };
}

function buildStatusLine() {
  const sessionState = readJson(omxSessionFile);
  const sessionIds = [
    sessionState?.native_session_id,
    sessionState?.session_id,
  ].filter(Boolean);
  const sessionFile =
    sessionIds.map((sessionId) => findSessionFile(codexSessionsRoot, sessionId)).find(Boolean)
    ?? findLatestSessionFile(codexSessionsRoot);
  if (!sessionFile) return "";

  const sessionData = parseSession(sessionFile);
  const tokenCount = sessionData.latestTokenCount;
  if (!tokenCount?.payload?.rate_limits) return "";
  const nowSeconds = Math.floor(Date.now() / 1000);
  const parts = [];

  const primaryUsed = clampPercent(tokenCount?.payload?.rate_limits?.primary?.used_percent);
  const primaryResetAt = Number(tokenCount?.payload?.rate_limits?.primary?.resets_at);
  if (primaryUsed !== null && Number.isFinite(primaryResetAt)) {
    parts.push(`5h used:${primaryUsed}%(${humanizeRemainingSeconds(primaryResetAt - nowSeconds)})`);
  }

  const secondaryUsed = clampPercent(tokenCount?.payload?.rate_limits?.secondary?.used_percent);
  const secondaryResetAt = Number(tokenCount?.payload?.rate_limits?.secondary?.resets_at);
  if (secondaryUsed !== null && Number.isFinite(secondaryResetAt)) {
    parts.push(`wk used:${secondaryUsed}%(${humanizeRemainingSeconds(secondaryResetAt - nowSeconds)})`);
  }

  return parts.join(" | ");
}

process.stdout.write(buildStatusLine());
