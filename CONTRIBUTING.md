# Contributing

Thanks for looking at this project. It's a small personal card, so changes should keep it small, fast and honest.

## Reporting a problem

Open an [issue](https://github.com/labbai-irfan/devfolio/issues) with:

- your operating system and terminal (for example, *Windows 11, VS Code terminal, Git Bash*),
- the exact command you ran,
- what you expected and what happened,
- the output with `LABBAI_DEBUG=1` set, if you can.

For layout problems, a screenshot and your terminal size help most.

## Sending a change

1. For anything larger than a small fix, open an issue first to agree on the approach.
2. Keep each pull request to one change.
3. Run the checks below. They must all pass.
4. Add a line to `CHANGELOG.md` under `## [Unreleased]` for anything a visitor would notice.
5. In the pull request, say what changed and how you checked it.

### Checks

```bash
npm run validate                               # profile data
npm run build                                  # compile src/data/*.json
npm test                                       # smoke tests: every screen, widths, modes, keys
shellcheck bin/labbai-irfan scripts/*.sh src/*/*.sh
```

For a UI change, also look at it by hand. Run `npm start`, then narrow the terminal window to about 40 columns (the screen re-lays itself out as you resize), and try plain mode with `npm start -- --plain`.

### Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): summary` in the imperative, lower case, under about 70 characters.

```
feat(projects): add previous/next navigation
fix(input): ignore mouse events that arrive in pieces
docs: explain the release steps
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.

## Coding standards

**Compatibility**
- Bash 3.2 compatible. No associative arrays, `mapfile`, `${var,,}`, `&>>` or fractional `read -t` without a fallback.
- No new runtime dependencies. Bash is the app, Node is only the `npx` launcher, and `curl` is optional.

**Safety**
- The app runs with `set -euo pipefail` and an ERR trap. A function whose last command is a failed test (`[[ … ]] && x`) returns non-zero and stops the app, so end such functions with `return 0`.
- Quote every expansion. Use `printf`, not `echo -e`.
- Pass any text from the network through `validate_sanitize` before printing it.
- ShellCheck clean. Any `# shellcheck disable=` needs a comment that says why.

**User interface**
- Build screens from the helpers in `src/ui/layout.sh` and `src/ui/menu.sh` (`layout_kv`, `layout_list`, `layout_wrap`, `menu_items`, `section_view`), so every screen looks and behaves the same.
- Use the glyph variables (`ICON_DOT`, `ICON_BULLET`, `KEYS_ARROWS`, …), never raw Unicode, so `--plain` stays ASCII.
- Nothing may overflow the terminal width: wrap or truncate.
- Keep render functions free of subshells and external commands. They run on every keypress.
- Keep menu labels short. Main-menu sections are a single word.

**Content**
- Personal information belongs in `src/data/*.json`, never in code.
- Never show invented numbers or placeholder data. When information is missing, hide it or say it's unavailable.
- Respect the layering in [ARCHITECTURE.md](docs/ARCHITECTURE.md): lower layers never call upper ones.

Please don't add features only to make the project look bigger. Ask first.
