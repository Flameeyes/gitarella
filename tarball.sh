#!/bin/sh

if [[ $# -ge 1 ]]; then
  version=$1
else
  version=$(date +"%Y-%m-%d_%H-%M")
fi

rm -rf "gitarella-${version}"
mkdir "gitarella-${version}"
git-ls-files | xargs tar cf - | tar xf - -C "gitarella-${version}"

tar -jcf "gitarella-${version}.tar.bz2" "gitarella-${version}"
