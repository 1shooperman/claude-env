#!/usr/bin/env bats
# shellcheck shell=bash

setup() {
  export CLAUDENV_HOME
  CLAUDENV_HOME="$(mktemp -d)"
  mkdir -p "$CLAUDENV_HOME/envs"
  # Mimic install.sh: the "default" env always exists after installation.
  mkdir -p "$CLAUDENV_HOME/envs/default"
  # shellcheck disable=SC1091
  source "$BATS_TEST_DIRNAME/../claudenv.sh"
  # Reset any auto-activation that happened at source time (e.g. from a
  # .claudenvrc in a parent directory of the test runner).
  _claudenv_deactivate --quiet 2>/dev/null || true
  unset _CLAUDENV_AUTO
}

teardown() {
  rm -rf "$CLAUDENV_HOME"
  unset CLAUDENV_ACTIVE CLAUDE_CONFIG_DIR \
        _CLAUDENV_OLD_CLAUDE_CONFIG_DIR _CLAUDENV_OLD_PS1 \
        _CLAUDENV_AUTO _CLAUDENV_OLD_PROMPT_COMMAND
}

# ── config ────────────────────────────────────────────────────────────────────

@test "config: creates env directory" {
  _claudenv_config "myenv" <<< "n"
  [ -d "$CLAUDENV_HOME/envs/myenv" ]
}

@test "config: rejects empty name" {
  run _claudenv_config ""
  [ "$status" -eq 1 ]
}

@test "config: rejects name with spaces" {
  run _claudenv_config "my env"
  [ "$status" -eq 1 ]
}

@test "config: rejects name with slashes" {
  run _claudenv_config "my/env"
  [ "$status" -eq 1 ]
}

@test "config: rejects duplicate name" {
  mkdir -p "$CLAUDENV_HOME/envs/existing"
  run _claudenv_config "existing"
  [ "$status" -eq 1 ]
}

@test "config: rejects name starting with hyphen" {
  run _claudenv_config "-badname"
  [ "$status" -eq 1 ]
}

# ── activate ──────────────────────────────────────────────────────────────────

@test "activate: sets CLAUDE_CONFIG_DIR" {
  mkdir -p "$CLAUDENV_HOME/envs/work"
  _claudenv_activate "work"
  [ "$CLAUDE_CONFIG_DIR" = "$CLAUDENV_HOME/envs/work" ]
}

@test "activate: sets CLAUDENV_ACTIVE" {
  mkdir -p "$CLAUDENV_HOME/envs/work"
  _claudenv_activate "work"
  [ "$CLAUDENV_ACTIVE" = "work" ]
}

@test "activate: fails for nonexistent env" {
  run _claudenv_activate "nonexistent"
  [ "$status" -eq 1 ]
}

@test "activate: prefixes PS1 in non-zsh shell" {
  PS1="$ "
  mkdir -p "$CLAUDENV_HOME/envs/work"
  _claudenv_activate "work"
  [[ "$PS1" == "(work)"* ]]
}

@test "activate: idempotent when called twice on same env" {
  mkdir -p "$CLAUDENV_HOME/envs/work"
  _claudenv_activate "work"
  _claudenv_activate "work"
  [ "$CLAUDENV_ACTIVE" = "work" ]
  [ "$CLAUDE_CONFIG_DIR" = "$CLAUDENV_HOME/envs/work" ]
}

@test "activate: swaps envs without losing original CLAUDE_CONFIG_DIR" {
  export CLAUDE_CONFIG_DIR="/original"
  mkdir -p "$CLAUDENV_HOME/envs/work" "$CLAUDENV_HOME/envs/personal"
  _claudenv_activate "work"
  _claudenv_activate "personal"
  [ "$CLAUDENV_ACTIVE" = "personal" ]
  [ "$CLAUDE_CONFIG_DIR" = "$CLAUDENV_HOME/envs/personal" ]
  # Deactivating personal should restore the original, not work's dir
  _claudenv_deactivate
  [ "$CLAUDE_CONFIG_DIR" = "/original" ]
}

# ── deactivate ────────────────────────────────────────────────────────────────

