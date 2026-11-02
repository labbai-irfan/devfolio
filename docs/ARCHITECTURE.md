# Architecture

The application is Bash. Node.js is used only by the `npx` launcher. Personal information lives in JSON files and is compiled into Bash variables at build time, so visitors need nothing but Bash.

## Layers

```
bin/                entry points: Node launcher (finds Bash) and Bash entry
src/main.sh         sources every module in order, then starts the app
src/core/           startup: flags, platform detection, config, main loop, cleanup
src/commands/       one file per section: what to show and which actions exist
src/ui/             drawing: layout primitives, menus, card, intro, spinner
src/services/       the outside world: browser, clipboard, download, GitHub API
src/lib/            generic helpers: colors, logging, terminal input, validation
src/data/           personal information (JSON) and the build output (profile.sh, github.sh)
scripts/            build, validation, smoke tests, release check, cross-platform npm runner
```

**Dependency rule:** `core → commands → ui/services → lib`. Lower layers never call upper layers. `lib/` knows nothing about this profile.

Services return status codes and never call `exit`. Commands turn those codes into messages, and the UI draws them.

## Startup

1. `npx labbai-irfan` runs `bin/labbai-irfan.js`. It finds Bash (on Windows, Git Bash, skipping WSL's `System32\bash.exe`) and starts `bin/labbai-irfan` with the same arguments. The npm scripts use the same lookup through `scripts/run-bash.js`.
2. `bin/labbai-irfan` follows symlinks to the install directory, checks the Bash version, turns on `set -euo pipefail`, and sources `src/main.sh`.
3. `app_run` reads the flags. `--help`, `--version` and `--json` answer immediately.
4. It detects the platform: OS, TTY, UTF-8 support, terminal size, and browser and clipboard tools. If the terminal is UTF-8 but the locale isn't (for example `npx` from PowerShell), it sets `LC_CTYPE=C.UTF-8` so Bash measures `●` as one character and box borders stay aligned.
5. It sets up colors and layout, then loads `src/data/profile.sh`. If that file is missing, it exits with code 3 and says to run the build.
6. It picks a mode:
   - `--card`, or output isn't a terminal: print the static card and exit.
   - Otherwise: alternate screen, a short intro, then the main menu.

## Screens and input

There are two kinds of screen, both in `ui/menu.sh`:

- **`menu_loop`**: a menu screen. The render function draws content and calls `menu_items`, which lays the items out in a two-column grid (one column if it wouldn't fit) and shows the selected item's `MENU_DETAILS` entry under it. Arrows move the selection, numbers and letters or Enter pick an item, and ←/→ that the grid can't use go to the handler (previous/next project). Each submenu is its own `menu_loop` and restores the parent's selection on return. A handler sets `MENU_DONE` to leave its screen; only the project tag picker does this.
- **`section_view`**: a read-only page that scrolls by line (arrows, mouse wheel) or by page (Space, PgUp/PgDn, Home/End).

`q` quits from anywhere, and `b`/Esc goes back.

**Rendering.** Every frame is rendered into a temp-file buffer and written in one go (`screen_paint`), clearing the end of each line and the rest of the screen. Repaints don't flicker or leave stray characters. Arrow-only redraws are skipped while more keys are queued, so a burst of keys costs one repaint. Render functions avoid subshells, so a repaint takes milliseconds even on Git Bash.

**Input.** `term_read_input` in `lib/term.sh` turns raw bytes into key names. The terminal is in the alternate screen with SGR mouse reporting on, so the wheel arrives as a mouse event rather than as fake arrow keys. Windows terminals can deliver one event in pieces, so the reader waits up to 0.5 s for the rest of an escape sequence and discards a stray `[` with its tail; otherwise digits in mouse coordinates would select menu items. A resize (`SIGWINCH`) interrupts the read and re-lays the screen out.

## Data pipeline

```
src/data/*.json ──validate-data.sh──► errors / warnings
        │
        └──build.sh──► profile.sh   (Bash variables, values escaped with jq @sh)
                  └──► github.sh    (GitHub API snapshot with its date; best effort)
```

Lists are stored as parallel indexed arrays, such as `PROJECT_NAME[i]`. Fields with several values (tags, highlights) are joined with `|` and split when drawn. Bash 3.2 has no associative arrays, so none are used. Missing optional fields compile to empty values, and nothing is invented.

The career timeline isn't a separate file: the build merges the dated entries from experience, education and certifications, newest first.

## GitHub data

`services/github_api.sh` makes two unauthenticated requests (the user and their repos, 5-second timeout) and turns them into `GH_*` variables with `jq @sh`, so the output is always safe to source.

Loading order, the first time the GitHub section is opened:
1. If `LABBAI_OFFLINE=1`, or `curl` or `jq` is missing, skip the network.
2. Otherwise fetch live, once per session.
3. If that fails, use the snapshot from the last build and show its date and the reason.

Only API data is shown as GitHub stats. Numbers from `profile.json` (`github_stats`) appear under a separate "Self-reported" heading.

## Terminal safety

- Text from GitHub (repository names and descriptions) passes through `validate_sanitize`, which removes escape sequences and control characters before printing.
- `trap app_cleanup EXIT` stops the spinner, leaves the alternate screen and restores the cursor on every exit path. Ctrl+C exits with code 130.
- An unexpected error (`set -E` with an `ERR` trap) shows a short message instead of a raw Bash error.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Success, or normal quit |
| 1 | Unexpected error |
| 2 | Bad usage (unknown flag or value) |
| 3 | Missing dependency or unbuilt data |
| 130 | Interrupted |
