# Contributing

Thanks for looking at this project. It is a small, personal card, so changes should keep it small.

## Reporting a problem

Open an issue with:
- your operating system and terminal (for example, Windows Terminal with Git Bash),
- the command you ran,
- what you expected and what happened,
- the output with `LABBAI_DEBUG=1` set, if you have it.

## Sending a change

1. Discuss larger changes in an issue first.
2. Keep each pull request to one change.
3. Run the checks in [DEVELOPMENT.md](docs/DEVELOPMENT.md): ShellCheck, the syntax check and `npm run validate`.
4. Describe what changed and how you checked it.

## Coding standards

- Bash 3.2 compatible. No associative arrays, `mapfile`, `${var,,}` or `&>>`.
- ShellCheck clean. Any `# shellcheck disable=` needs a comment that says why.
- Quote every expansion. Use `printf`, not `echo -e`.
- Keep personal information out of code. It belongs in `src/data/*.json`.
- Keep the dependency rule in [ARCHITECTURE.md](docs/ARCHITECTURE.md): lower layers never call upper layers.
- Add a `CHANGELOG.md` entry under `## [Unreleased]` for user-visible changes.

Please do not add features only to make the project look bigger. Ask first.
