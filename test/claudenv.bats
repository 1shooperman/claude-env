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
}

teardown() {
  rm -rf "$CLAUDENV_HOME"
  unset CLAUDENV_ACTIVE CLAUDE_CONFIG_DIR \
        _CLAUDENV_OLD_CLAUDE_CONFIG_DIR _CLAUDENV_OLD_PS1
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