@test "deactivate: restores CLAUDE_CONFIG_DIR" {
  export CLAUDE_CONFIG_DIR="/original/dir"
  mkdir -p "$CLAUDENV_HOME/envs/work"
  _claudenv_activate "work"
  _claudenv_deactivate
  [ "$CLAUDE_CONFIG_DIR" = "/original/dir" ]
}

@test "deactivate: clears CLAUDENV_ACTIVE" {
  mkdir -p "$CLAUDENV_HOME/envs/work"
  _claudenv_activate "work"
  _claudenv_deactivate
  [ -z "${CLAUDENV_ACTIVE:-}" ]
}

@test "deactivate: restores PS1 in non-zsh shell" {
  PS1="$ "
  mkdir -p "$CLAUDENV_HOME/envs/work"
  _claudenv_activate "work"
  _claudenv_deactivate
  [ "$PS1" = "$ " ]
}

@test "deactivate: fails when no env is active" {
  run _claudenv_deactivate
  [ "$status" -eq 1 ]
}

@test "deactivate --quiet: returns 0 when no env is active" {
  run _claudenv_deactivate --quiet
  [ "$status" -eq 0 ]
}

# ── list ──────────────────────────────────────────────────────────────────────

@test "list: shows configured envs" {
  mkdir -p "$CLAUDENV_HOME/envs/work" "$CLAUDENV_HOME/envs/personal"
  run _claudenv_list
  [ "$status" -eq 0 ]
  [[ "$output" == *"work"* ]]
  [[ "$output" == *"personal"* ]]
}

@test "list: marks active env with asterisk" {
  mkdir -p "$CLAUDENV_HOME/envs/work"
  _claudenv_activate "work"
  run _claudenv_list
  [[ "$output" == *"* work"* ]]
}

@test "list: shows message when no envs exist" {
  rm -rf "$CLAUDENV_HOME/envs/default"
  run _claudenv_list
  [ "$status" -eq 0 ]
  [[ "$output" == *"No envs"* ]]
}

@test "list: output is sorted alphabetically" {
  mkdir -p "$CLAUDENV_HOME/envs/zebra" "$CLAUDENV_HOME/envs/alpha" "$CLAUDENV_HOME/envs/middle"
  run _claudenv_list
  [ "$status" -eq 0 ]
  # Extract env names from output lines, verify alpha ordering
  local names
  names=$(printf '%s\n' "$output" | sed 's/^[* ]*//' | tr -d ' ')
  [ "$(printf '%s\n' "$names" | head -1)" = "alpha" ]
  [ "$(printf '%s\n' "$names" | tail -1)" = "zebra" ]
}

# ── remove ────────────────────────────────────────────────────────────────────

@test "remove: removes env directory" {
  mkdir -p "$CLAUDENV_HOME/envs/old"
  _claudenv_remove "old" <<< "y"
  [ ! -d "$CLAUDENV_HOME/envs/old" ]
}

@test "remove: rejects removing active env" {
  mkdir -p "$CLAUDENV_HOME/envs/work"
  _claudenv_activate "work"
  run _claudenv_remove "work"
  [ "$status" -eq 1 ]
  [ -d "$CLAUDENV_HOME/envs/work" ]
}

@test "remove: fails for nonexistent env" {
  run _claudenv_remove "ghost"
  [ "$status" -eq 1 ]
}

# ── default env ───────────────────────────────────────────────────────────────

@test "default: activate sets CLAUDE_CONFIG_DIR to ~/.claude" {
  _claudenv_activate "default"
  [ "$CLAUDE_CONFIG_DIR" = "$HOME/.claude" ]
}

@test "default: activate sets CLAUDENV_ACTIVE" {
  _claudenv_activate "default"
  [ "$CLAUDENV_ACTIVE" = "default" ]
}

@test "default: deactivate restores original CLAUDE_CONFIG_DIR" {
  export CLAUDE_CONFIG_DIR="/original"
  _claudenv_activate "default"
  _claudenv_deactivate
  [ "$CLAUDE_CONFIG_DIR" = "/original" ]
}

@test "default: config rejects reserved name" {
  run _claudenv_config "default"
  [ "$status" -eq 1 ]
  [[ "$output" == *"reserved"* ]]
}

