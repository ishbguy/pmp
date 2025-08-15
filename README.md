# [pmp](https://github.com/ishbguy/pmp) - Package Manager Proxy, Plus, P...

```
 _ __  _ __ ___  _ __
| '_ \| '_ ` _ \| '_ \
| |_) | | | | | | |_) |
| .__/|_| |_| |_| .__/
|_|             |_|

```

[![CI][cisvg]][ci] [![Version][versvg]][ver] [![License][licsvg]][lic]

[cisvg]: https://github.com/ishbguy/pmp/actions/workflows/bats-test.yml/badge.svg
[ci]: https://github.com/ishbguy/pmp/actions/workflows/bats-test.yml
[versvg]: https://img.shields.io/badge/version-v0.2.0-lightgrey.svg
[ver]: https://img.shields.io/badge/version-v0.2.0-lightgrey.svg
[licsvg]: https://img.shields.io/badge/license-MIT-green.svg
[lic]: https://github.com/ishbguy/pmp/blob/master/LICENSE

pmp, an unified Linux package manager and user friendly configuration manager.

## Table of Contents

- [:art: Features](#art-features)
- [:straight_ruler: Prerequisite](#straight_ruler-prerequisite)
- [:rocket: Installation](#rocket-installation)
- [:notebook: Usage](#notebook-usage)
- [:memo: Configuration](#memo-configuration)
- [:hibiscus: Contributing](#hibiscus-contributing)
- [:boy: Authors](#boy-authors)
- [:scroll: License](#scroll-license)

## :art: Features

- Unified package manager of most popular Linux distros
- Flexiblely manage your configurations
- Easily bootstrap a new system or environment
- Versioning control powered by git

## :straight_ruler: Prerequisite

> - bash
> - awk
> - git

## :rocket: Installation

```sh
git clone https://github.com/ishbguy/pmp && ./pmp self-install
```

or

```sh
curl -fLo pmp https://rawgithubusercontent.com/ishbguy/pmp/main/pmp && ./pmp self-install
```

## :notebook: Usage

```
pmp v0.2.0
pmp [-frIvhD] [file|dir] <cmd> args...

    -f  specify the configuration file
    -r  specify the repo directory
    -I  self install and update
    -v  print version number
    -h  print this help message
    -D  turn on debug mode

General commands:

    self-install   self install and update
    version        print version number
    help           print this help message

Linux package managment commands:

    install     install packages
    remove      remove packages
    autoremove  automatically remove all unused packages
    update      update list of available packages
    upgrade     upgrade the system by installing/upgrading packages
    search      search packages
    list        list installed packages
    info        show package infomations
    files       list all files owned by a package
    owns        list packages provide the given file
    clean       clean the local repository of retrieved package files (cache)
    source      list the repository list

Configuration managment commands:

    init        init a new configuration repo
    clone       clone a configuration repo
    config      configuration operations of pmp and git repo
    pin         add package deps to pmp configuration file
    unpin       rmove package deps to pmp configuration file
    keep        add configuration files to the repo
    free        remove configuration files from the repo
    sync        install dependence packages and configure
    deps        show packages deps

Others commands will be passed to git, you can type 'git help <cmd>' for help.

This program is released under the terms of the MIT License.
```

## :memo: Configuration

- `PMP_REPO`: Environment variable of pmp repo.
- `PMP_CONF`: Environment variable of pmp configuration file.

## :hibiscus: Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## :boy: Authors

- [ishbguy](https://github.com/ishbguy)

## :scroll: License

Released under the terms of [MIT License](./LICENSE).
