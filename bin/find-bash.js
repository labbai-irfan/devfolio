'use strict';
// Locates a real Bash on this machine. Shared by the CLI launcher and the npm script runner
// so there is one place that knows how to find Bash on Windows.

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

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

module.exports = { findBash };
