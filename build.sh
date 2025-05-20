#!/usr/bin/env bash

set -euo pipefail

GITHUB_WORKSPACE=/workspace/ghc

apt install --yes \
  libtool-bin \
  zstd

curl -f -L https://get-ghcup.haskell.org | BOOTSTRAP_HASKELL_CABAL_VERSION=latest BOOTSTRAP_HASKELL_GHC_VERSION=latest BOOTSTRAP_HASKELL_INSTALL_NO_STACK=1 BOOTSTRAP_HASKELL_NONINTERACTIVE=1 bash

. ~/.ghcup/env

cabal install \
  alex \
  happy

git clone \
  --depth=1 \
  --jobs=32 \
  --recurse-submodules \
  --shallow-submodules \
  https://github.com/ghc/ghc.git \
  $GITHUB_WORKSPACE

trap "rm -rf $GITHUB_WORKSPACE" EXIT

pushd $GITHUB_WORKSPACE

hadrian/build --version

./boot

./configure

echo :q | HADRIAN_ARGS=-j ./hadrian/ghci-multi -j

popd

git -C "$GITHUB_WORKSPACE" ls-files -oi --exclude-standard -z \
  | sed -z "s|^|$GITHUB_WORKSPACE/|" >> /tmp/listing

git -C "$GITHUB_WORKSPACE" submodule foreach --quiet --recursive '
  git ls-files -oi --exclude-standard -z \
    | sed -z "s|^|$toplevel/$path/|" >> /tmp/listing
'

printf "%s\0" /root/.ghcup /root/.cabal >> /tmp/listing

rm -rf \
  ~/.cabal/logs \
  ~/.ghcup/cache \
  ~/.ghcup/logs

tar --create \
    --null --files-from=/tmp/listing \
    --absolute-names -P \
    --file=/tmp/ghc.tar

zstd -T0 --ultra -22 /tmp/ghc.tar -o /workspace/ghc.tar.zst
