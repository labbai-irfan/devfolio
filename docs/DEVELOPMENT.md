# Development

## Prerequisites

| Tool | Needed for | Required |
|---|---|---|
| Bash 3.2+ | running the app | yes |
| Node.js 18+ and npm | `npx` launcher, packing and publishing | yes |
| jq | building and validating the profile data | yes |
| ShellCheck | linting | yes (CI runs it too) |
| qrencode | QR code on the Portfolio screen | optional |
| curl | resume download, GitHub stats | optional at runtime |

On Windows, install [Git for Windows](https://gitforwindows.org) for Git Bash. Use Git Bash for every command below.

## Common commands

```bash
npm run build          # validate data, then compile it for Bash
npm run validate       # validate only
npm run start          # run the app (after a build)
npm run release:check  # pre-release gate (see Releasing)
shellcheck bin/labbai-irfan && find scripts src -name '*.sh' -exec shellcheck {} +
```

`npm run build` must run after any change to `src/data/*.json`. The app reads the generated files (profile.sh, github.sh, qr.txt), not the JSON.

## Updating the profile

1. Edit the JSON files in `src/data/`:

   | File | Holds |
   |---|---|
   | `profile.json` | name, title, tagline, about, location, links, contact, resume, GitHub username |
   | `skills.json` | skill categories and their items |
   | `projects.json` | projects, with name, description, tags and URL |
   | `experience.json` | jobs, with dates and highlights |
   | `education.json` | degrees |
   | `certifications.json` | certifications, with optional verify links |

2. Run `npm run build`. Fix any errors it reports.
3. Run `npm run start` and check the screens you changed.

Dates are `YYYY`, `YYYY-MM`, or `present`. Links must start with `https://`. WhatsApp is the country code followed by digits only, with no `+` or spaces.

Put only information you are happy to make public in these files. The package ships them in readable form.

## Adding a section or action

- A new read-only screen goes in `src/commands/<name>.sh` and uses `section_view` (or `menu_loop` if it has keys).
- Add it to the main menu in `src/core/app.sh` (`app_main_render` and `app_main_handle`).
- Add the new file to the `source` list in `src/main.sh`, in dependency order.
- Browser, clipboard and network work goes in `src/services/` and returns a status code. Commands turn that code into the message shown to the user.

## Releasing

1. Move the items under `## [Unreleased]` in `CHANGELOG.md` to a new `## [x.y.z]` section.
2. Set the same version in `package.json`.
3. Commit, then run `npm run release:check`. It must pass.
4. Tag and push: `git tag vx.y.z && git push --follow-tags`.

The `release.yml` workflow then runs the checks and publishes to npm (`latest`, or `next` for pre-releases). It also creates the GitHub release. It needs an `NPM_TOKEN` repository secret.

## Known gaps

- `npm test` runs `scripts/smoke-test.sh`: the static card at five widths (ASCII and no-color modes), the flags, a scripted walk through every interactive screen, and checks that the mouse wheel and arrow keys never jump the selection to Quit. CI runs it along with ShellCheck, syntax checks, data validation and the package smoke test.
- The app has not been run on every target platform yet. The manual checklist in the plan (§16.2) is still open.
