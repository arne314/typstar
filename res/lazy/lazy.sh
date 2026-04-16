#!/bin/sh
REPO=$(git rev-parse --show-toplevel)
cd "$REPO"

export XDG_CONFIG_HOME="$REPO/lazy_temp/config"
export XDG_DATA_HOME="$REPO/lazy_temp/data"
export XDG_STATE_HOME="$REPO/lazy_temp/state"
export XDG_CACHE_HOME="$REPO/lazy_temp/cache"
mkdir -p "$XDG_CONFIG_HOME/nvim"
cp ./res/lazy/init.lua "$XDG_CONFIG_HOME/nvim/"

exec nvim "$@"
