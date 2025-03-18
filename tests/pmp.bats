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
    assert_match "pmp $VERSION"
}

@test "pmp help" {
    run pmp
    assert_match "print this help message"
    run pmp -h
    assert_match "print this help message"
}

@test "pmp install" {
    pass
}

@test "pmp remove" {
    pass
}

@test "pmp autoremove" {
    pass
}

@test "pmp update" {
    pass
}

@test "pmp upgrade" {
    pass
}

@test "pmp search" {
    pass
}

@test "pmp list" {
    pass
}

@test "pmp info" {
    pass
}

@test "pmp files" {
    pass
}

@test "pmp owns" {
    pass
}

@test "pmp clean" {
    pass
}

@test "pmp repo" {
    pass
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
