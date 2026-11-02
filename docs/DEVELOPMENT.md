# Development

## Prerequisites

| Tool | Needed for | Required |
|---|---|---|
| Bash 3.2+ | running the app and every script | yes |
| Node.js 18+ and npm | the `npx` launcher, packing and publishing | yes |
| jq | validating and building the profile data | yes |
| ShellCheck | linting | yes for changes (CI runs it too) |
| curl | live GitHub data and the resume download | optional |

On Windows, install [Git for Windows](https://gitforwindows.org) for Git Bash. The `npm` scripts find Git Bash themselves, so they work from PowerShell or cmd too.

## Common commands

```bash
npm run build          # validate the data, then compile it for Bash (+ GitHub snapshot)
npm start              # run the app (after a build)
npm test               # smoke tests (after a build)
npm run validate       # validate the data only
npm run release:check  # pre-release gate (see Releasing)
shellcheck bin/labbai-irfan scripts/*.sh src/*/*.sh
```

The app reads the generated `src/data/profile.sh` and `src/data/github.sh`, not the JSON, so run `npm run build` after every change to `src/data/*.json`.

## Updating the profile

1. Edit the JSON files in `src/data/`:

   | File | Holds |
   |---|---|
   | `profile.json` | name, title, tagline, `about` paragraphs, `focus` areas (card footer and About), location, availability, links, contact, resume URLs, GitHub username, optional `github_stats` (shown as self-reported) |
   | `skills.json` | skill categories and their items |
   | `projects.json` | name, description, `tags`, `url`, and optional `category`, `status` (e.g. `In Production`, `Completed`) and `featured` (`true`/`false`) |
   | `experience.json` | jobs, with `start`/`end` dates and highlights (the first highlight appears on the timeline) |
   | `education.json` | degrees, with optional notes |
   | `certifications.json` | certifications, with an optional verification link |

2. Run `npm run build` and fix any errors it reports.
3. Run `npm start` and check the screens you changed. Then run `npm test`.

**Format rules:** dates are `YYYY`, `YYYY-MM` or `present`. Links must start with `https://`. WhatsApp is the country code followed by digits only, or `""` to hide it.

**How skills get highlighted:** a skill turns green when its name exactly matches a tag in `projects.json` (same spelling and capitals). To highlight a skill, add it to the tags of a project that really used it.

**Empty means hidden:** leave an optional field as `""` and the app hides it; it never shows a placeholder.

**Privacy:** everything in these files is published in readable form and can't be fully withdrawn once on npm. Only include what you're happy to make public.

## Adding a section or action

- A read-only screen goes in `src/commands/<name>.sh` and uses `section_view`. A screen with actions uses `menu_loop` with a render function (calling `menu_items` and `menu_prompt`) and a handler.
- Add it to the main menu in `src/core/app.sh` (`app_main_render` and `app_main_handle`), and to the `source` list in `src/main.sh`.
- Browser, clipboard and network work goes in `src/services/` and returns a status code; the command turns it into the message shown.
- Add the screen's key to the walk in `scripts/smoke-test.sh`, and follow the coding standards in [CONTRIBUTING.md](../CONTRIBUTING.md).

## Testing

`npm test` runs `scripts/smoke-test.sh`, which covers:

- the static card at 30–120 columns, in ASCII and no-color modes
- every flag
- a scripted walk through every interactive screen
- that the mouse wheel, split mouse events and arrow keys never move or trigger the menu by mistake

CI runs it on every push, along with syntax checks, ShellCheck, data validation, and a package build and run on Linux, macOS and Windows.

Manual checks are still worth doing for interface changes: a real terminal on Windows (Git Bash, PowerShell), macOS and Linux, at a narrow width and in `--plain` mode.

## Releasing

Versions follow [Semantic Versioning](https://semver.org/). The first public release is `0.1.0`.

1. In `CHANGELOG.md`, move the items under `## [Unreleased]` into a new `## [x.y.z] - YYYY-MM-DD` section.
2. Commit, then run `npm version x.y.z -m "chore(release): %s"`. It sets the version in `package.json`, commits it and creates the `vx.y.z` tag.
3. Run `npm run release:check`. It must end with `release-check: OK`.
4. Push: `git push --follow-tags`.

The `release.yml` workflow then runs CI, publishes to npm (`latest`, or `next` for versions with a dash such as `0.2.0-rc.1`), and creates the GitHub release from the changelog section. It uses npm **Trusted Publishing**, so there's no token to store or renew, and npm adds provenance automatically.

**The very first release** has to be published by hand, because Trusted Publishing can only be set up for a package that already exists: `npm login`, then `npm publish --access public`, then `git push --follow-tags`. Then, on npmjs.com, open the package → **Settings** → **Trusted Publisher** → **GitHub Actions**, and enter owner `labbai-irfan`, repository `devfolio`, workflow `release.yml`.
