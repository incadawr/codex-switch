# cx — codex account switcher

Switch between several Codex CLI accounts. Run `cx` and it picks the next
account in rotation, or shows a menu when you have more than one.

Each account is a separate `CODEX_HOME` under `~/.codex-accounts/<name>/` with
its own `auth.json`, so logins don't step on each other. Config, skills, rules
and session history are symlinked back to your normal `~/.codex`, so you still
edit config in one place, and `codex resume`/`fork` see every account's
sessions no matter which account you're currently running as — e.g.
`cx resume --last` or `cx resume <session-id>` picks up a session started
under any account. (If an account already had its own session history before
sessions became shared, `cx` merges it into the shared store the next time
that account is used, instead of discarding it.)

## Install

```bash
git clone git@github.com:incadawr/codex-switch.git
cd codex-switch
./install.sh
```

`install.sh` links `bin/cx` into a directory on your `PATH` and, if you're
already logged into `~/.codex`, adopts that login as an account called
`personal`. `personal` is a symlink to `~/.codex` (not a copy), so it shares the
same `auth.json` as bare `codex`, the desktop app, and any tooling that uses the
default home — the token never drifts when one of them refreshes it. Updating
later is just `git pull` — the link points at the repo.

Tokens never go into git. They stay in `~/.codex-accounts/`, which is outside
the repo and listed in `.gitignore`.

## Usage

```bash
cx                  # rotate to next account (↑/↓ menu + 5s auto-pick when >1 account)
cx --use work       # use a specific account
cx app [name]       # launch the Codex desktop app on an account
cx --list           # list accounts, marks the last one used
cx login work       # add an account: creates its home, links config, runs codex login
                    #   (defaults to `codex login --device-auth`)
cx --help
```

Extra arguments go straight to `codex`, e.g. `cx exec "..."`. With one account
the menu is skipped.

## Desktop app

The desktop app reads `CODEX_HOME` too, but a GUI launch from the Dock ignores
the shell environment, so it always uses the default `~/.codex`. `cx app` works
around that: it quits the running app and relaunches it with `CODEX_HOME` set to
the chosen account. It auto-detects both the standalone `Codex.app` and the
Codex experience bundled in `ChatGPT.app`; override the bundle with `CODEX_APP`
when needed. Because the app is single-instance, switching accounts means
restarting it — which is what `cx app` does. Pass a name or let it pick the next
account in rotation. macOS only.

## Adding an account

```bash
cx login work               # device-auth flow (default): shows a code + URL
cx                          # now rotates between personal and work
```

`cx login` defaults to `codex login --device-auth`, which works over SSH /
headless boxes since it doesn't need a local browser. Override the method by
passing codex-login args through verbatim, or use the `browser` keyword for the
bare ChatGPT browser flow:

```bash
cx login work browser                       # ChatGPT browser login
printenv OPENAI_API_KEY | cx login work --with-api-key
```

## Custom-endpoint accounts (API key, no ChatGPT login)

An account doesn't have to be a ChatGPT login. To point one at any
OpenAI-Chat/Responses-API-compatible gateway (e.g. a company-internal proxy)
by API key instead:

```bash
mkdir -p ~/.codex-accounts/work-gw
echo "config.toml" > ~/.codex-accounts/work-gw/.cx-private   # keep this account off the shared config.toml

cat > ~/.codex-accounts/work-gw/config.toml <<'EOF'
model_provider = "work_gw"
model = "some-model-id"

[model_providers.work_gw]
name = "Work Gateway"
base_url = "https://gateway.example.com/v1"
env_key = "WORK_GW_API_KEY"   # codex reads the key from this env var at launch
wire_api = "responses"         # use "responses" — codex no longer speaks plain chat/completions;
                                # most gateways (LiteLLM etc.) expose /v1/responses too
EOF

cat > ~/.codex-accounts/work-gw/env.sh <<'EOF'
export WORK_GW_API_KEY=sk-...
EOF
chmod 600 ~/.codex-accounts/work-gw/env.sh

cx --use work-gw
```

`.cx-private` lists (space-separated) which shared items this account keeps
private instead of symlinking from `~/.codex` — here just `config.toml`, so
skills/rules/sessions still stay shared. `env.sh`, if present, is sourced
right before `codex` runs, so the key never touches `config.toml` or git.
Switch models per call with `-m <model-id>` (`cx --use work-gw -m other-model`).

Custom model aliases usually aren't in codex's own `/model` picker (it only
knows OpenAI's catalog), so `cx` has its own: list the account's models, one
per line, first = default, in `.cx-models`, and `cx` shows the same
arrow-key/auto-select menu it uses for accounts before launching — skipped
if you already passed `-m`/`--model`/`-c model=...` yourself.

```bash
cat > ~/.codex-accounts/work-gw/.cx-models <<'EOF'
default-model-id
fast-model-id
planning-model-id
EOF

cx --use work-gw            # menu: pick a model, auto-selects the first after 5s
cx --use work-gw -m other   # skips the menu, uses `other` directly
```

To print a post-run token cache summary for an account, create an empty
`.cx-token-cache-summary` file in that account home. After Codex exits, `cx`
reads the latest rollout and prints cached input tokens plus a cache hit rate
when the provider returned those usage fields. The summary follows Codex's
final usage accounting: cached input is shown separately and excluded from the
visible `input`/`total` numbers.

If `codex` on your `PATH` is itself a wrapper (e.g. one that routes traffic
through an SSH-tunneled proxy) and this account should bypass it — an
internal-network endpoint has no business going out over that tunnel — set
`CX_CODEX_BIN` in `env.sh` to the real binary instead:

```bash
echo 'export CX_CODEX_BIN=/opt/homebrew/bin/codex' >> ~/.codex-accounts/work-gw/env.sh
```

### Resuming across providers

Sessions are shared between accounts, but Codex reasoning items can contain
provider-bound encrypted content. When `resume` or `fork` targets a session
created by a different provider, `cx` now selects the session before Codex
starts and creates a provider-compatible copy automatically. The copy keeps
messages and tool history, omits encrypted reasoning items, and leaves the
original session unchanged. Repeated resumes reuse the same converted copy.

This works both with an explicit session UUID and with the `cx` session picker:

```bash
cx --use work-gw resume <session-id>
cx --use personal resume
cx --use personal resume --last
```

Converted-session mappings live in
`~/.codex-accounts/.session-conversions`; converted rollouts and their index
rows live alongside the normal shared Codex history. Cross-provider conversion
requires `jq`, `sqlite3`, and `uuidgen`.

## Settings

Override with environment variables:

- `CODEX_ACCOUNTS_ROOT` — where account homes live (default `~/.codex-accounts`)
- `CODEX_SHARED_HOME` — source of shared config/skills/rules/sessions (default `~/.codex`)
- `CX_AUTO_SECONDS` — menu countdown before auto-pick (default `5`)

## Uninstall

```bash
./uninstall.sh           # remove the cx link, keep accounts
./uninstall.sh --purge   # also delete ~/.codex-accounts
```

Needs `codex` on `PATH` and bash (works with the bash 3.2 that ships on macOS).
