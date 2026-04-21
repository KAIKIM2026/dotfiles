#!/usr/bin/env node

import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import os from "node:os";
import { dirname, join } from "node:path";

const home = os.homedir();
const codexConfigPath = process.env.CODEX_CONFIG_PATH || join(home, ".codex", "config.toml");
const desiredStatusLine = 'status_line = ["model-with-reasoning", "git-branch", "context-used"]';
const desiredHudEnv = 'OMX_DISABLE_TMUX_HUD = "1"';
const hudHookCall = "await reconcileHudForPromptSubmit(cwd).catch(() => { });";

function readText(path) {
  return existsSync(path) ? readFileSync(path, "utf8") : "";
}

function writeText(path, content) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, content);
}

function upsertTomlValue(content, tableName, key, valueLine) {
  const tableHeader = `[${tableName}]`;
  const lines = content.length > 0 ? content.split("\n") : [];
  let tableStart = -1;
  let tableEnd = lines.length;

  for (let i = 0; i < lines.length; i += 1) {
    if (lines[i].trim() === tableHeader) {
      tableStart = i;
      break;
    }
  }

  if (tableStart === -1) {
    const trimmed = content.trimEnd();
    return `${trimmed}${trimmed ? "\n\n" : ""}${tableHeader}\n${valueLine}\n`;
  }

  for (let i = tableStart + 1; i < lines.length; i += 1) {
    if (/^\[.+\]$/.test(lines[i].trim())) {
      tableEnd = i;
      break;
    }
  }

  const keyPattern = new RegExp(`^\\s*${key}\\s*=`);
  for (let i = tableStart + 1; i < tableEnd; i += 1) {
    if (keyPattern.test(lines[i])) {
      lines[i] = valueLine;
      return `${lines.join("\n").replace(/\n*$/, "\n")}`;
    }
  }

  lines.splice(tableEnd, 0, valueLine);
  return `${lines.join("\n").replace(/\n*$/, "\n")}`;
}

function patchCodexConfig() {
  let content = readText(codexConfigPath);
  content = upsertTomlValue(content, "tui", "status_line", desiredStatusLine);
  content = upsertTomlValue(content, "env", "OMX_DISABLE_TMUX_HUD", desiredHudEnv);
  writeText(codexConfigPath, content);
}

function resolveOhMyCodexHookPath() {
  if (process.env.OH_MY_CODEX_HOOK_PATH) {
    return process.env.OH_MY_CODEX_HOOK_PATH;
  }

  const globalNodeModules = execFileSync("npm", ["root", "-g"], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  }).trim();
  if (!globalNodeModules) {
    throw new Error("Failed to resolve npm global root.");
  }

  return join(globalNodeModules, "oh-my-codex", "dist", "scripts", "codex-native-hook.js");
}

function patchOhMyCodexHudHook() {
  const hookPath = resolveOhMyCodexHookPath();
  const content = readText(hookPath);
  if (!content) {
    throw new Error(`Missing hook file: ${hookPath}`);
  }
  if (content.includes('if (process.env.OMX_DISABLE_TMUX_HUD !== "1") {')) {
    return hookPath;
  }

  let next = content.replace(
    /^(\s*)await reconcileHudForPromptSubmit\(cwd\)\.catch\(\(\) => \{ \}\);\s*$/m,
    (_, indent) => [
      `${indent}if (process.env.OMX_DISABLE_TMUX_HUD !== "1") {`,
      `${indent}    ${hudHookCall}`,
      `${indent}}`,
    ].join("\n"),
  );
  if (next === content) {
    next = content.replace(
      "        // Local preference: keep tmux auto-launch, but do not auto-spawn the OMX HUD pane.",
      [
        '        if (process.env.OMX_DISABLE_TMUX_HUD !== "1") {',
        `            ${hudHookCall}`,
        "        }",
      ].join("\n"),
    );
  }
  if (next === content) {
    throw new Error(`Failed to patch HUD hook in ${hookPath}`);
  }

  writeText(hookPath, next);
  return hookPath;
}

patchCodexConfig();
const hookPath = patchOhMyCodexHudHook();
process.stdout.write(`patched ${codexConfigPath}\npatched ${hookPath}\n`);
