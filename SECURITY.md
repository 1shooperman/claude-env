# Security Policy

## Supported versions

| Branch | Supported |
|--------|-----------|
| `main` | Yes       |

Only the latest commit on `main` is actively supported. There are no versioned releases at this time.

## Reporting a vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Use GitHub's private vulnerability reporting instead:
[Report a vulnerability](https://github.com/1shooperman/claude-env/security/advisories/new)

You should receive an acknowledgment within 48 hours. We will work with you to understand the scope and issue a fix as quickly as possible.

## Scope

claudenv is a shell function that sets `CLAUDE_CONFIG_DIR` and modifies your shell prompt. The primary security surface is:

- **Env directory names** — validated to `[a-zA-Z0-9_-]` only; no arbitrary paths are accepted.
- **`CLAUDE_CONFIG_DIR` contents** — claudenv does not manage credentials directly; that is delegated to Claude Code's own auth flow.
- **Shell injection** — claudenv does not evaluate arbitrary input via `eval`. All user-supplied values are validated before use.

If you discover a way to achieve privilege escalation, arbitrary code execution, or credential exposure through claudenv, please report it privately.
