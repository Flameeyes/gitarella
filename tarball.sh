#!/bin/sh

git-ls-files | xargs tar -jcf gitarella-$(date +"%Y-%m-%d_%H-%M").tar.bz2
