#!/bin/sh
NVIM_BIN="$(which nvim)"
set -- "$@"
filtered_args=""

# filter out --clean argument to make nix injected rc work
for arg; do
    if [ "$arg" != "--clean" ]; then
        filtered_args="$filtered_args \"$arg\""
    fi
done

echo "running filtered nvim"
eval exec "$NVIM_BIN" $filtered_args
