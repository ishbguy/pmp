#!/usr/bin/env bats

load bats-helper
load pmp-helper

@test "pmp no-such-cmd" {
    local PMP_REPO="$PROJECT_TMP_DIR/pmp"
    local PMP_CONF="$PMP_REPO/pmp.conf"

    run pmp no-such-cmd
    assert_match "not a git command"
}

@test "pmp debug" {
    run pmp -D
    assert_match "^\+"
}

@test "pmp version" {
    run pmp -v
    assert_match "pmp v([0-9]+.?){3}"
    run pmp version
    assert_match "pmp v([0-9]+.?){3}"
}

@test "pmp help" {
    run pmp
    assert_match "print this help message"
    run pmp -h
    assert_match "print this help message"
    run pmp help
    assert_match "print this help message"
}

@test "pmp linux_pma" {
    run linux_pma
    assert_match "$(awk -F= '/^ID=/ {gsub(/-/, "_", $2); gsub(/"/, "", $2); print $2}' /etc/os-release)"

    run pmp update
    assert_success

    run pmp search tmux
    assert_success
    assert_match "tmux"

    run pmp install -y tmux
    assert_success

    run pmp remove -y tmux
    assert_success

    run pmp install -y tmux
    run pmp autoremove -y tmux
    assert_success

    run pmp install -y tmux
    run pmp list
    assert_success
    assert_match "tmux"

    run pmp info tmux
    assert_success
    assert_match "tmux"

    run pmp files tmux
    assert_success
    assert_match "tmux"

    run pmp owns tmux
    assert_success

    run pmp clean -y
    assert_success

    run pmp source
    assert_success
}

@test "pmp init" {
    local PMP_REPO="$PROJECT_TMP_DIR/pmp"
    local PMP_CONF="$PMP_REPO/pmp.conf"

    run pmp init
    assert_success
    assert_match "Initialized empty Git repository"
    [[ -e $PMP_CONF ]]

    rm -rf "$PMP_REPO" && mkdir -p "$PMP_REPO"
    run pmp init "$PMP_REPO"
    assert_success
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

    run pmp clone "$PMP_REMOTE" "$PMP_REPO"
    assert_success
    assert_match "Cloning into '$PMP_REPO'"
    [[ -e $PMP_CONF ]]
}

@test "pmp config" {
    local PMP_REPO="$PROJECT_TMP_DIR/pmp"
    local PMP_CONF="$PMP_REPO/pmp.conf"

    run pmp config
    assert_failure
    # assert_match "error"
    [[ -e $PMP_CONF ]]

    run pmp config pmp.repo "$PMP_REPO"
    assert_success
    run pmp config -l
    assert_success
    assert_match "pmp.repo=$PMP_REPO"

    run pmp config pmp.repo
    assert_success
    assert_match "$PMP_REPO"

    run pmp config --unset pmp.repo
    assert_success
    run pmp config pmp.repo
    assert_failure

    pmp init

    run pmp config --local core.bare
    assert_success
    assert_match "false"
}

@test "pmp pin & unpin" {
    local PMP_REPO="$PROJECT_TMP_DIR/pmp"
    local PMP_CONF="$PMP_REPO/pmp.conf"

    pmp init

    run pmp pin git
    assert_success
    run pmp config cmd.git
    assert_success
    run pmp pin vim tmux
    assert_success
    run pmp config cmd.vim
    assert_success
    run pmp config cmd.tmux
    assert_success

    run pmp unpin git
    assert_success
    run pmp config cmd.git
    assert_failure
    run pmp unpin vim tmux
    assert_success
    run pmp config cmd.vim
    assert_failure
    run pmp config cmd.tmux
    assert_failure
}

