# claudenv

Shell environment switcher for Claude Code accounts.

## Key constraints

- `install.sh` must stay POSIX sh — no arrays, no `select`, no process substitution.
- `claudenv.sh` targets bash 3.2+ and zsh 5+; arrays, `select`, and `< <(...)` are intentional.
- No external dependencies. No build step.

## Testing

```sh
source claudenv.sh
claudenv config test-env
claudenv test-env          # prompt should show (test-env)
claudenv deactivate
rm -rf "$CLAUDENV_HOME/envs/test-env"
```

Test oh-my-zsh prompt integration by sourcing in an active zsh session with a theme loaded.
