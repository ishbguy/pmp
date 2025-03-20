#!/usr/bin/env bats

load bats-helper
load pmp-helper

@test "pmp no-such-cmd" {
    run pmp no-such-cmd
    assert_match "No such command"
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
    pass
}

@test "pmp git" {
    pass
}
