#!/usr/bin/env node
'use strict';
// Runs a bash script via npm, finding bash the same way the CLI launcher does.
// Usage: node scripts/run-bash.js <script> [args...]

const { spawnSync } = require('child_process');
const { findBash } = require('../bin/find-bash');

const bash = findBash();
if (!bash) {
  console.error('labbai-irfan: Bash was not found. Install Git for Windows (https://gitforwindows.org), or use WSL, then run again.');
  process.exit(3);
}

const result = spawnSync(bash, process.argv.slice(2), { stdio: 'inherit' });
process.exit(result.status === null ? 1 : result.status);