@test "default: remove rejects reserved name" {
  run _claudenv_remove "default"
  [ "$status" -eq 1 ]
  [ -d "$CLAUDENV_HOME/envs/default" ]
}

@test "default: list annotates with (~/.claude)" {
  run _claudenv_list
  [ "$status" -eq 0 ]
  [[ "$output" == *"default"*"~/.claude"* ]]
}

@test "default: list marks active default with asterisk" {
  _claudenv_activate "default"
  run _claudenv_list
  [[ "$output" == *"* default"* ]]
}

@test "default: swap from named env preserves original CLAUDE_CONFIG_DIR" {
  export CLAUDE_CONFIG_DIR="/original"
  mkdir -p "$CLAUDENV_HOME/envs/work"
  _claudenv_activate "work"
  _claudenv_activate "default"
  [ "$CLAUDE_CONFIG_DIR" = "$HOME/.claude" ]
  _claudenv_deactivate
  [ "$CLAUDE_CONFIG_DIR" = "/original" ]
}

# ── version ───────────────────────────────────────────────────────────────────

@test "version: outputs a string" {
  printf 'v1.2.3\n' > "$CLAUDENV_HOME/version"
  run _claudenv_version
  [ "$status" -eq 0 ]
  [[ "$output" == *"v1.2.3"* ]]
}

# ── upgrade ───────────────────────────────────────────────────────────────────

@test "upgrade: fails with no argument" {
  run _claudenv_upgrade ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage"* ]]
}

@test "upgrade: installs downloaded claudenv.sh and updates version file" {
  local fake_sh fake_sums
  fake_sh="$(mktemp)"
  printf '# fake claudenv.sh\n' > "$fake_sh"

  # Stub download to simulate a versioned release (no SHA256SUMS)
  _claudenv_upgrade_download() {
    local url="$1" dest="$2"
    case "$url" in
      */claudenv.sh) cp "$fake_sh" "$dest"; return 0 ;;
      *)             return 1 ;;  # SHA256SUMS not found
    esac
  }

  run _claudenv_upgrade "v9.9.9"
  rm -f "$fake_sh"

  [ "$status" -eq 0 ]
  [ "$(cat "$CLAUDENV_HOME/version")" = "v9.9.9" ]
  [[ "$output" == *"upgraded to v9.9.9"* ]]
}

@test "upgrade: verifies SHA256 checksum when SHA256SUMS is present" {
  local fake_sh fake_sums
  fake_sh="$(mktemp)"
  printf '# fake claudenv.sh v2\n' > "$fake_sh"

  local checksum
  if command -v sha256sum > /dev/null 2>&1; then
    checksum="$(sha256sum "$fake_sh" | awk '{print $1}')"
  else
    checksum="$(shasum -a 256 "$fake_sh" | awk '{print $1}')"
  fi

  _claudenv_upgrade_download() {
    local url="$1" dest="$2"
    case "$url" in
      */claudenv.sh)  cp "$fake_sh" "$dest"; return 0 ;;
      */SHA256SUMS)   printf '%s  claudenv.sh\n' "$checksum" > "$dest"; return 0 ;;
    esac
  }

  run _claudenv_upgrade "v9.9.9"
  rm -f "$fake_sh"

  [ "$status" -eq 0 ]
  [[ "$output" == *"integrity check passed"* ]]
  [[ "$output" == *"upgraded to v9.9.9"* ]]
}

@test "upgrade: fails when SHA256 checksum does not match" {
  local fake_sh
  fake_sh="$(mktemp)"
  printf '# fake claudenv.sh\n' > "$fake_sh"

  _claudenv_upgrade_download() {
    local url="$1" dest="$2"
    case "$url" in
      */claudenv.sh)  cp "$fake_sh" "$dest"; return 0 ;;
      */SHA256SUMS)   printf 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef  claudenv.sh\n' > "$dest"; return 0 ;;
    esac
  }

  run _claudenv_upgrade "v9.9.9"
  rm -f "$fake_sh"

  [ "$status" -eq 1 ]
  [[ "$output" == *"integrity check FAILED"* ]]
}

