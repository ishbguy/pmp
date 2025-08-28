#!/usr/bin/env bats

load bats-helper
load pmp-helper

@test "pmp no-such-cmd" {
    local PMP_REPO="$PROJECT_TMP_DIR/pmp"
    local PMP_CONF="$PMP_REPO/pmp.conf"

    run_fail pmp no-such-cmd
    assert_match "not a git command"
}

@test "pmp debug" {
    run_ok pmp -D
    assert_match "^\+"
}

@test "pmp version" {
    run_ok pmp -v
    assert_match "pmp v([0-9]+.?){3}"
    run_ok pmp version
    assert_match "pmp v([0-9]+.?){3}"
}

@test "pmp help" {
    run_ok pmp
    assert_match "print this help message"
    run_ok pmp -h
    assert_match "print this help message"
    run_ok pmp help
    assert_match "print this help message"
}

@test "pmp linux_pma" {
    run_ok linux_pma
    assert_match "$(awk -F= '/^ID=/ {gsub(/-/, "_", $2); gsub(/"/, "", $2); print $2}' /etc/os-release)"

    run_ok pmp update

    run_ok pmp search tmux
    assert_match "tmux"

    run_ok pmp install -y tmux

    run_ok pmp remove -y tmux

    run_ok pmp install -y tmux
    run_ok pmp autoremove -y tmux

    run_ok pmp install -y tmux
    run_ok pmp list
    assert_match "tmux [[:digit:]]"

    run_ok pmp info tmux
    assert_match "tmux"

    run_ok pmp files tmux
    assert_match "tmux  /"

    run_ok pmp owns tmux
    assert_match "tmux"
    run_ok pmp owns -l tmux
    assert_match "^tmux$"
    run_ok pmp owns -l "$(command -v tmux)"
    assert_match "^tmux$"
    run_fail pmp owns -l no-such-file

    run_ok pmp clean -y

    run_ok pmp source
}

@test "pmp init" {
    local PMP_REPO="$PROJECT_TMP_DIR/pmp"
    local PMP_CONF="$PMP_REPO/pmp.conf"

    run_ok pmp init
    assert_match "Initialized empty Git repository"
    [[ -e $PMP_CONF ]]

    rm -rf "$PMP_REPO" && mkdir -p "$PMP_REPO"
    run_ok pmp init "$PMP_REPO"
    assert_match "Initialized empty Git repository"
    [[ -e $PMP_CONF ]]
}

@test "pmp clone" {
    local PMP_REPO="$PROJECT_TMP_DIR/pmp"
    local PMP_CONF="$PMP_REPO/pmp.conf"
    local PMP_REMOTE="$PROJECT_TMP_DIR/remote"

    git init "$PMP_REMOTE"
    touch "$PMP_REMOTE/pmp.conf"
    git -C "$PMP_REMOTE" add pmp.conf
    git -C "$PMP_REMOTE" commit -am 'test'

    run_ok pmp clone "$PMP_REMOTE" "$PMP_REPO"
    assert_match "Cloning into '$PMP_REPO'"
    [[ -e $PMP_CONF ]]
}

@test "pmp config" {
    local PMP_REPO="$PROJECT_TMP_DIR/pmp"
    local PMP_CONF="$PMP_REPO/pmp.conf"

    run_fail pmp config
    [[ -e $PMP_CONF ]]

    run_ok pmp config pmp.repo "$PMP_REPO"
    run_ok pmp config -l
    assert_match "pmp.repo=$PMP_REPO"

    run_ok pmp config pmp.repo
    assert_match "$PMP_REPO"

    run_ok pmp config --unset pmp.repo
    run_fail pmp config pmp.repo

    pmp init

    run_ok pmp config --local core.bare
    assert_match "false"
}

@test "pmp pin & unpin" {
    local PMP_REPO="$PROJECT_TMP_DIR/pmp"
    local PMP_CONF="$PMP_REPO/pmp.conf"

    run_ok pmp init

    run_ok pmp pin git
    run_ok pmp config cmd.git

    run_ok pmp pin tmux awk
    run_ok pmp config cmd.tmux
    run_ok pmp config cmd.awk

    run_fail pmp pin no-such-cmd
    run_fail pmp config cmd.no-such-cmd

    run_ok pmp unpin git
    run_fail pmp config cmd.git

    run_ok pmp unpin tmux awk
    run_fail pmp config cmd.tmux
    run_fail pmp config cmd.awk

    run_fail pmp unpin no-such-cmd
    run_fail pmp config cmd.no-such-cmd
}

