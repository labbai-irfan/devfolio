# Security

## What `npx labbai-irfan` does on your machine

- **No dependencies.** The package installs nothing besides its own files.
- **No install scripts.** Nothing runs when it's downloaded; code runs only when you start it.
- **Reads nothing of yours.** It doesn't touch your project, files, environment secrets, databases or git config.
- **Writes one file, only when asked:** the resume PDF when you choose *Download*, and it never overwrites an existing file. Its only other writes are short-lived files in your temp folder, removed on exit.
- **Network:** only the public GitHub API (when you open the GitHub section) and the resume URL (when you download it). No tracking or analytics. `LABBAI_OFFLINE=1` turns the network off.
- **Opens links only when you press a key** for it, using your system's browser.

CI enforces the first two rules, and every release is published from GitHub Actions with npm provenance, so you can check that a version was built from this repository:

```bash
npm view labbai-irfan dist.attestations
```

The npm page also shows a **Provenance** badge linking to the exact commit and workflow run.

## Automated checks

| Check | Runs |
|---|---|
| Dependabot (GitHub Actions and npm updates) | weekly |
| CodeQL (JavaScript and workflows, security-extended queries) | every push, pull request, and weekly |
| `npm audit` and a no-dependencies/no-install-scripts guard | every push and pull request |
| ShellCheck on all Bash code | every push and pull request |

## Reporting a vulnerability

Please don't open a public issue. Use **[Report a vulnerability](https://github.com/labbai-irfan/devfolio/security/advisories/new)** on GitHub (private), or email labbaiirfan09@gmail.com. I'll reply within 7 days. Only the latest version receives fixes.