@test "upgrade: fails when download of claudenv.sh fails" {
  _claudenv_upgrade_download() { return 1; }
  run _claudenv_upgrade "v9.9.9"
  [ "$status" -eq 1 ]
  [[ "$output" == *"failed to download"* ]]
}

@test "upgrade: latest resolves tag from API response" {
  local fake_sh
  fake_sh="$(mktemp)"
  printf '# latest claudenv.sh\n' > "$fake_sh"

  _claudenv_upgrade_download() {
    local url="$1" dest="$2"
    case "$url" in
      */releases/latest) printf '{"tag_name":"v2.0.0","name":"Release v2.0.0"}\n' > "$dest"; return 0 ;;
      */claudenv.sh)     cp "$fake_sh" "$dest"; return 0 ;;
      *)                 return 1 ;;
    esac
  }

  run _claudenv_upgrade "latest"
  rm -f "$fake_sh"

  [ "$status" -eq 0 ]
  [[ "$output" == *"v2.0.0"* ]]
  [ "$(cat "$CLAUDENV_HOME/version")" = "v2.0.0" ]
}

# ── uninstall ─────────────────────────────────────────────────────────────────

@test "uninstall: cancels when answer is n" {
  _claudenv_uninstall <<< "n"
  [ -d "$CLAUDENV_HOME" ]
}

@test "uninstall: removes CLAUDENV_HOME" {
  local home_path="$CLAUDENV_HOME"
  _claudenv_uninstall <<< "y"
  [ ! -d "$home_path" ]
}

@test "uninstall: deactivates active env first" {
  mkdir -p "$CLAUDENV_HOME/envs/work"
  _claudenv_activate "work"
  _claudenv_uninstall <<< "y"
  [ -z "${CLAUDENV_ACTIVE:-}" ]
}

@test "uninstall: removes claudenv block from rc file" {
  local fake_home
  fake_home="$(mktemp -d)"
  printf '\n# claudenv\nexport CLAUDENV_HOME="$HOME/.claudenv"\n. "$HOME/.claudenv/claudenv.sh"\n' \
    > "$fake_home/.zshrc"
  HOME="$fake_home" SHELL="/bin/zsh" _claudenv_uninstall <<< "y"
  ! grep -qF '# claudenv' "$fake_home/.zshrc" 2>/dev/null
  rm -rf "$fake_home"
}

@test "uninstall: leaves other rc content intact" {
  local fake_home
  fake_home="$(mktemp -d)"
  printf 'export PATH="$PATH:/usr/local/bin"\n\n# claudenv\nexport CLAUDENV_HOME="$HOME/.claudenv"\n. "$HOME/.claudenv/claudenv.sh"\n\nexport EDITOR=vim\n' \
    > "$fake_home/.zshrc"
  HOME="$fake_home" SHELL="/bin/zsh" _claudenv_uninstall <<< "y"
  grep -qF 'export PATH=' "$fake_home/.zshrc"
  grep -qF 'export EDITOR=vim' "$fake_home/.zshrc"
  rm -rf "$fake_home"
}

# ── .claudenvrc auto-activation ───────────────────────────────────────────────

@test "find_rc: finds .claudenvrc in current directory" {
  local tmpdir
  tmpdir="$(mktemp -d)"
  printf 'myenv\n' > "$tmpdir/.claudenvrc"
  result="$(cd "$tmpdir" && _claudenv_find_rc)"
  [ "$result" = "$tmpdir/.claudenvrc" ]
  rm -rf "$tmpdir"
}

@test "find_rc: finds .claudenvrc in parent directory" {
  local tmpdir child
  tmpdir="$(mktemp -d)"
  child="$tmpdir/sub/dir"
  mkdir -p "$child"
  printf 'myenv\n' > "$tmpdir/.claudenvrc"
  result="$(cd "$child" && _claudenv_find_rc)"
  [ "$result" = "$tmpdir/.claudenvrc" ]
  rm -rf "$tmpdir"
}

@test "find_rc: returns non-zero when no .claudenvrc exists" {
  local tmpdir
  tmpdir="$(mktemp -d)"
  run bash -c "source '$BATS_TEST_DIRNAME/../claudenv.sh'; cd '$tmpdir'; _claudenv_find_rc"
  [ "$status" -ne 0 ]
  rm -rf "$tmpdir"
}