@test "pmp keep & free" {
    local PMP_REPO="$PROJECT_TMP_DIR/pmp"
    local PMP_CONF="$PMP_REPO/pmp.conf"
    local TMP_CONF="$PROJECT_TMP_DIR/a.conf"
    local TMP_DIR="$PROJECT_TMP_DIR/b"

    pmp init
    touch "$TMP_CONF"
    mkdir -p "$TMP_DIR" && touch "$TMP_DIR/b.conf"

    run_fail pmp keep
    assert_match "Usage: pmp keep"

    run_fail pmp keep not-exist
    assert_match "No such file or directory"

    run_ok pmp keep "$TMP_CONF"
    assert_match "keep $TMP_CONF"
    [[ -h $TMP_CONF ]]
    [[ -f "$PMP_REPO/$(basename "$TMP_CONF")" ]]
    [[ "$(readlink -f "$TMP_CONF")" == "$(readlink -f "$PMP_REPO/$(basename "$TMP_CONF")")" ]]
    run_ok pmp config --get-regexp "cfg.'$(basename "$TMP_CONF")'*"
    assert_match "$TMP_CONF"

    run_fail pmp keep "$TMP_CONF"
    assert_match "already exist"

    run_ok pmp keep "$TMP_CONF" test/"$(basename "$TMP_CONF")"
    [[ -h $TMP_CONF ]]
    [[ -f "$PMP_REPO/test/$(basename "$TMP_CONF")" ]]
    [[ "$(readlink -f "$TMP_CONF")" == "$(readlink -f "$PMP_REPO/test/$(basename "$TMP_CONF")")" ]]
    run_ok pmp config --get-regexp "cfg.'test/$(basename "$TMP_CONF")'*"
    assert_match "$TMP_CONF"

    run_ok pmp keep "$TMP_DIR"
    assert_match "keep $TMP_DIR"
    [[ -h $TMP_DIR ]]
    [[ -d "$PMP_REPO/$(basename "$TMP_DIR")" ]]
    [[ "$(readlink -f "$TMP_DIR")" == "$(readlink -f "$PMP_REPO/$(basename "$TMP_DIR")")" ]]
    run_ok pmp config --get-regexp "cfg.'$(basename "$TMP_DIR")'*"
    assert_match "$TMP_DIR"

    touch "$HOME/pmp-test.conf"
    run_ok pmp keep "$HOME/pmp-test.conf"
    assert_match 'keep \$HOME/pmp-test.conf'
    [[ -h $HOME/pmp-test.conf ]]
    [[ -f "$PMP_REPO/pmp-test.conf" ]]
    [[ "$(readlink -f "$HOME/pmp-test.conf")" == "$(readlink -f "$PMP_REPO/pmp-test.conf")" ]]
    run_ok pmp config --get-regexp "cfg.'pmp-test.conf'*"
    assert_match '\$HOME/pmp-test.conf'
    rm -rf "$HOME"/pmp-test.conf*

    run_fail pmp free
    assert_match "Usage: pmp free"

    run_fail pmp free not-exist.conf
    assert_match "No such file or directory"

    run_fail pmp free "$(basename "$TMP_DIR")/b.conf"
    assert_match "is not directly"

    run_ok pmp free "$(basename "$TMP_CONF")"
    [[ -f $TMP_CONF && ! -h $TMP_CONF ]]
    [[ ! -e "$PMP_REPO/$(basename "$TMP_CONF")" ]]
    run_fail pmp config --get-regexp "cfg.'$(basename "$TMP_CONF")'*"

    run_ok pmp free "$(basename "$TMP_DIR")"
    [[ -d $TMP_DIR && ! -h $TMP_DIR ]]
    [[ ! -e "$PMP_REPO/$(basename "$TMP_DIR")" ]]
    run_fail pmp config --get-regexp "cfg.'$(basename "$TMP_DIR")'*"
}

@test "pmp sync" {
    pass
}

@test "pmp deps" {
    pass
}

