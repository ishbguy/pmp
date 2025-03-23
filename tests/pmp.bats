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
    assert_match "$(awk -F= '/^ID=/ {print $2}' /etc/os-release)"
    run pmp install
    assert_failure
}

@test "pmp bootstrap" {
    pass
}

@test "pmp config" {
    local PMP_REPO="$PROJECT_TMP_DIR/pmp"
    local PMP_CONF="$PMP_REPO/pmp.conf"

    run pmp config
    assert_failure
    assert_match "error"
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

    git init "$PMP_REPO"
    touch "$PMP_REPO/pmp.conf"
    git -C "$PMP_REPO" add pmp.conf
    git -C "$PMP_REPO" commit -am 'test'

    run pmp config --local core.bare
    assert_success
    assert_match "false"
}

@test "pmp init" {
    local PMP_REPO="$PROJECT_TMP_DIR/pmp"
    local PMP_CONF="$PMP_REPO/pmp.conf"
    mkdir -p "$PMP_REPO"
    
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
