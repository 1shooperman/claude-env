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
    remove)     _claudenv_remove "${2:-}" ;;
    version)    _claudenv_version ;;
    uninstall)  _claudenv_uninstall ;;
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

  # Silently swap if already in another env.
  # Invariant: _CLAUDENV_OLD_CLAUDE_CONFIG_DIR always holds the pre-claudenv
  # value to restore on deactivation — never a claudenv-managed path.
  # Deactivating first restores CLAUDE_CONFIG_DIR to that original value, so
  # the subsequent stash below correctly captures it.
  [ -n "${CLAUDENV_ACTIVE:-}" ] && _claudenv_deactivate --quiet

  export _CLAUDENV_OLD_CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-}"
  # The "default" env maps to the original ~/.claude directory.
  if [ "$name" = "default" ]; then
    export CLAUDE_CONFIG_DIR="$HOME/.claude"
  else
    export CLAUDE_CONFIG_DIR="$env_dir"
  fi
  export CLAUDENV_ACTIVE="$name"

  _claudenv_prompt_on

  printf 'Switched to claudenv: %s\n' "$name"
}

_claudenv_deactivate() {
  if [ -z "${CLAUDENV_ACTIVE:-}" ]; then
    # Quiet: nothing to do is not an error.
    [ "${1:-}" = "--quiet" ] && return 0
    printf 'claudenv: no active env\n' >&2
    return 1
  fi

  if [ -n "${_CLAUDENV_OLD_CLAUDE_CONFIG_DIR:-}" ]; then
    export CLAUDE_CONFIG_DIR="$_CLAUDENV_OLD_CLAUDE_CONFIG_DIR"
  else
    unset CLAUDE_CONFIG_DIR
  fi

  # Pass active name before unsetting so prompt_off can strip the prefix.
  _claudenv_prompt_off "$CLAUDENV_ACTIVE"

  unset CLAUDENV_ACTIVE _CLAUDENV_OLD_CLAUDE_CONFIG_DIR

  [ "${1:-}" = "--quiet" ] || printf 'claudenv: deactivated\n'
}

# ── Prompt integration ────────────────────────────────────────────────────────
#
# oh-my-zsh themes rebuild PROMPT on each precmd call. We register our own
# precmd hook (via add-zsh-hook) so it runs *after* the theme, prepending our
# prefix to whatever PROMPT the theme just produced. The guard in the hook
# prevents double-prefixing when the theme doesn't rebuild on every render.
#
# For plain bash/zsh (no oh-my-zsh), PS1 is modified directly.
#
# Detection: $ZSH_VERSION is set in any zsh session (plain or oh-my-zsh).
# $ZSH is oh-my-zsh-specific and must NOT be used here.

_claudenv_prompt_hook() {
  local prefix="(${CLAUDENV_ACTIVE}) "
  case "$PROMPT" in
    "$prefix"*) ;; # already prefixed — theme didn't rebuild this render
    *)          PROMPT="${prefix}${PROMPT}" ;;
  esac
}

_claudenv_prompt_on() {
  if [ -n "${ZSH_VERSION:-}" ]; then
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
  if [ -n "${ZSH_VERSION:-}" ]; then
    add-zsh-hook -d precmd _claudenv_prompt_hook 2>/dev/null || true
    # Strip prefix immediately for themes that don't rebuild PROMPT in precmd.
    if [ -n "$prev_name" ]; then
      local prefix="(${prev_name}) "
      PROMPT="${PROMPT#"$prefix"}"
    fi
  else
    PS1="${_CLAUDENV_OLD_PS1:-}"
    export PS1
    unset _CLAUDENV_OLD_PS1
  fi
}

# ── Shared env enumeration ────────────────────────────────────────────────────

# Prints one env name per line, sorted alphabetically. Shared by list and pick.
_claudenv_list_names() {
  find "$CLAUDENV_HOME/envs" -mindepth 1 -maxdepth 1 -type d \
    -exec basename {} \; 2>/dev/null | sort
}

# ── List ──────────────────────────────────────────────────────────────────────

_claudenv_list() {
  local found=0
  local name

  while IFS= read -r name; do
    found=1
    local suffix=""
    [ "$name" = "default" ] && suffix="  (~/.claude)"
    if [ "$name" = "${CLAUDENV_ACTIVE:-}" ]; then
      printf '* %s%s\n' "$name" "$suffix"
    else
      printf '  %s%s\n' "$name" "$suffix"
    fi
  done < <(_claudenv_list_names)

  if [ "$found" -eq 0 ]; then
    printf "No envs configured. Run 'claudenv config' to create one.\n"
  fi
}

# ── Interactive picker ────────────────────────────────────────────────────────