@test "pmp keep & free" {
    local PMP_REPO="$PROJECT_TMP_DIR/pmp"
    local PMP_CONF="$PMP_REPO/pmp.conf"
    local TMP_CONF="$PROJECT_TMP_DIR/a.conf"
    local TMP_DIR="$PROJECT_TMP_DIR/b"

    pmp init
    touch "$TMP_CONF"
    mkdir -p "$TMP_DIR" && touch "$TMP_DIR/b.conf"

    run pmp keep
    assert_failure
    assert_match "Usage: pmp keep"

    run pmp keep not-exist
    assert_failure
    assert_match "No such file or directory"

    run pmp keep "$TMP_CONF"
    assert_success
    assert_match "keep $TMP_CONF"
    [[ -h $TMP_CONF ]]
    [[ -f "$PMP_REPO/$(basename "$TMP_CONF")" ]]
    [[ "$(readlink -f "$TMP_CONF")" == "$(readlink -f "$PMP_REPO/$(basename "$TMP_CONF")")" ]]
    run pmp config --get-regexp "cfg.'$(basename "$TMP_CONF")'*"
    assert_success
    assert_match "$TMP_CONF"

    run pmp keep "$TMP_CONF"
    assert_failure
    assert_match "already exist"

    run pmp keep "$TMP_CONF" test/"$(basename "$TMP_CONF")"
    assert_success
    [[ -h $TMP_CONF ]]
    [[ -f "$PMP_REPO/test/$(basename "$TMP_CONF")" ]]
    [[ "$(readlink -f "$TMP_CONF")" == "$(readlink -f "$PMP_REPO/test/$(basename "$TMP_CONF")")" ]]
    run pmp config --get-regexp "cfg.'test/$(basename "$TMP_CONF")'*"
    assert_success
    assert_match "$TMP_CONF"

    run pmp keep "$TMP_DIR"
    assert_success
    assert_match "keep $TMP_DIR"
    [[ -h $TMP_DIR ]]
    [[ -d "$PMP_REPO/$(basename "$TMP_DIR")" ]]
    [[ "$(readlink -f "$TMP_DIR")" == "$(readlink -f "$PMP_REPO/$(basename "$TMP_DIR")")" ]]
    run pmp config --get-regexp "cfg.'$(basename "$TMP_DIR")'*"
    assert_success
    assert_match "$TMP_DIR"

    touch "$HOME/pmp-test.conf"
    run pmp keep "$HOME/pmp-test.conf"
    assert_success
    assert_match 'keep \$HOME/pmp-test.conf'
    [[ -h $HOME/pmp-test.conf ]]
    [[ -f "$PMP_REPO/pmp-test.conf" ]]
    [[ "$(readlink -f "$HOME/pmp-test.conf")" == "$(readlink -f "$PMP_REPO/pmp-test.conf")" ]]
    run pmp config --get-regexp "cfg.'pmp-test.conf'*"
    assert_success
    assert_match '\$HOME/pmp-test.conf'
    rm -rf "$HOME"/pmp-test.conf*

    run pmp free
    assert_failure
    assert_match "Usage: pmp free"

    run pmp free not-exist.conf
    assert_failure
    assert_match "No such file or directory"

    run pmp free "$(basename "$TMP_DIR")/b.conf"
    assert_failure
    assert_match "is not directly"

    run pmp free "$(basename "$TMP_CONF")"
    assert_success
    [[ -f $TMP_CONF && ! -h $TMP_CONF ]]
    [[ ! -e "$PMP_REPO/$(basename "$TMP_CONF")" ]]
    run pmp config --get-regexp "cfg.'$(basename "$TMP_CONF")'*"
    assert_failure

    run pmp free "$(basename "$TMP_DIR")"
    assert_success
    [[ -d $TMP_DIR && ! -h $TMP_DIR ]]
    [[ ! -e "$PMP_REPO/$(basename "$TMP_DIR")" ]]
    run pmp config --get-regexp "cfg.'$(basename "$TMP_DIR")'*"
    assert_failure
}

@test "pmp sync" {
    pass
}

@test "pmp deps" {
    pass
}

