# Architecture

The application is Bash. Node.js is used only by the `npx` launcher. Personal information lives in JSON files and is compiled into Bash variables at build time.

## Layers

```
bin/                entry points: Node launcher and Bash entry
src/main.sh         sources every module in order, then starts the app
src/core/           startup: flags, platform, config, main loop, cleanup
src/commands/       one file per menu section: what to show and which actions exist
src/ui/             drawing: card, layout, menus
src/services/       the outside world: browser, clipboard, download, GitHub
src/lib/            generic helpers: colors, logging, terminal, validation
src/data/           personal information (JSON) and the build output (profile.sh, github.sh, qr.txt)
```

**Dependency rule:** `core → commands → ui/services → lib`. Lower layers never call upper layers. `lib/` has no knowledge of this profile, so it could be reused elsewhere.

Services return status codes and never call `exit`. Commands turn those codes into messages, and the UI draws them.

## Startup

1. `npx labbai-irfan` runs `bin/labbai-irfan.js`. It finds Bash (on Windows, Git Bash, skipping WSL's `System32\bash.exe`) and starts `bin/labbai-irfan` with your arguments.
2. `bin/labbai-irfan` follows symlinks to find the install directory, checks the Bash version, and sources `src/main.sh`.
3. `src/main.sh` sources all modules, then calls `app_run`.
4. `app_run` reads flags, detects the platform, sets up colors and layout, and loads `src/data/profile.sh`. If that file is missing, it exits with code 3 and says to run the build.
5. It picks a mode:
   - `--card`, or output is not a terminal: print the static card and exit.
   - Otherwise: start the interactive menu.

## Interactive loop

`menu_loop` in `ui/menu.sh` renders the screen, reads one key, and either moves the selection (arrows) or passes the key to a handler (number/letter keys, or Enter on the selected item). `q` quits from anywhere, and `b`/Esc returns to the previous screen. Each submenu is a `menu_loop` of its own and restores the parent selection on return. Read-only sections use `section_view`, which scrolls by line (arrows, mouse wheel) or by page (Space, PgUp/PgDn).

Every frame is rendered into a temp-file buffer and written in one go (`screen_paint`), so repaints do not flicker. Arrow-only redraws are skipped while more keys are already queued, so a burst of keys costs one repaint. The terminal is put in the alternate screen with SGR mouse reporting on: the mouse wheel then arrives as a mouse event (scrolls pages, ignored in menus) instead of being turned into arrow keys by the terminal. A resize (`SIGWINCH`) interrupts the key read and re-lays the screen out.

A handler sets `MENU_DONE` when it wants to leave its screen. Only the project tag picker does this today.

## Data pipeline

```
src/data/*.json ──validate-data.sh──► checks
        │
        └──build.sh──► profile.sh     (Bash variables, values escaped with @sh)
                   ├─► github.sh      (GitHub snapshot, best effort)
                   └─► qr.txt         (only if qrencode is installed)
```

Lists are stored as parallel indexed arrays, such as `PROJECT_NAME[i]`. Fields with several values (tags, highlights) are joined with `|` and split when drawn. Bash 3.2 has no associative arrays, so none are used.

The career timeline is not a separate file. The build merges the dated entries from experience, education and certifications.

## GitHub stats

`services/github_api.sh` makes two unauthenticated requests: the user and their repos. It turns the results into `GH_*` variables using `jq` with `@sh`, so the output is always safe to source.

Loading is decided in this order:
1. If `LABBAI_OFFLINE=1`, or `curl` or `jq` is missing, skip the network.
2. Otherwise fetch live once per session.
3. If that fails, use the snapshot from the last build and show its date and the reason.

Nothing is fetched until the GitHub section is opened.

## Terminal safety

- Text from remote sources (GitHub repo names and descriptions) passes through `validate_sanitize`, which removes escape sequences and control characters before printing.
- `trap app_cleanup EXIT` restores the cursor on every exit path. Ctrl+C exits with code 130.
- An unexpected error (`set -E` with an `ERR` trap) shows a short message instead of a raw Bash error.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Success, or normal quit |
| 1 | Unexpected error |
| 2 | Bad usage (unknown flag or value) |
| 3 | Missing dependency or unbuilt data |
| 130 | Interrupted |
