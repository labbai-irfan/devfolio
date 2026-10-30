#!/usr/bin/env node
'use strict';
// npm launcher: finds a Bash shell and runs bin/labbai-irfan with it. No application logic lives here.

const fs = require('fs');
const path = require('path');
const { spawn, spawnSync } = require('child_process');

const pkg = require('../package.json');
const script = path.join(__dirname, 'labbai-irfan').split(path.sep).join('/');

function fail(message) {
  console.error(`labbai-irfan: ${message}`);
  if (pkg.homepage) console.error(`More help: ${pkg.homepage}`);
  process.exit(3);
}

// On Windows, C:\Windows\System32\bash.exe is WSL's bash, which cannot see Windows paths. Skip it.
function isWslBash(file) {
  return /system32/i.test(file);
}

function windowsBashCandidates() {
  const found = [];
  const where = spawnSync('where', ['bash'], { encoding: 'utf8' });
  if (where.status === 0) {
    for (const line of where.stdout.split(/\r?\n/)) {
      const file = line.trim();
      if (file && !isWslBash(file)) found.push(file);
    }
  }
  const roots = [
    process.env.ProgramFiles,
    process.env['ProgramFiles(x86)'],
    process.env.LOCALAPPDATA && path.join(process.env.LOCALAPPDATA, 'Programs'),
  ];
  for (const root of roots) {
    if (root) found.push(path.join(root, 'Git', 'bin', 'bash.exe'));
  }
  return found;
}

function findBash() {
  if (process.platform !== 'win32') return 'bash';
  for (const file of windowsBashCandidates()) {
    if (fs.existsSync(file)) return file;
  }
  return null;
}

const bash = findBash();
if (!bash) {
  fail('Bash was not found. Install Git for Windows (https://gitforwindows.org), or use WSL, then run again.');
}

const child = spawn(bash, [script, ...process.argv.slice(2)], { stdio: 'inherit' });

child.on('error', (err) => {
  if (err.code === 'ENOENT') fail('Bash was not found. Install Bash (or Git for Windows on Windows), then run again.');
  console.error(`labbai-irfan: could not start Bash (${err.message}).`);
  process.exit(1);
});

// Forward Ctrl+C / kill to the app so it can restore the terminal itself.
for (const sig of ['SIGINT', 'SIGTERM']) {
  process.on(sig, () => child.kill(sig));
}

child.on('exit', (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
    return;
  }
  process.exit(code === null ? 1 : code);
});
