#!/usr/bin/env bash
# Copyright (c) 2025 Herbert Shen <ishbguy@hotmail.com> All Rights Reserved.
# Released under the terms of the MIT License.

# source guard
[[ $MIRROR_SET_SOURCED -eq 1 ]] && return
readonly MIRROR_SET_SOURCED=1
readonly MIRROR_SET_ABS_SRC="$(readlink -f "${BASH_SOURCE[0]}")"
readonly MIRROR_SET_ABS_DIR="$(dirname "$MIRROR_SET_ABS_SRC")"

# Utils
MIRROR_SET_EXIT_CODE=0
MIRROR_SET_WARN_CODE=0
warn() { echo -e "WARN:" "$@" >&2; return $((++MIRROR_SET_WARN_CODE)); }
error() { echo -e "ERROR:" "$@" >&2; return $((++MIRROR_SET_EXIT_CODE)); }
die() { echo -e "ERROR:" "$@" >&2; exit $((++MIRROR_SET_EXIT_CODE)); }
info() { echo -e "INFO:" "$@" >&2; }
debug() { [[ $DEBUG == 1 ]] && echo -e "DEBUG:" "$@" >&2 || true; }
usage() { echo -e "$HELP"; }
version() { echo -e "$PROGRAM $VERSION"; }
defined() { declare -p "$1" &>/dev/null; }
definedf() { declare -f "$1" &>/dev/null; }
is_sourced() { [[ -n ${FUNCNAME[1]} && ${FUNCNAME[1]} != "main" ]]; }
is_array() { local -a def=($(declare -p "$1" 2>/dev/null)); [[ ${def[1]} =~ a ]]; }
is_map() { local -a def=($(declare -p "$1" 2>/dev/null)); [[ ${def[1]} =~ A ]]; }
has_tool() { hash "$1" &>/dev/null; }
ensure() {
    local cmd="$1"; shift
    local -a info=($(caller 0))
    (eval "$cmd" &>/dev/null) || \
       die "${info[2]}:${info[0]}:${info[1]}:${FUNCNAME[0]} '$cmd' failed. " "$@"
}
date_cmp() { echo "$(($(date -d "$1" +%s) - $(date -d "$2" +%s)))"; }
tmpfd() { basename <(:); }
pargs() {
    ensure "[[ $# -ge 3 ]]" "Need OPTIONS, ARGUMENTS and OPTSTRING"
    ensure "[[ -n $1 && -n $2 && -n $3 ]]" "Args should not be empty."
    ensure "is_map $1 && is_map $2" "OPTIONS and ARGUMENTS should be map."

    local -n __opt="$1"
    local -n __arg="$2"
    local optstr="$3"
    shift 3

    OPTIND=1
    while getopts "$optstr" opt; do
        [[ $opt == ":" || $opt == "?" ]] && die "$HELP"
        __opt[$opt]=1
        __arg[$opt]="$OPTARG"
    done
    shift $((OPTIND - 1))
}
trap_push() {
    ensure "[[ $# -ge 2 ]]" "Usage: trap_push 'cmds' SIGSPEC..."
    local cmds="$1"; shift
    for sig in "$@"; do
        defined "trap_$sig" || declare -ga "trap_$sig"
        local -n ts="trap_$sig"
        ts+=("$cmds")
        if [[ $sig == RETURN ]]; then
            trap "trap '$cmds; trap_pop RETURN' RETURN" RETURN 
        else
            trap "$cmds" "$sig"
        fi
    done
}
trap_pop() {
    ensure "[[ $# -ge 1 ]]" "Usage: trap_pop SIGSPEC..."
    for sig in "$@"; do
        defined "trap_$sig" || declare -ga "trap_$sig"
        local -n ts="trap_$sig"
        local cmds
        # pop cmds
        ts=("${ts[@]:0:$((${#ts[@]}-1))}")
        [[ ${#ts[@]} -gt 0 ]] && cmds="${ts[-1]}"
        if [[ $sig == RETURN ]]; then
            trap "trap '$cmds' RETURN" RETURN
        else
            trap "$cmds" "$sig"
        fi
    done
}
require() {
    ensure "[[ $# -gt 2 ]]" "Not enough args."
    ensure "definedf $1" "$1 should be a defined func."

    local -a miss
    local cmd="$1"
    local msg="$2"
    shift 2
    for obj in "$@"; do
        "$cmd" "$obj" || miss+=("$obj")
    done
    [[ ${#miss[@]} -eq 0 ]] || die "$msg: ${miss[*]}."
}
require_var() { require defined "You need to define vars" "$@"; }
require_func() { require definedf "You need to define funcs" "$@"; }
require_tool() { require has_tool "You need to install tools" "$@"; }
inicfg() { require_tool git; git config --file "$@"; }

mirror_set() {
    local PROGRAM="$(basename "${BASH_SOURCE[0]}")"
    local VERSION="v0.1.0"
    local HELP=$(cat <<EOF
$PROGRAM $VERSION
$PROGRAM [-hvD] <distro>
    
    -v  print version number
    -h  print this help message 
    -D  turn on debug mode

This program is released under the terms of the MIT License.
EOF
)
    local -A opts=() args=()
    pargs opts args 'hvD' "$@"
    shift $((OPTIND - 1))
    [[ ${opts[D]} ]] && set -x
    [[ ${opts[h]} ]] && usage && return 0
    [[ ${opts[v]} ]] && version && return 0

    [[ 0 -eq "$(id -u)" ]] || die "YOU MUST RUN TOOL UNDER ROOT!"

    case $1 in
        arch|archlinux)
            sed -ri -e '1iServer = https://mirrors.aliyun.com/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist
            ;;
        debian)
            sed -i -e "s|http://deb.debian.org|http://mirrors.aliyun.com|" /etc/apt/sources.list.d/debian.sources
            sed -i -e "s|http://security.debian.org|http://mirrors.aliyun.com/debian-security|" /etc/apt/sources.list.d/debian.sources
            ;;
        ubuntu)
            sed -i -e 's|//.*archive.ubuntu.com|//mirrors.ustc.edu.cn|g' /etc/apt/sources.list.d/ubuntu.sources
            sed -i -e 's|security.ubuntu.com|mirrors.ustc.edu.cn|g' /etc/apt/sources.list.d/ubuntu.sources
            ;;
        fedora)
            sed -e 's|^metalink=|#metalink=|g' \
                -e 's|^#baseurl=http://download.example/pub/fedora/linux|baseurl=https://mirrors.aliyun.com/fedora|g' \
                -i.bak /etc/yum.repos.d/fedora.repo /etc/yum.repos.d/fedora-updates.repo
            ;;
        redhat*) : ;;
        opensuse/leap)
            zypper mr -da
            zypper ar -cfg 'https://mirrors.aliyun.com/opensuse/distribution/leap/$releasever/repo/oss/' mirror-oss
            zypper ar -cfg 'https://mirrors.aliyun.com/opensuse/distribution/leap/$releasever/repo/non-oss/' mirror-non-oss
            zypper ar -cfg 'https://mirrors.aliyun.com/opensuse/update/leap/$releasever/oss/' mirror-update
            zypper ar -cfg 'https://mirrors.aliyun.com/opensuse/update/leap/$releasever/non-oss/' mirror-update-non-oss
            zypper ar -cfg 'https://mirrors.aliyun.com/opensuse/update/leap/$releasever/sle/' mirror-sle-update
            zypper ar -cfg 'https://mirrors.aliyun.com/opensuse/update/leap/$releasever/backports/' mirror-backports-update
            ;;
        opensuse/tumbleweed)
            zypper mr -da
            zypper ar -cfg 'https://mirrors.ustc.edu.cn/opensuse/tumbleweed/repo/oss/' mirror-oss
            zypper ar -cfg 'https://mirrors.ustc.edu.cn/opensuse/tumbleweed/repo/non-oss/' mirror-non-oss
            zypper ar -fcg 'https://mirrors.ustc.edu.cn/opensuse/update/tumbleweed' mirror-update
            ;;
        *openwrt|*immortalwrt)
            sed -i 's|-SNAPSHOT|.0|g' /etc/opkg/distfeeds.conf
            sed -i 's|immortalwrt|openwrt|g' /etc/opkg/distfeeds.conf
            sed -i 's|https\?://downloads.openwrt.org|https://mirrors.aliyun.com/openwrt|' /etc/opkg/distfeeds.conf
            [[ -d /var/lock ]] || mkdir -p /var/lock || die "Can not mkdir -p /var/lock!"
            opkg update
            opkg install coreutils-nl
            ;;
        *) die "No such distro: ${1@Q}" ;;
    esac
}

is_sourced || mirror_set "$@"

# vim:set ft=sh ts=4 sw=4:
