'use strict';

/**
 * Morph Animation Engine for `labbai-irfan` CLI
 * 
 * Animation Sequence:
 *   ◐ -> ◓ -> ◑ -> ◒
 * 
 * Color System (ANSI TrueColor / 256-color fallback):
 * - Active morph: Electric Cyan (#00D9FF -> rgb(0, 217, 255))
 * - Secondary morph: Soft Blue (#5599FF -> rgb(85, 153, 255))
 * - Completed task: Bright Green (#35D07F -> rgb(53, 208, 127))
 * - Failed task: Soft Red (#FF5C5C -> rgb(255, 92, 92))
 * - Task description: Default foreground
 * 
 * Features:
 * - Independent task state management
 * - Zero flickering with atomic \r\x1b[K writes
 * - Static locked completed tasks (never re-animated)
 * - Pulsing green "● Ready" state
 * - Full support for Windows Terminal, PowerShell, Git Bash, Linux, macOS
 * - Respects NO_COLOR, CI, non-TTY, --no-animation
 * - Safe signal trapping (SIGINT / Ctrl+C, SIGTERM, exit) restoring cursor visibility
 */

class MorphSpinner {
  constructor(options = {}) {
    this.stream = options.stream || process.stdout;
    this.indent = options.indent || '   ';
    this.fps = options.fps || 12; // ~80ms per frame
    this.frameInterval = Math.round(1000 / this.fps);

    // Environment & capabilities detection
    this.isTTY = Boolean(this.stream.isTTY);
    this.noColor = Boolean(
      (process.env.NO_COLOR !== undefined && process.env.NO_COLOR !== '' && process.env.NO_COLOR !== '0') ||
      process.argv.includes('--no-color') ||
      process.argv.includes('--plain')
    );
    this.isCI = Boolean(
      process.env.CI ||
      process.env.CONTINUOUS_INTEGRATION ||
      process.env.BUILD_NUMBER ||
      process.env.GITHUB_ACTIONS ||
      process.argv.includes('--no-animation') ||
      process.env.LABBAI_REDUCED_MOTION === '1'
    );

    // UTF-8 detection
    this.isUTF8 = options.utf8 !== undefined ? options.utf8 : (
      !process.argv.includes('--plain') &&
      process.env.LC_ALL !== 'C' &&
      process.env.LANG !== 'C'
    );

    // Morph frames (◐ -> ◓ -> ◑ -> ◒)
    this.frames = this.isUTF8 ? ['◐', '◓', '◑', '◒'] : ['|', '/', '-', '\\'];
    this.charCheck = this.isUTF8 ? '✔' : 'OK';
    this.charCross = this.isUTF8 ? '✖' : 'ERR';
    this.charDot = this.isUTF8 ? '●' : '*';

    // ANSI Colors: Electric Cyan, Soft Blue, Bright Green, Soft Red
    const trueColor = Boolean(
      process.env.COLORTERM === 'truecolor' ||
      process.env.COLORTERM === '24bit' ||
      process.env.WT_SESSION ||
      process.env.TERM_PROGRAM
    );

    if (this.noColor) {
      this.colors = {
        cyan: '',
        softBlue: '',
        green: '',
        red: '',
        white: '',
        dim: '',
        bold: '',
        reset: ''
      };
    } else if (trueColor) {
      this.colors = {
        cyan: '\x1b[38;2;0;217;255m',      // #00D9FF
        softBlue: '\x1b[38;2;85;153;255m',  // #5599FF
        green: '\x1b[38;2;53;208;127m',    // #35D07F
        red: '\x1b[38;2;255;92;92m',       // #FF5C5C
        white: '\x1b[37m',
        dim: '\x1b[90m',
        bold: '\x1b[1m',
        reset: '\x1b[0m'
      };
    } else {
      // 256-color fallback
      this.colors = {
        cyan: '\x1b[38;5;45m',
        softBlue: '\x1b[38;5;69m',
        green: '\x1b[38;5;42m',
        red: '\x1b[38;5;203m',
        white: '\x1b[37m',
        dim: '\x1b[90m',
        bold: '\x1b[1m',
        reset: '\x1b[0m'
      };
    }

    // Active state
    this.currentFrameIdx = 0;
    this.timer = null;
    this.currentText = '';
    this.cursorHidden = false;
    this.isDestroyed = false;

    this.bindSignals();
  }

  bindSignals() {
    this._onSigint = () => {
      this.cleanup();
      process.exit(130);
    };
    this._onSigterm = () => {
      this.cleanup();
      process.exit(143);
    };
    this._onExit = () => {
      this.cleanup();
    };

    process.once('SIGINT', this._onSigint);
    process.once('SIGTERM', this._onSigterm);
    process.once('exit', this._onExit);

    if (this.isTTY && this.stream.on) {
      this._onResize = () => {
        if (this.timer && this.currentText) {
          this.renderFrame();
        }
      };
      this.stream.on('resize', this._onResize);
    }
  }

