#!/usr/bin/env bats
# shellcheck shell=bash

setup() {
  export CLAUDENV_HOME
  CLAUDENV_HOME="$(mktemp -d)"
  mkdir -p "$CLAUDENV_HOME/envs"
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
  run _claudenv_list
  [ "$status" -eq 0 ]
  [[ "$output" == *"No envs"* ]]
}
