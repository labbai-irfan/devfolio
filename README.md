# Labbai Irfan CLI

An interactive developer card for your terminal. Run it, and a short card appears with who I am, what I build, and how to get in touch.

```bash
npx labbai-irfan
```

Press a number, or use the arrow keys and Enter, to open About, Skills, Projects, Career, GitHub, Contact, Resume and Built With (how this CLI is engineered and released). Your portfolio link is under Contact. `b` or Esc goes back and `q` quits. On long pages, the arrow keys, the mouse wheel, Space/PgUp/PgDn and Home/End scroll.

The app captures the mouse so the wheel scrolls its pages instead of moving the menu. To select text with the mouse, hold Shift while dragging (Option on macOS).

> The package is not published to npm yet. Until it is, run it from a clone (see [DEVELOPMENT.md](docs/DEVELOPMENT.md)).

## Requirements

- **Node.js 18 or newer** (for `npx`). The app itself is Bash.
- **Bash 3.2 or newer.**
  - Linux and macOS: already installed.
  - Windows: [Git for Windows](https://gitforwindows.org) (its Git Bash), or WSL.
- **curl** (optional): needed for the resume download and live GitHub stats.

## Options

| Option | What it does |
|---|---|
| `--card` | Print the static card and exit. |
| `--json` | Print the whole profile as JSON and exit. |
| `--theme <name>` | `default` or `mono` (bold only, no colors). Also `LABBAI_THEME`. |
| `--plain` | No colors, no box drawing, plain ASCII. Good for screen readers. |
| `--no-color` | Turn off colors. Same as `NO_COLOR=1`. |
| `--interactive` | Run the menu even when output is not a terminal. |
| `--no-animation` | Skip animations (the short intro and loading spinners). |
| `-h`, `--help` | Show help. |
| `-v`, `--version` | Show version. |

When output is piped (`npx labbai-irfan | cat`), the app prints the static card instead of the menu.

## Environment variables

| Variable | Effect |
|---|---|
| `NO_COLOR` | Turn off colors. |
| `LABBAI_THEME` | Default theme. |
| `LABBAI_OFFLINE=1` | Never use the network. |
| `LABBAI_REDUCED_MOTION=1` | Same as `--no-animation`. |
| `LABBAI_DEBUG=1` | Print debug messages to stderr. |

## Platform notes

- **Linux:** opening links needs `xdg-open`. Copying needs `wl-copy` (Wayland) or `xclip` or `xsel` (X11).
- **macOS:** uses `open` and `pbcopy`.
- **Windows:** use Git Bash or WSL. Clipboard uses `clip.exe`.

If a tool is missing, the app shows the link or text so you can do it yourself.

## Documentation

- [DEVELOPMENT.md](docs/DEVELOPMENT.md): set up, build, update the profile, release.
- [ARCHITECTURE.md](docs/ARCHITECTURE.md): how the code is organised.
- [CONTRIBUTING.md](CONTRIBUTING.md): how to report issues and send changes.
- [CHANGELOG.md](CHANGELOG.md): what changed in each version.

## License

MIT. See [LICENSE](LICENSE).