  hideCursor() {
    if (this.isTTY && !this.cursorHidden) {
      this.stream.write('\x1b[?25l');
      this.cursorHidden = true;
    }
  }

  showCursor() {
    if (this.isTTY && this.cursorHidden) {
      this.stream.write('\x1b[?25h');
      this.cursorHidden = false;
    }
  }

  cleanup() {
    if (this.isDestroyed) return;
    this.isDestroyed = true;

    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
    this.showCursor();

    process.removeListener('SIGINT', this._onSigint);
    process.removeListener('SIGTERM', this._onSigterm);
    process.removeListener('exit', this._onExit);

    if (this.isTTY && this.stream.removeListener && this._onResize) {
      this.stream.removeListener('resize', this._onResize);
    }
  }

  renderFrame() {
    // Alternates between Electric Cyan and Soft Blue on consecutive frames for morphing energy
    const glyph = this.frames[this.currentFrameIdx % this.frames.length];
    const color = (this.currentFrameIdx % 2 === 0) ? this.colors.cyan : this.colors.softBlue;
    const line = `${this.indent}${color}${glyph}${this.colors.reset} ${this.currentText}...`;
    this.stream.write(`\r\x1b[K${line}`);
  }

  startTask(text) {
    this.currentText = text;
    this.currentFrameIdx = 0;

    if (!this.isTTY || this.isCI) {
      return;
    }

    this.hideCursor();
    this.renderFrame();

    if (this.timer) clearInterval(this.timer);
    this.timer = setInterval(() => {
      this.currentFrameIdx++;
      this.renderFrame();
    }, this.frameInterval);
  }

  completeTask(customText) {
    const text = customText || this.currentText;

    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }

    const check = `${this.colors.green}${this.colors.bold}${this.charCheck}${this.colors.reset}`;
    if (!this.isTTY || this.isCI) {
      this.stream.write(`${this.indent}${check} ${text}\n`);
      return;
    }

    // Replace the spinner with the static green checkmark in exact position and freeze line
    this.stream.write(`\r\x1b[K${this.indent}${check} ${text}\n`);
  }

  failTask(customText) {
    const text = customText || this.currentText;

    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }

    const cross = `${this.colors.red}${this.colors.bold}${this.charCross}${this.colors.reset}`;
    if (!this.isTTY || this.isCI) {
      this.stream.write(`${this.indent}${cross} ${text}\n`);
      return;
    }

    this.stream.write(`\r\x1b[K${this.indent}${cross} ${text}\n`);
  }

  /**
   * Pulse effect on the final Ready indicator:
   * Smoothly cycles between bright green and soft green before locking static.
   */
  async ready(message = 'Ready', pulseDuration = 320) {
    if (!this.isTTY || this.isCI) {
      const dot = `${this.colors.green}${this.colors.bold}${this.charDot}${this.colors.reset}`;
      this.stream.write(`\n${this.indent}${dot} ${message}\n\n`);
      this.showCursor();
      return;
    }

    const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
    const pulseColors = [
      this.colors.green,
      this.colors.cyan,
      this.colors.green
    ];

    this.stream.write('\n');
    for (const col of pulseColors) {
      const dot = `${col}${this.colors.bold}${this.charDot}${this.colors.reset}`;
      this.stream.write(`\r\x1b[K${this.indent}${dot} ${this.colors.bold}${message}${this.colors.reset}`);
      await sleep(Math.round(pulseDuration / pulseColors.length));
    }

    const finalDot = `${this.colors.green}${this.colors.bold}${this.charDot}${this.colors.reset}`;
    this.stream.write(`\r\x1b[K${this.indent}${finalDot} ${message}\n\n`);
    this.showCursor();
  }
}

/**
 * Standard 4-step initialization sequence with Morph Animation.
 */
async function runMorphIntro(options = {}) {
  const spinner = new MorphSpinner(options);

  if (spinner.isCI) {
    spinner.cleanup();
    return;
  }

  const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

  const steps = [
    { text: 'Detecting terminal environment', duration: 320 },
    { text: 'Initializing developer profile', duration: 340 },
    { text: 'Verifying cloud & devops registry', duration: 380 },
    { text: 'Rendering developer identity card', duration: 320 }
  ];

  process.stdout.write('\n');

  for (const step of steps) {
    spinner.startTask(step.text);
    await sleep(step.duration);
    spinner.completeTask(step.text);
    await sleep(50);
  }

  await spinner.ready('Ready', 350);
  await sleep(200);

  spinner.cleanup();
}

if (require.main === module) {
  runMorphIntro().catch((err) => {
    process.stderr.write(`${err.message}\n`);
    process.exit(1);
  });
}

module.exports = {
  MorphSpinner,
  runMorphIntro
};