_claudenv_pick() {
  local envs=()
  local name first=""

  while IFS= read -r name; do
    [ -z "$first" ] && first="$name"
    envs+=("$name")
  done < <(_claudenv_list_names)

  if [ "${#envs[@]}" -eq 0 ]; then
    printf "No envs configured. Run 'claudenv config' to create one.\n"
    return 1
  fi

  if [ "${#envs[@]}" -eq 1 ]; then
    _claudenv_activate "$first"
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
    "default")
      printf 'claudenv: "default" is a reserved env — activate it with: claudenv default\n' >&2; return 1 ;;
    [-_]* | *[^a-zA-Z0-9_-]*)
      printf 'claudenv: invalid name "%s" (must start with a letter or digit; letters, numbers, - and _ only)\n' "$name" >&2; return 1 ;;
  esac

  local env_dir="$CLAUDENV_HOME/envs/$name"

  if [ -d "$env_dir" ]; then
    printf 'claudenv: env "%s" already exists at %s\n' "$name" "$env_dir"
    printf 'Activate now? [y/N] '
    read -r yn
    case "$yn" in [Yy]*) _claudenv_activate "$name" ;; esac
    return 1
  fi

  mkdir -p "$env_dir"
  printf 'Created env "%s" → %s\n' "$name" "$env_dir"

  printf 'Activate now? [y/N] '
  read -r yn
  case "$yn" in [Yy]*) _claudenv_activate "$name" ;; esac
}

# ── Remove ────────────────────────────────────────────────────────────────────

_claudenv_remove() {
  local name="${1:-}"

  if [ -z "$name" ]; then
    printf 'claudenv: usage: claudenv remove <name>\n' >&2
    return 1
  fi

  if [ "$name" = "default" ]; then
    printf 'claudenv: cannot remove the reserved "default" env\n' >&2
    return 1
  fi

  if [ "$name" = "${CLAUDENV_ACTIVE:-}" ]; then
    printf 'claudenv: cannot remove active env "%s" — run "claudenv deactivate" first\n' "$name" >&2
    return 1
  fi

  local env_dir="$CLAUDENV_HOME/envs/$name"

  if [ ! -d "$env_dir" ]; then
    printf 'claudenv: no such env "%s"\n' "$name" >&2
    return 1
  fi

  printf 'Remove env "%s" at %s? [y/N] ' "$name" "$env_dir"
  read -r yn
  case "$yn" in
    [Yy]*)
      rm -rf "$env_dir"
      printf 'Removed env "%s"\n' "$name"
      ;;
    *)
      printf 'Cancelled.\n'
      ;;
  esac
}

# ── Version ───────────────────────────────────────────────────────────────────

_claudenv_version() {
  local version_file="$CLAUDENV_HOME/version"
  if [ -f "$version_file" ]; then
    cat "$version_file"
  else
    printf 'unknown (reinstall via install.sh to record version)\n'
  fi
}

# ── Uninstall ─────────────────────────────────────────────────────────────────

_claudenv_uninstall() {
  printf 'This will remove %s and the claudenv block from your shell profile.\n' "$CLAUDENV_HOME"
  printf 'Uninstall? [y/N] '
  read -r yn
  case "$yn" in
    [Yy]*) ;;
    *) printf 'Cancelled.\n'; return 0 ;;
  esac

  [ -n "${CLAUDENV_ACTIVE:-}" ] && _claudenv_deactivate --quiet

  rm -rf "$CLAUDENV_HOME"
  printf 'Removed %s\n' "$CLAUDENV_HOME"

  local rc
  if [ -n "${ZSH_VERSION:-}" ] || [ "$(basename "${SHELL:-sh}")" = "zsh" ]; then
    rc="$HOME/.zshrc"
  else
    rc="$HOME/.bashrc"
  fi

  if [ -f "$rc" ] && grep -qF '# claudenv' "$rc"; then
    local tmp
    tmp="$(mktemp)"
    awk '/^# claudenv$/{skip=3} skip>0{skip--; next} 1' "$rc" > "$tmp" && mv "$tmp" "$rc"
    printf 'Removed claudenv block from %s\n' "$rc"
  fi

  unset -f claudenv \
    _claudenv_activate _claudenv_deactivate \
    _claudenv_prompt_hook _claudenv_prompt_on _claudenv_prompt_off \
    _claudenv_list_names _claudenv_list _claudenv_pick \
    _claudenv_config _claudenv_remove _claudenv_version \
    _claudenv_uninstall 2>/dev/null || true

  unset CLAUDENV_HOME CLAUDENV_ACTIVE _CLAUDENV_OLD_CLAUDE_CONFIG_DIR _CLAUDENV_OLD_PS1

  printf 'claudenv uninstalled. Open a new shell to finish.\n'
}
