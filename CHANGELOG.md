# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-11-02

First public release.

### Added
- `npx labbai-irfan` opens an interactive developer card. When output is piped or `--card` is used, it prints a static card.
- Eight sections, ordered as a story: About, Career, Skills, Projects, GitHub, Resume, Contact and Pipeline.
- **About:** current role, location, availability, focus areas and profile.
- **Career:** experience, education, certifications and a vertical timeline.
- **Skills:** grouped by area, with skills used in listed projects highlighted.
- **Projects:** a browsable list with details, stack, status, repository link, previous/next and a tag filter.
- **GitHub:** public stats, languages and top repositories, live from the GitHub API with a dated snapshot as offline fallback. Self-reported numbers are labelled as such.
- **Resume:** download the PDF (never overwrites an existing file) or open it online.
- **Contact:** email, LinkedIn, GitHub and portfolio, each opened or copied in one key. Empty channels are hidden.
- **Pipeline:** how this CLI is built, tested and released.
- Keyboard and mouse: number keys, arrow keys and Enter, mouse-wheel scrolling, Space/PgUp/PgDn/Home/End, and `b`/Esc/`q`.
- Options: `--card`, `--json`, `--plain`, `--no-color`, `--theme mono`, `--no-animation` and `--interactive`. Environment: `NO_COLOR`, `LABBAI_THEME`, `LABBAI_OFFLINE`, `LABBAI_REDUCED_MOTION` and `LABBAI_DEBUG`.
- Works with Bash 3.2+ on Linux, macOS and Windows (Git Bash or WSL), in UTF-8 or plain ASCII, at any width down to 30 columns, and adapts when the terminal is resized.
- Profile data kept in JSON, validated, and compiled for Bash at build time, so visitors don't need `jq`.
- CI: syntax check, ShellCheck, data validation, smoke tests, and package checks on Linux, macOS and Windows. Releases are published from git tags with npm provenance.

[Unreleased]: https://github.com/labbai-irfan/devfolio/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/labbai-irfan/devfolio/releases/tag/v0.1.0
