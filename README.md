# cx — codex account switcher

Switch between several Codex CLI accounts. Run `cx` and it picks the next
account in rotation, or shows a menu when you have more than one.

Each account is a separate `CODEX_HOME` under `~/.codex-accounts/<name>/` with
its own `auth.json`, so logins don't step on each other. Config, skills and
rules are symlinked back to your normal `~/.codex`, so you still edit them in
one place.

## Install

```bash
git clone git@github.com:incadawr/codex-switch.git
cd codex-switch
./install.sh
```

`install.sh` links `bin/cx` into a directory on your `PATH` and, if you're
already logged into `~/.codex`, adopts that login as an account called
`personal`. Updating later is just `git pull` — the link points at the repo.

Tokens never go into git. They stay in `~/.codex-accounts/`, which is outside
the repo and listed in `.gitignore`.

## Usage

```bash
cx                  # rotate to the next account (menu + 5s auto-pick when >1 account)
cx --use work       # use a specific account
cx app [name]       # launch the Codex desktop app on an account
cx --list           # list accounts, marks the last one used
cx login work       # add an account: creates its home, links config, runs codex login
cx --help
```

Extra arguments go straight to `codex`, e.g. `cx exec "..."`. With one account
the menu is skipped.

## Desktop app

The desktop app reads `CODEX_HOME` too, but a GUI launch from the Dock ignores
the shell environment, so it always uses the default `~/.codex`. `cx app` works
around that: it quits the running app and relaunches it with `CODEX_HOME` set to
the chosen account. Because the app is single-instance, switching accounts means
restarting it — which is what `cx app` does. Pass a name or let it pick the next
account in rotation. macOS only.

## Adding an account

```bash
cx login work       # log into the second account in a browser
cx                  # now rotates between personal and work
```

## Settings

Override with environment variables:

- `CODEX_ACCOUNTS_ROOT` — where account homes live (default `~/.codex-accounts`)
- `CODEX_SHARED_HOME` — source of shared config/skills/rules (default `~/.codex`)
- `CX_AUTO_SECONDS` — menu countdown before auto-pick (default `5`)

## Uninstall

```bash
./uninstall.sh           # remove the cx link, keep accounts
./uninstall.sh --purge   # also delete ~/.codex-accounts
```

Needs `codex` on `PATH` and bash (works with the bash 3.2 that ships on macOS).
