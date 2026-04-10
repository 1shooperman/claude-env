#!/usr/bin/env bats
# shellcheck shell=bash
# Tests for install.sh shell-profile wiring behaviour.

INSTALL_SH="$BATS_TEST_DIRNAME/../install.sh"

setup() {
  export FAKE_HOME
  FAKE_HOME="$(mktemp -d)"
  export HOME="$FAKE_HOME"
  export CLAUDENV_HOME="$FAKE_HOME/.claudenv"
  export SHELL="/bin/zsh"
}

teardown() {
  rm -rf "$FAKE_HOME"
}

# ── rc prompt ─────────────────────────────────────────────────────────────────

@test "rc-prompt: writes to .zshrc when SHELL is zsh" {
  export CLAUDENV_INSTALL_CONFIRM=""
  run sh "$INSTALL_SH"
  [ "$status" -eq 0 ]
  grep -qF '# claudenv' "$HOME/.zshrc"
}

@test "rc-prompt: writes to .bashrc when SHELL is bash" {
  export SHELL="/bin/bash"
  export CLAUDENV_INSTALL_CONFIRM=""
  run sh "$INSTALL_SH"
  [ "$status" -eq 0 ]
  grep -qF '# claudenv' "$HOME/.bashrc"
}

@test "rc-prompt: skips write when answer is n" {
  export CLAUDENV_INSTALL_CONFIRM="n"
  run sh "$INSTALL_SH"
  [ "$status" -eq 0 ]
  ! grep -qF '# claudenv' "$HOME/.zshrc" 2>/dev/null
}

@test "rc-prompt: skips write when answer is N" {
  export CLAUDENV_INSTALL_CONFIRM="N"
  run sh "$INSTALL_SH"
  [ "$status" -eq 0 ]
  ! grep -qF '# claudenv' "$HOME/.zshrc" 2>/dev/null
}

@test "rc-prompt: writes when answer is y" {
  export CLAUDENV_INSTALL_CONFIRM="y"
  run sh "$INSTALL_SH"
  [ "$status" -eq 0 ]
  grep -qF '# claudenv' "$HOME/.zshrc"
}

@test "rc-prompt: defaults to yes when stdin is not a TTY" {
  unset CLAUDENV_INSTALL_CONFIRM
  run sh "$INSTALL_SH"
  [ "$status" -eq 0 ]
  grep -qF '# claudenv' "$HOME/.zshrc"
}

@test "rc-prompt: does not duplicate when marker already present" {
  printf '\n# claudenv\nexport CLAUDENV_HOME="$HOME/.claudenv"\n. "$HOME/.claudenv/claudenv.sh"\n' \
    > "$HOME/.zshrc"
  export CLAUDENV_INSTALL_CONFIRM=""
  run sh "$INSTALL_SH"
  [ "$status" -eq 0 ]
  count=$(grep -cF '# claudenv' "$HOME/.zshrc")
  [ "$count" -eq 1 ]
}

@test "rc-prompt: prints manual setup hint when answer is n" {
  export CLAUDENV_INSTALL_CONFIRM="n"
  run sh "$INSTALL_SH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Skipping shell profile wiring"* ]]
}

@test "rc-prompt: adds CLAUDENV_HOME export to rc file" {
  export CLAUDENV_INSTALL_CONFIRM=""
  run sh "$INSTALL_SH"
  [ "$status" -eq 0 ]
  grep -qF 'CLAUDENV_HOME' "$HOME/.zshrc"
}
