# docker build -t ghr .

FROM ubuntu:bionic

COPY . /root/ghr

ARG GHR_TOKEN

RUN apt update \
  && apt install -y software-properties-common \
  && apt-add-repository -y ppa:fish-shell/release-3 \
  && apt update \
  && apt install -y curl fish git tar unzip \
  && fish -c "curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher" \
  && fish -c "fisher install jorgebucaran/getopts.fish americanhanko/fish-spin ~/ghr" \
  && GHR_TOKEN=$GHR_TOKEN cat ~/ghr/test/test.fish | fish
