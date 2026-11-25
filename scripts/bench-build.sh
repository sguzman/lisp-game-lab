#!/bin/sh
# Fresh ASDF cache per trial; preserve the user's normal cache.
set -eu
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
echo "BENCH_ENV revision=$(git rev-parse HEAD) os=$(uname -s) arch=$(uname -m)"
uname -a
sbcl --version
pkg-config --modversion raylib
if [ "$(uname -s)" = Linux ]; then
    grep -m 1 'model name' /proc/cpuinfo || true
    grep '^MemTotal:' /proc/meminfo || true
else
    sysctl -n machdep.cpu.brand_string 2>/dev/null || true
    sysctl -n hw.memsize 2>/dev/null || true
fi
for i in 1 2 3; do
    export XDG_CACHE_HOME="$scratch/$i"
    mkdir -p "$XDG_CACHE_HOME"
    echo "BENCH_BUILD cold trial=$i"
    time sbcl --noinform --non-interactive --load scripts/bench-load.lisp
    echo "BENCH_BUILD warm trial=$i"
    time sbcl --noinform --non-interactive --load scripts/bench-load.lisp
done
