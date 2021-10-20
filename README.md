# ghr

[![Build Status](https://travis-ci.org/kobanyan/ghr.svg?branch=master)](https://travis-ci.org/kobanyan/ghr)

A fish shell to install a binary from GitHub releases

## Install

With [fisherman](https://github.com/fisherman/fisherman)

```fish
fisher install jorgebucaran/getopts.fish americanhanko/fish-spin kobanyan/ghr
```

## Synopsis

```fish
ghr <repo> [-t tag] [-n name]
```

## Options

|||
| --- | --- |
| -h, --help | Show usage help |
| -n, --name NAME | Save binary as NAME |
| -t, --tag TAG | Download from TAG |

## Usage

### Install latest version  

```fish
ghr peco/peco
```

### Install as alias  

```fish
ghr junegunn/fzf-bin -n fzf
```

### Install from specified tag  

```fish
ghr stedolan/jq -t jq-1.5rc2
```

## License

MIT

## Author Information

[kobanyan](https://github.com/kobanyan)
