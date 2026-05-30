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
    upgrade)    _claudenv_upgrade "${2:-}" ;;
    uninstall)  _claudenv_uninstall ;;
    help|-h|--help) _claudenv_help ;;
    "")         _claudenv_pick ;;
    *)          _claudenv_activate "$1" ;;
  esac
}

# ── Activate / Deactivate ─────────────────────────────────────────────────────

_claudenv_activate() {
  local name="$1"
  local auto="${2:-}"
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

  if [ "$auto" = "--auto" ]; then
    export _CLAUDENV_AUTO=1
  else
    unset _CLAUDENV_AUTO
  fi

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

  unset CLAUDENV_ACTIVE _CLAUDENV_OLD_CLAUDE_CONFIG_DIR _CLAUDENV_AUTO

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
  # Strip ALL occurrences before prepending once; prevents accumulation when
  # tools like Python venv insert their own prefix before ours, which shifts
  # our prefix away from position 0 and breaks the simple starts-with guard.
  PROMPT="${prefix}${PROMPT//"$prefix"/}"
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

# ── Help ──────────────────────────────────────────────────────────────────────

_claudenv_help() {
  printf 'Commands\n\n'
  printf '  %-30s %s\n' 'claudenv'              'Interactive env picker'
  printf '  %-30s %s\n' 'claudenv <name>'        'Activate a named env'
  printf '  %-30s %s\n' 'claudenv deactivate'    'Deactivate the current env'
  printf '  %-30s %s\n' 'claudenv config [name]' 'Create a new env'
  printf '  %-30s %s\n' 'claudenv list'          'List all envs (* marks the active one)'
  printf '  %-30s %s\n' 'claudenv remove <name>' 'Delete an env'
  printf '  %-30s %s\n' 'claudenv upgrade <ver>' 'Upgrade to a release (e.g. v1.2.3 or latest)'
  printf '  %-30s %s\n' 'claudenv uninstall'     'Remove claudenv and clean up shell profile'
  printf '\nAuto-activation\n\n'
  printf '  Add a .claudenvrc file containing an env name to any directory.\n'
  printf '  claudenv will activate that env automatically when you cd into it\n'
  printf '  and deactivate it when you leave (if it was auto-activated).\n'
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

# ── Upgrade ───────────────────────────────────────────────────────────────────

_claudenv_upgrade_download() {
  local url="$1" dest="$2"
  if command -v curl > /dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest" 2>/dev/null
  elif command -v wget > /dev/null 2>&1; then
    wget -qO "$dest" "$url" 2>/dev/null
  else
    printf 'claudenv upgrade: curl or wget is required\n' >&2
    return 1
  fi
}

_claudenv_upgrade() {
  local target="${1:-}"
  local CLAUDENV_RELEASE_BASE="https://github.com/1shooperman/claude-env/releases/download"
  local CLAUDENV_API="https://api.github.com/repos/1shooperman/claude-env/releases/latest"

  if [ -z "$target" ]; then
    printf 'claudenv upgrade: specify a version or "latest"\n' >&2
    printf '  Usage: claudenv upgrade v1.2.3\n' >&2
    printf '         claudenv upgrade latest\n' >&2
    return 1
  fi

  if [ "$target" = "latest" ]; then
    local tmp_json
    tmp_json="$(mktemp)"
    if ! _claudenv_upgrade_download "$CLAUDENV_API" "$tmp_json"; then
      printf 'claudenv upgrade: failed to query GitHub releases\n' >&2
      rm -f "$tmp_json"
      return 1
    fi
    target="$(awk -F'"' '/"tag_name":/{print $4; exit}' "$tmp_json")"
    rm -f "$tmp_json"
    if [ -z "$target" ]; then
      printf 'claudenv upgrade: could not determine latest release\n' >&2
      return 1
    fi
    printf 'claudenv: latest release is %s\n' "$target"
  fi

  local tmp_sh tmp_sums
  tmp_sh="$(mktemp)"
  tmp_sums="$(mktemp)"

  if ! _claudenv_upgrade_download "${CLAUDENV_RELEASE_BASE}/${target}/claudenv.sh" "$tmp_sh"; then
    printf 'claudenv upgrade: failed to download claudenv.sh for %s\n' "$target" >&2
    rm -f "$tmp_sh" "$tmp_sums"
    return 1
  fi

  if _claudenv_upgrade_download "${CLAUDENV_RELEASE_BASE}/${target}/SHA256SUMS" "$tmp_sums" 2>/dev/null \
      && [ -s "$tmp_sums" ]; then
    local expected actual
    expected="$(awk '$2 == "claudenv.sh" { print $1 }' "$tmp_sums")"
    if [ -n "$expected" ]; then
      if command -v sha256sum > /dev/null 2>&1; then
        actual="$(sha256sum "$tmp_sh" | awk '{print $1}')"
      elif command -v shasum > /dev/null 2>&1; then
        actual="$(shasum -a 256 "$tmp_sh" | awk '{print $1}')"
      fi
      if [ -n "${actual:-}" ] && [ "$actual" != "$expected" ]; then
        printf 'claudenv upgrade: integrity check FAILED for %s\n' "$target" >&2
        printf '  expected: %s\n' "$expected" >&2
        printf '  actual:   %s\n' "$actual" >&2
        rm -f "$tmp_sh" "$tmp_sums"
        return 1
      fi
      [ -n "${actual:-}" ] && printf 'claudenv: integrity check passed\n'
    fi
  fi
  rm -f "$tmp_sums"

  cp "$CLAUDENV_HOME/claudenv.sh" "$CLAUDENV_HOME/claudenv.sh.bak" 2>/dev/null || true
  mv "$tmp_sh" "$CLAUDENV_HOME/claudenv.sh"
  chmod 644 "$CLAUDENV_HOME/claudenv.sh"
  printf '%s\n' "$target" > "$CLAUDENV_HOME/version"

  printf 'claudenv: upgraded to %s\n' "$target"
  printf 'Reload your shell to apply the update:\n'
  printf '  source %s/claudenv.sh\n' "$CLAUDENV_HOME"
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

  # Remove chpwd / PROMPT_COMMAND auto-activation hooks.
  if [ -n "${ZSH_VERSION:-}" ]; then
    add-zsh-hook -d chpwd _claudenv_auto 2>/dev/null || true
  else
    if [ -n "${_CLAUDENV_OLD_PROMPT_COMMAND+x}" ]; then
      PROMPT_COMMAND="$_CLAUDENV_OLD_PROMPT_COMMAND"
      unset _CLAUDENV_OLD_PROMPT_COMMAND
    fi
  fi

  unset -f claudenv \
    _claudenv_activate _claudenv_deactivate \
    _claudenv_prompt_hook _claudenv_prompt_on _claudenv_prompt_off \
    _claudenv_list_names _claudenv_list _claudenv_pick \
    _claudenv_config _claudenv_remove _claudenv_version \
    _claudenv_upgrade_download _claudenv_upgrade \
    _claudenv_help _claudenv_uninstall \
    _claudenv_find_rc _claudenv_auto 2>/dev/null || true

  unset CLAUDENV_HOME CLAUDENV_ACTIVE _CLAUDENV_AUTO \
    _CLAUDENV_OLD_CLAUDE_CONFIG_DIR _CLAUDENV_OLD_PS1

  printf 'claudenv uninstalled. Open a new shell to finish.\n'
}

# ── Auto-activation via .claudenvrc ──────────────────────────────────────────
#
# Walking up to the filesystem root, finds the nearest .claudenvrc. The file
# should contain only an env name (whitespace is stripped). On cd, the matching
# env is activated automatically; leaving the directory tree auto-deactivates
# it (only if it was auto-activated, not manually activated).

_claudenv_find_rc() {
  local dir="${PWD}"
  while [ "$dir" != "/" ]; do
    [ -f "$dir/.claudenvrc" ] && printf '%s/.claudenvrc\n' "$dir" && return 0
    dir="${dir%/*}"
    [ -z "$dir" ] && dir="/"
  done
  return 1
}

_claudenv_auto() {
  local rc name
  if rc="$(_claudenv_find_rc 2>/dev/null)"; then
    name="$(tr -d '[:space:]' < "$rc")"
    [ -z "$name" ] && return 0
    if [ "$name" = "${CLAUDENV_ACTIVE:-}" ]; then
      # Names match but validate CLAUDE_CONFIG_DIR is consistent — inherited
      # env vars from a parent shell can leave it pointing at the wrong path.
      local expected
      if [ "$name" = "default" ]; then
        expected="$HOME/.claude"
      else
        expected="$CLAUDENV_HOME/envs/$name"
      fi
      [ "${CLAUDE_CONFIG_DIR:-}" = "$expected" ] && return 0
    fi
    _claudenv_activate "$name" --auto
  elif [ "${_CLAUDENV_AUTO:-}" = "1" ] && [ -n "${CLAUDENV_ACTIVE:-}" ]; then
    _claudenv_deactivate --quiet
  fi
}

# On source, clear stale inherited claudenv state so new shells start clean.
# Sub-shells that don't re-source claudenv.sh keep inherited env vars as-is.
if [ -n "${CLAUDENV_ACTIVE:-}" ]; then
  _claudenv_expected_dir=""
  if [ "$CLAUDENV_ACTIVE" = "default" ]; then
    _claudenv_expected_dir="$HOME/.claude"
  else
    _claudenv_expected_dir="$CLAUDENV_HOME/envs/$CLAUDENV_ACTIVE"
  fi
  if [ "${CLAUDE_CONFIG_DIR:-}" != "$_claudenv_expected_dir" ]; then
    unset CLAUDENV_ACTIVE _CLAUDENV_OLD_CLAUDE_CONFIG_DIR _CLAUDENV_AUTO
    unset CLAUDE_CONFIG_DIR
  fi
  unset _claudenv_expected_dir
fi

# If a consistent env was inherited, restore the prompt hook for this shell.
[ -n "${CLAUDENV_ACTIVE:-}" ] && _claudenv_prompt_on

# Register the directory-change hook and run once for the initial directory.
if [ -n "${ZSH_VERSION:-}" ]; then
  autoload -Uz add-zsh-hook 2>/dev/null
  add-zsh-hook chpwd _claudenv_auto
else
  export _CLAUDENV_OLD_PROMPT_COMMAND="${PROMPT_COMMAND:-}"
  if [ -z "${PROMPT_COMMAND:-}" ]; then
    PROMPT_COMMAND="_claudenv_auto"
  else
    PROMPT_COMMAND="_claudenv_auto; ${PROMPT_COMMAND}"
  fi
fi

_claudenv_auto
