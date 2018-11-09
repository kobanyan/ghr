# docker build -t ghr .

FROM ubuntu:bionic

COPY . /root/ghr

ARG GHR_TOKEN

RUN apt update \
  && apt install -y software-properties-common \
  && apt-add-repository -y ppa:fish-shell/release-2 \
  && apt update \
  && apt install -y curl fish git tar unzip \
  && curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs git.io/fisher \
  && fish -c "fisher add ~/ghr" \
  && GHR_TOKEN=$GHR_TOKEN cat ~/ghr/test/test.fish | fish
