# Contributing to claudenv

Thank you for your interest in contributing. claudenv is a plain shell project — no build step, no package manager, no compiled artifacts.

## Reporting bugs

Open a [GitHub issue](https://github.com/1shooperman/claude-env/issues/new) and include:

- Your shell and version (`zsh --version` or `bash --version`)
- Your OS and version
- Steps to reproduce
- What you expected vs. what happened

## Suggesting features

Open an issue with the `enhancement` label. Check [existing issues](https://github.com/1shooperman/claude-env/issues) first to avoid duplicates.

## Submitting a pull request

1. Fork the repo and create a branch from `main`.
2. Make your changes to `claudenv.sh` and/or `install.sh`.
3. Test manually (see below).
4. Open a PR against `main` with a clear description of what changed and why.

Keep PRs focused — one logical change per PR. If you're unsure whether a change is in scope, open an issue first.

## Testing

There is no automated test suite yet. Test your changes manually:

```sh
# From the repo root, source the function directly
source claudenv.sh

# Create a test env
claudenv config test-env

# Activate it — your prompt should show (test-env)
claudenv test-env

# List envs
claudenv list

# Deactivate
claudenv deactivate

# Clean up
rm -rf "$CLAUDENV_HOME/envs/test-env"
```

Test in both zsh and bash if your change touches shell-specific behavior.

## Shell compatibility

- `install.sh` must remain **POSIX sh** compatible — no arrays, no `select`, no process substitution.
- `claudenv.sh` targets **bash 3.2+** and **zsh 5+**. It intentionally uses arrays, `select`, and process substitution for a better UX.

## Code style

- Prefer `printf` over `echo`.
- Use `[ ... ]` not `[[ ... ]]` in `install.sh`.
- Keep functions small and named with `_claudenv_` prefix (private) or `claudenv` (public).
- Quote all variable expansions.
- No external dependencies beyond what's in a base macOS or Linux install.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
