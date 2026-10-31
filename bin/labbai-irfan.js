#!/usr/bin/env node
'use strict';
// npm launcher: finds a Bash shell and runs bin/labbai-irfan with it. No application logic lives here.

const path = require('path');
const { spawn } = require('child_process');
const { findBash } = require('./find-bash');

const pkg = require('../package.json');
const script = path.join(__dirname, 'labbai-irfan').split(path.sep).join('/');

function fail(message) {
  console.error(`labbai-irfan: ${message}`);
  if (pkg.homepage) console.error(`More help: ${pkg.homepage}`);
  process.exit(3);
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
