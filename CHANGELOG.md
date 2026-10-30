# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.0.1]

- Bash entry point with `--help`, `--version`, `--card`, `--plain`, `--no-color` and `--interactive`.
- Profile data kept in JSON, validated and compiled for Bash by `scripts/build.sh`.
- Developer card and single-key menus, with colors that respect `NO_COLOR` and non-terminal output.
- Sections: About, Skills, Projects, Career (Experience, Education, Certifications, Timeline), GitHub, Contact, Resume, Portfolio.
- Actions: open links, send email, open WhatsApp, copy email and portfolio URL, download and open the resume.
- GitHub public stats (live, with a build-time snapshot as fallback), project tag filter, QR code and `mono` theme.
- Node launcher for `npx labbai-irfan`, with Git Bash detection on Windows.
