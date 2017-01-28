# ghr

[![Build Status](https://travis-ci.org/kobanyan/ghr.svg?branch=master)](https://travis-ci.org/kobanyan/ghr)

A fish shell to install a binary from GitHub releases

## Synopsis

`ghr <repo> [-t tag] [-n name]`

## Options

|||
|-|-|
|-h, --help|Show usage help|
|-n, --name NAME|Save binary as NAME|
|-t, --tag TAG|Download from TAG|

## Usage

### Install latest version  

`ghr peco/peco`

### Install as alias  

`ghr junegunn/fzf-bin -n fzf`

### Install from specified tag  

`ghr stedolan/jq -t jq-1.5rc2`
