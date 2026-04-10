# claudenv — Claude Code environment switcher
# Source this file via install.sh; do not execute directly.
#
# Compatible with: bash 3.2+, zsh (including oh-my-zsh)
# macOS is the primary target; see GitHub issues for WSL/Windows roadmap.
# shellcheck shell=bash

CLAUDENV_HOME="${CLAUDENV_HOME:-$HOME/.claudenv}"

# ── Public command ────────────────────────────────────────────────────────────

claudenv() {
  local cmd="${1:-}"
  case "$cmd" in
    deactivate) _claudenv_deactivate ;;
    config)     _claudenv_config "${2:-}" ;;
    list)       _claudenv_list ;;
    "")         _claudenv_pick ;;
    *)          _claudenv_activate "$1" ;;
  esac
}

# ── Activate / Deactivate ─────────────────────────────────────────────────────

_claudenv_activate() {
  local name="$1"
  local env_dir="$CLAUDENV_HOME/envs/$name"

  if [ ! -d "$env_dir" ]; then
    printf 'claudenv: no such env "%s"\n' "$name" >&2
    printf "  Run 'claudenv list' to see available envs, or 'claudenv config' to create one.\n" >&2
    return 1
  fi

  # Silently swap if already in another env
  [ -n "${CLAUDENV_ACTIVE:-}" ] && _claudenv_deactivate --quiet

  export _CLAUDENV_OLD_CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-}"
  export CLAUDE_CONFIG_DIR="$env_dir"
  export CLAUDENV_ACTIVE="$name"

  _claudenv_prompt_on

  printf 'Switched to claudenv: %s\n' "$name"
}

_claudenv_deactivate() {
  if [ -z "${CLAUDENV_ACTIVE:-}" ]; then
    [ "${1:-}" = "--quiet" ] || printf 'claudenv: no active env\n' >&2
    return 1
  fi

  if [ -n "${_CLAUDENV_OLD_CLAUDE_CONFIG_DIR:-}" ]; then
    export CLAUDE_CONFIG_DIR="$_CLAUDENV_OLD_CLAUDE_CONFIG_DIR"
  else
    unset CLAUDE_CONFIG_DIR
  fi

  # Pass active name before unsetting so prompt_off can strip the prefix
  _claudenv_prompt_off "$CLAUDENV_ACTIVE"

  unset CLAUDENV_ACTIVE _CLAUDENV_OLD_CLAUDE_CONFIG_DIR

  [ "${1:-}" = "--quiet" ] || printf 'claudenv: deactivated\n'
}

# ── Prompt integration ────────────────────────────────────────────────────────
#
# oh-my-zsh themes rebuild PROMPT on each precmd call. We register our own
# precmd hook (via add-zsh-hook) so it runs *after* the theme, appending our
# prefix to whatever PROMPT the theme just produced. The guard in the hook
# prevents double-prefixing when the theme doesn't rebuild on every render.
#
# For plain bash/zsh (no oh-my-zsh), PS1 is modified directly.

_claudenv_prompt_hook() {
  local prefix="(${CLAUDENV_ACTIVE}) "
  case "$PROMPT" in
    "$prefix"*) ;; # already prefixed — theme didn't rebuild this render
    *)          PROMPT="${prefix}${PROMPT}" ;;
  esac
}

_claudenv_prompt_on() {
  if [ -n "${ZSH:-}" ]; then
    autoload -Uz add-zsh-hook 2>/dev/null
    add-zsh-hook precmd _claudenv_prompt_hook
  else
    export _CLAUDENV_OLD_PS1="${PS1:-}"
    PS1="(${CLAUDENV_ACTIVE}) ${PS1}"
    export PS1
  fi
}

_claudenv_prompt_off() {
  local prev_name="${1:-}"
  if [ -n "${ZSH:-}" ]; then
    add-zsh-hook -d precmd _claudenv_prompt_hook 2>/dev/null || true
    # Strip prefix immediately for themes that don't rebuild PROMPT in precmd
    if [ -n "$prev_name" ]; then
      local prefix="(${prev_name}) "
      PROMPT="${PROMPT#$prefix}"
    fi
  else
    PS1="${_CLAUDENV_OLD_PS1:-}"
    export PS1
    unset _CLAUDENV_OLD_PS1
  fi
}

# ── List ──────────────────────────────────────────────────────────────────────

_claudenv_list() {
  local envs_dir="$CLAUDENV_HOME/envs"
  local found=0
  local name

  while IFS= read -r name; do
    found=1
    if [ "$name" = "${CLAUDENV_ACTIVE:-}" ]; then
      printf '* %s\n' "$name"
    else
      printf '  %s\n' "$name"
    fi
  done < <(find "$envs_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
           -exec basename {} \; | sort)

  [ "$found" -eq 0 ] && printf "No envs configured. Run 'claudenv config' to create one.\n"
}

# ── Interactive picker ────────────────────────────────────────────────────────

_claudenv_pick() {
  local envs_dir="$CLAUDENV_HOME/envs"
  local envs=()
  local name

  while IFS= read -r name; do
    envs+=("$name")
  done < <(find "$envs_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
           -exec basename {} \; | sort)

  if [ "${#envs[@]}" -eq 0 ]; then
    printf "No envs configured. Run 'claudenv config' to create one.\n"
    return 1
  fi

  if [ "${#envs[@]}" -eq 1 ]; then
    _claudenv_activate "${envs[0]}"
    return
  fi

  PS3="Select env: "
  select name in "${envs[@]}" "(cancel)"; do
    case "$name" in
      "(cancel)") printf 'Cancelled.\n'; break ;;
      "")         printf 'Invalid selection.\n' ;;
      *)          _claudenv_activate "$name"; break ;;
    esac
  done
}

# ── Config / create ───────────────────────────────────────────────────────────

_claudenv_config() {
  local name="${1:-}"

  if [ -z "$name" ]; then
    printf 'Env name: '
    read -r name
  fi

  case "$name" in
    "")
      printf 'claudenv: name cannot be empty\n' >&2; return 1 ;;
    *[^a-zA-Z0-9_-]*)
      printf 'claudenv: invalid name "%s" (letters, numbers, - and _ only)\n' "$name" >&2; return 1 ;;
  esac

  local env_dir="$CLAUDENV_HOME/envs/$name"

  if [ -d "$env_dir" ]; then
    printf 'claudenv: env "%s" already exists at %s\n' "$name" "$env_dir" >&2; return 1
  fi

  mkdir -p "$env_dir"
  printf 'Created env "%s" → %s\n' "$name" "$env_dir"

  printf 'Activate now? [y/N] '
  read -r yn
  case "$yn" in [Yy]*) _claudenv_activate "$name" ;; esac
}
