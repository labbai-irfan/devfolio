# shellcheck shell=bash
# Sources every module in dependency order (lib → core → ui → services → commands), then runs the app.

# shellcheck source=lib/log.sh
source "$APP_ROOT/src/lib/log.sh"
# shellcheck source=lib/term.sh
source "$APP_ROOT/src/lib/term.sh"
# shellcheck source=lib/colors.sh
source "$APP_ROOT/src/lib/colors.sh"
# shellcheck source=lib/validate.sh
source "$APP_ROOT/src/lib/validate.sh"

# shellcheck source=core/config.sh
source "$APP_ROOT/src/core/config.sh"
# shellcheck source=core/args.sh
source "$APP_ROOT/src/core/args.sh"
# shellcheck source=core/platform.sh
source "$APP_ROOT/src/core/platform.sh"

# shellcheck source=ui/layout.sh
source "$APP_ROOT/src/ui/layout.sh"
# shellcheck source=ui/menu.sh
source "$APP_ROOT/src/ui/menu.sh"
# shellcheck source=ui/card.sh
source "$APP_ROOT/src/ui/card.sh"
# shellcheck source=ui/intro.sh
source "$APP_ROOT/src/ui/intro.sh"

# shellcheck source=services/browser.sh
source "$APP_ROOT/src/services/browser.sh"
# shellcheck source=services/clipboard.sh
source "$APP_ROOT/src/services/clipboard.sh"
# shellcheck source=services/download.sh
source "$APP_ROOT/src/services/download.sh"
# shellcheck source=services/github_api.sh
source "$APP_ROOT/src/services/github_api.sh"

# shellcheck source=commands/actions.sh
source "$APP_ROOT/src/commands/actions.sh"
# shellcheck source=commands/about.sh
source "$APP_ROOT/src/commands/about.sh"
# shellcheck source=commands/skills.sh
source "$APP_ROOT/src/commands/skills.sh"
# shellcheck source=commands/projects.sh
source "$APP_ROOT/src/commands/projects.sh"
# shellcheck source=commands/career.sh
source "$APP_ROOT/src/commands/career.sh"
# shellcheck source=commands/contact.sh
source "$APP_ROOT/src/commands/contact.sh"
# shellcheck source=commands/resume.sh
source "$APP_ROOT/src/commands/resume.sh"
# shellcheck source=commands/github.sh
source "$APP_ROOT/src/commands/github.sh"
# shellcheck source=commands/portfolio.sh
source "$APP_ROOT/src/commands/portfolio.sh"
# shellcheck source=commands/export.sh
source "$APP_ROOT/src/commands/export.sh"

# shellcheck source=core/app.sh
source "$APP_ROOT/src/core/app.sh"

app_run "$@"
