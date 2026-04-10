# claudenv — agent guidance

See CLAUDE.md for build constraints and testing instructions.

## File map

| File | Purpose |
|------|---------|
| `claudenv.sh` | Shell function — the entire runtime; sourced, not executed |
| `install.sh` | One-time setup; POSIX sh; copies claudenv.sh and writes to shell rc |

## What not to change

- Do not introduce external dependencies or a build step.
- Do not replace the `select`-based picker with an `fzf` dependency.
- Do not modify `PS1`/`PROMPT` outside of `_claudenv_prompt_on` and `_claudenv_prompt_off`.
