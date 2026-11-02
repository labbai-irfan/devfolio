# labbai-irfan

[![CI](https://github.com/labbai-irfan/devfolio/actions/workflows/ci.yml/badge.svg)](https://github.com/labbai-irfan/devfolio/actions/workflows/ci.yml)
[![npm](https://img.shields.io/npm/v/labbai-irfan)](https://www.npmjs.com/package/labbai-irfan)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**My developer card, in your terminal.** One command shows who I am, what I've built and how to reach me. No install, no browser.

```bash
npx labbai-irfan
```

```
  ╭──────────────────────────────────────────────────────────────────────────╮
  │  Labbai Irfan                                                            │
  │  Software Engineer | Aspiring DevOps & Cloud Engineer                    │
  │  “Building, automating, deploying and scaling software.”                 │
  ├──────────────────────────────────────────────────────────────────────────┤
  │  LOCATION        Mumbai, India                                           │
  │  AVAILABILITY    ● Open to DevOps & Cloud Engineering opportunities      │
  ├──────────────────────────────────────────────────────────────────────────┤
  │  PORTFOLIO       labbaiirfan.vercel.app                                  │
  │  GITHUB          github.com/labbai-irfan                                 │
  │  LINKEDIN        www.linkedin.com/in/irfan-labbai                        │
  │  EMAIL           labbaiirfan09@gmail.com                                 │
  ├──────────────────────────────────────────────────────────────────────────┤
  │  SOFTWARE ENGINEERING  ·  DEVOPS  ·  CLOUD INFRASTRUCTURE                │
  ╰──────────────────────────────────────────────────────────────────────────╯
```

## What's inside

| # | Section | What you'll find |
|---|---|---|
| 1 | **About** | Current role, location, availability and a short profile |
| 2 | **Career** | Experience, education, certifications and a timeline |
| 3 | **Skills** | Skills by area; the ones used in my projects are highlighted |
| 4 | **Projects** | Each project's stack, status and repository link |
| 5 | **GitHub** | Public repositories and languages, live from the GitHub API |
| 6 | **Resume** | Download the PDF or open it in your browser |
| 7 | **Contact** | Email, LinkedIn, GitHub and portfolio: open or copy in one key |
| 8 | **Pipeline** | How this CLI itself is built, tested and released |

## Keys

| Key | Action |
|---|---|
| `1`–`8`, or arrows + `Enter` | Open a section |
| `↑` `↓`, mouse wheel, `Space`, `PgUp` / `PgDn` | Scroll long pages |
| `←` `→` | Previous / next project |
| `b` or `Esc` | Back |
| `q` | Quit |

The app uses the mouse wheel for scrolling, so to select text hold **Shift** while dragging (**Option** on macOS).

## Requirements

- **Node.js 18+** (for `npx`)
- **Bash 3.2+**: built into macOS and Linux. On Windows, install [Git for Windows](https://gitforwindows.org), which includes Git Bash; it works from PowerShell, cmd or Windows Terminal. WSL works too.
- **curl** (optional): for live GitHub data and the resume download

## Options

| Option | Effect |
|---|---|
| `--card` | Print the card and exit (also what happens when output is piped) |
| `--json` | Print the full profile as JSON |
| `--plain` | Plain ASCII: no colors or box drawing, good for screen readers |
| `--no-color` | No colors (same as `NO_COLOR=1`) |
| `--theme mono` | Bold instead of colors (or `LABBAI_THEME=mono`) |
| `--no-animation` | No intro or spinners (or `LABBAI_REDUCED_MOTION=1`) |
| `--interactive` | Use the menu even when output isn't a terminal |
| `-h`, `-v` | Help, version |

Environment variables: `LABBAI_OFFLINE=1` never uses the network, and `LABBAI_DEBUG=1` prints diagnostics to stderr.

## Privacy and network

The app only goes online when you open **GitHub** (public API, 5-second timeout) or **download the resume**. It sends no tracking or analytics. Offline, the GitHub screen falls back to a dated snapshot from the last release. Links open in your default browser, and if no browser or clipboard tool is found, the app shows the text so you can copy it yourself.

## Make your own

All the content lives in [`src/data/*.json`](src/data). To make a card of your own, fork the repo, edit the JSON, run `npm run build` and `npm test`, then publish under your own name. See [DEVELOPMENT.md](docs/DEVELOPMENT.md) for details.

## Documentation

- [DEVELOPMENT.md](docs/DEVELOPMENT.md): setup, updating the profile, testing and releasing
- [ARCHITECTURE.md](docs/ARCHITECTURE.md): how the code is organised
- [CONTRIBUTING.md](CONTRIBUTING.md): reporting issues and sending changes
- [CHANGELOG.md](CHANGELOG.md): what changed in each version

## License

[MIT](LICENSE) © Labbai Irfan
