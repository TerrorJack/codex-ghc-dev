#!/usr/bin/env bash

set -euo pipefail

GITHUB_WORKSPACE=/workspace/ghc

apt install --yes \
  libtool-bin

git clone \
  --depth=1 \
  --jobs=32 \
  --recurse-submodules \
  --shallow-submodules \
  https://github.com/haskell-llms/ghc.git \
  $GITHUB_WORKSPACE

trap "rm -rf $GITHUB_WORKSPACE" EXIT

tar xJf /workspace/ghc.tar.xz -C /

. ~/.ghcup/env

pushd $GITHUB_WORKSPACE

echo :q | HADRIAN_ARGS=-j ./hadrian/ghci-multi -j

popd
