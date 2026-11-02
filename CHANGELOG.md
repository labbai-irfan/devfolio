# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed
- Scrolling the mouse wheel no longer moves the menu selection or repaints the screen. The wheel now scrolls long pages.
- Arrow keys no longer wrap around to Quit; on menus without Quit, every item can be reached with up/down.
- Main screen repaints about 40x faster (459 ms to 11 ms on Git Bash) and without flicker or leftover characters.
- Wrapped paragraphs keep their color and indent (About, GitHub, Resume, timeline).
- Live GitHub stats work again (a jq sort error made every live fetch fall back to the snapshot).
- The GitHub screen no longer shows invented fallback numbers; self-reported numbers from `profile.json` are labelled as such.
- `npm run build` now produces every field the UI uses; the duplicate `scripts/build.js` is gone.
- The resume save path is shown correctly on macOS and Linux; a failed download no longer risks ending the app.
- ASCII fallbacks for every symbol in `--plain` mode, and the static card fits narrow terminals.
- Terminal resizes are applied immediately.

### Added
- Pipeline section: the real build, test and release pipeline of this CLI, and how its interface works.
- Project browser: pick a project for its details and open its repository; the tag filter is back.
- Contact shows each value next to its action; copy email and copy portfolio URL are back.
- `--json` (was documented but not implemented) and `LABBAI_REDUCED_MOTION=1`.
- The GitHub snapshot is generated from the API by `scripts/build.sh`, with its date.
- `npm test` smoke tests, also run in CI.

### Changed
- The Portfolio screen is merged into Contact (it repeated the same link); the main menu has 7 sections.
- The start-up intro is a short typed `whoami` (about 0.3 s) instead of a two-second fake progress sequence.
- Skills are shown as one wrapped line per category; the card focus row comes from `profile.json` (`focus`).
- Every screen uses the same key-hint footer.
- The CI package-size limit is 100 KB (was 60 KB).

## [0.0.1]

- Bash entry point with `--help`, `--version`, `--card`, `--plain`, `--no-color` and `--interactive`.
- Profile data kept in JSON, validated and compiled for Bash by `scripts/build.sh`.
- Developer card and single-key menus, with colors that respect `NO_COLOR` and non-terminal output.
- Sections: About, Skills, Projects, Career (Experience, Education, Certifications, Timeline), GitHub, Contact, Resume, Portfolio.
- Actions: open links, send email, open WhatsApp, copy email and portfolio URL, download and open the resume.
- GitHub public stats (live, with a build-time snapshot as fallback), project tag filter, QR code and `mono` theme.
- Node launcher for `npx labbai-irfan`, with Git Bash detection on Windows.
