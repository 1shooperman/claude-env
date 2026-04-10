# claudenv

Shell environment switcher for Claude Code accounts.

## Key constraints

- `install.sh` must stay POSIX sh — no arrays, no `select`, no process substitution.
- `claudenv.sh` targets bash 3.2+ and zsh 5+; arrays, `select`, and `< <(...)` are intentional.
- No external dependencies. No build step.

## GitHub Actions constraints

- **Do not pin actions to commit SHAs.** Use semver tags (e.g. `@v2`, `@v6`). Dependabot keeps tags current.
- **Do not replace apt-installed tools with pinned binary downloads** in `Dockerfile.dev` (e.g. shellcheck stays as `apt-get install shellcheck`).
- **Do not add update-type guards to `dependabot-automerge.yml`.** All dependabot PRs are auto-merged, not just patch bumps.

## Testing

```sh
source claudenv.sh
claudenv config test-env
claudenv test-env          # prompt should show (test-env)
claudenv deactivate
rm -rf "$CLAUDENV_HOME/envs/test-env"
```

Test oh-my-zsh prompt integration by sourcing in an active zsh session with a theme loaded.
