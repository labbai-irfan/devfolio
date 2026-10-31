'use strict';

/**
 * Signal Scanner Animation Engine
 * Engineered loading indicator for the `labbai-irfan` developer CLI.
 * 
 * Features:
 * - Signal scanner indicator: ▰▱▱▱▱ -> ▱▰▱▱▱ -> ▱▱▰▱▱ -> ▱▱▱▰▱ -> ▱▱▱▱▰
 * - Electric cyan/blue active scanning beam with subtle dim gray inactive segments
 * - Atomic rendering with \r\x1b[K to eliminate cursor artifacts and terminal flicker
 * - Static green ✔ indicators upon task completion (no replaying)
 * - Full support for NO_COLOR, CI, non-TTY, reduced-motion, and terminal resize
 * - Clean Ctrl+C / SIGINT signal management ensuring cursor is always restored
 */

class SignalScanner {
  constructor(options = {}) {
    this.stream = options.stream || process.stdout;
    this.segments = options.segments || 5;
    this.interval = options.interval || 75; // 75ms for sleek, intentional scanning
    this.indent = options.indent || '   ';

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

    // UTF-8 detection: UTF-8 is supported in all modern terminals unless explicitly disabled
    this.isUTF8 = options.utf8 !== undefined ? options.utf8 : (
      !process.argv.includes('--plain') &&
      process.env.LC_ALL !== 'C' &&
      process.env.LANG !== 'C'
    );

    // Scanner glyphs
    this.charActive = this.isUTF8 ? '▰' : '=';
    this.charInactive = this.isUTF8 ? '▱' : '-';
    this.charCheck = this.isUTF8 ? '✔' : 'OK';
    this.charDot = this.isUTF8 ? '●' : '*';

    // Color palette: Electric blue/cyan active, dim gray inactive, vibrant green check
    this.colors = {
      active: this.noColor ? '' : '\x1b[38;5;39m', // electric cyan/blue
      inactive: this.noColor ? '' : '\x1b[90m',    // dim gray
      check: this.noColor ? '' : '\x1b[32m',       // green
      white: this.noColor ? '' : '\x1b[37m',       // clean white
      dim: this.noColor ? '' : '\x1b[90m',         // subtle muted text
      bold: this.noColor ? '' : '\x1b[1m',
      reset: this.noColor ? '' : '\x1b[0m'
    };

    // State
    this.timer = null;
    this.currentPosition = 0;
    this.direction = 1;
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

    // Handle terminal resize gracefully
    if (this.isTTY && this.stream.on) {
      this._onResize = () => {
        if (this.timer && this.currentText) {
          this.renderActiveFrame();
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

  /**
   * Generates a 5-segment scanning frame.
   */
  getScannerFrame() {
    let frame = '';
    for (let i = 0; i < this.segments; i++) {
      if (i === this.currentPosition) {
        frame += `${this.colors.active}${this.charActive}${this.colors.reset}`;
      } else {
        frame += `${this.colors.inactive}${this.charInactive}${this.colors.reset}`;
      }
    }
    return frame;
  }

  /**
   * Starts scanning for an ongoing task.
   */
  startTask(text) {
    this.currentText = text;
    this.currentPosition = 0;
    this.direction = 1;

    // Non-interactive or CI environments: skip animation frames
    if (!this.isTTY || this.isCI) {
      return;
    }

    this.hideCursor();

    // Render initial frame immediately
    this.renderActiveFrame();

    if (this.timer) clearInterval(this.timer);
    this.timer = setInterval(() => {
      // Smooth scanning radar sweep
      this.currentPosition += this.direction;
      if (this.currentPosition >= this.segments - 1) {
        this.currentPosition = this.segments - 1;
        this.direction = -1;
      } else if (this.currentPosition <= 0) {
        this.currentPosition = 0;
        this.direction = 1;
      }

      this.renderActiveFrame();
    }, this.interval);
  }

  renderActiveFrame() {
    const scanner = this.getScannerFrame();
    // Fixed layout: Indent + 5-char scanner + 2 spaces + text...
    const line = `${this.indent}${scanner}  ${this.colors.dim}${this.currentText}...${this.colors.reset}`;
    this.stream.write(`\r\x1b[K${line}`);
  }

  /**
   * Completes the task: transforms the scanner into a green check and locks the static line.
   */
  completeTask(customText) {
    const text = customText || this.currentText;

    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }

    if (!this.isTTY || this.isCI) {
      const checkBadge = `${this.colors.check}${this.charCheck}${this.colors.reset}`;
      this.stream.write(`${this.indent}${checkBadge} ${this.colors.white}${text}${this.colors.reset}\n`);
      return;
    }

    const checkBadge = `${this.colors.check}${this.colors.bold}${this.charCheck}${this.colors.reset}`;
    const completedLine = `\r\x1b[K${this.indent}${checkBadge} ${this.colors.white}${text}${this.colors.reset}\n`;
    this.stream.write(completedLine);
  }

  /**
   * Displays the final Ready confirmation status.
   */
  ready(message = 'Ready') {
    this.showCursor();
    const dot = `${this.colors.check}${this.colors.bold}${this.charDot}${this.colors.reset}`;
    this.stream.write(`\n${this.indent}${dot} ${this.colors.white}${this.colors.bold}${message}${this.colors.reset}\n\n`);
  }
}

/**
 * Standard 4-step initialization sequence for labbai-irfan.
 */
async function runIntroAnimation(options = {}) {
  const scanner = new SignalScanner(options);

  if (scanner.isCI) {
    scanner.cleanup();
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
    scanner.startTask(step.text);
    await sleep(step.duration);
    scanner.completeTask(step.text);
    await sleep(40);
  }

  scanner.ready('Ready');
  await sleep(250);

  scanner.cleanup();
}

// Standalone execution support
if (require.main === module) {
  runIntroAnimation().catch((err) => {
    process.stderr.write(`${err.message}\n`);
    process.exit(1);
  });
}

module.exports = {
  SignalScanner,
  runIntroAnimation
};