@test "auto: activates env named in .claudenvrc" {
  mkdir -p "$CLAUDENV_HOME/envs/work"
  local rcfile; rcfile="$(mktemp)"
  printf 'work\n' > "$rcfile"
  _claudenv_find_rc() { printf '%s\n' "$rcfile"; }
  _claudenv_auto
  unset -f _claudenv_find_rc
  rm -f "$rcfile"
  [ "$CLAUDENV_ACTIVE" = "work" ]
}

@test "auto: sets _CLAUDENV_AUTO when activating from .claudenvrc" {
  mkdir -p "$CLAUDENV_HOME/envs/work"
  local rcfile; rcfile="$(mktemp)"
  printf 'work\n' > "$rcfile"
  _claudenv_find_rc() { printf '%s\n' "$rcfile"; }
  _claudenv_auto
  unset -f _claudenv_find_rc
  rm -f "$rcfile"
  [ "${_CLAUDENV_AUTO:-}" = "1" ]
}

@test "auto: does nothing when env already active" {
  mkdir -p "$CLAUDENV_HOME/envs/work"
  _claudenv_activate "work"
  local rcfile; rcfile="$(mktemp)"
  printf 'work\n' > "$rcfile"
  _claudenv_find_rc() { printf '%s\n' "$rcfile"; }
  run _claudenv_auto
  unset -f _claudenv_find_rc
  rm -f "$rcfile"
  [ -z "$output" ]
}

@test "auto: deactivates auto-activated env when no .claudenvrc present" {
  mkdir -p "$CLAUDENV_HOME/envs/work"
  _claudenv_activate "work" --auto
  _claudenv_find_rc() { return 1; }
  _claudenv_auto
  unset -f _claudenv_find_rc
  [ -z "${CLAUDENV_ACTIVE:-}" ]
}

@test "auto: does not deactivate manually-activated env" {
  mkdir -p "$CLAUDENV_HOME/envs/work"
  _claudenv_activate "work"
  unset _CLAUDENV_AUTO
  _claudenv_find_rc() { return 1; }
  _claudenv_auto
  unset -f _claudenv_find_rc
  [ "$CLAUDENV_ACTIVE" = "work" ]
}

@test "auto: ignores .claudenvrc with empty content" {
  local rcfile; rcfile="$(mktemp)"
  printf '   \n' > "$rcfile"
  _claudenv_find_rc() { printf '%s\n' "$rcfile"; }
  _claudenv_auto
  unset -f _claudenv_find_rc
  rm -f "$rcfile"
  [ -z "${CLAUDENV_ACTIVE:-}" ]
}

@test "auto: re-activates when CLAUDE_CONFIG_DIR is stale despite matching CLAUDENV_ACTIVE" {
  mkdir -p "$CLAUDENV_HOME/envs/work"
  # Simulate env-var bleed: CLAUDENV_ACTIVE=work but CLAUDE_CONFIG_DIR is wrong.
  export CLAUDENV_ACTIVE="work"
  export CLAUDE_CONFIG_DIR="/wrong/path"
  local rcfile; rcfile="$(mktemp)"
  printf 'work\n' > "$rcfile"
  _claudenv_find_rc() { printf '%s\n' "$rcfile"; }
  _claudenv_auto
  unset -f _claudenv_find_rc
  rm -f "$rcfile"
  [ "$CLAUDE_CONFIG_DIR" = "$CLAUDENV_HOME/envs/work" ]
}

@test "auto: re-activates default when CLAUDE_CONFIG_DIR is stale" {
  # Simulate bleed: CLAUDENV_ACTIVE=default but CLAUDE_CONFIG_DIR points elsewhere.
  export CLAUDENV_ACTIVE="default"
  export CLAUDE_CONFIG_DIR="/wrong/path"
  local rcfile; rcfile="$(mktemp)"
  printf 'default\n' > "$rcfile"
  _claudenv_find_rc() { printf '%s\n' "$rcfile"; }
  _claudenv_auto
  unset -f _claudenv_find_rc
  rm -f "$rcfile"
  [ "$CLAUDE_CONFIG_DIR" = "$HOME/.claude" ]
}
