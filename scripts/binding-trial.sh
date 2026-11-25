#!/bin/sh
set -eu

# Optional Linux-only experiment; upstream checkouts are supplied by CI.
# Use the same shared Raylib as the baseline instead of compiling a second copy.
root=$(pwd -P)
upstream="$root/build/binding-trial/raylib"
garbage="$root/build/binding-trial/trivial-garbage"
test "$(git -C "$upstream" rev-parse HEAD)" = 4ab295114348a84a1d2a6d1472fd1610a5c706ff
test "$(git -C "$garbage" rev-parse HEAD)" = f0663f7b0c900ed78ac19f6db306e7c6cac999fd
libdir=$(pkg-config --variable=libdir raylib)
test -f "$libdir/libraylib.so"
cd "$upstream"
mkdir -p lib
ln -sf "$libdir/libraylib.so" lib/liblisp-raylib.so
# Explicitly use Nix's matching Raylib header. A copy of the upstream shim
# outside its source directory avoids resolving a vendored header first.
cp c/shim.c lib/trial-shim.c
${CC:-cc} -O2 -fPIC -shared -Wl,-z,defs -o lib/liblisp-raylib-shim.so \
  lib/trial-shim.c $(pkg-config --cflags --libs raylib)
export LAB_TRIAL_GARBAGE="$garbage/trivial-garbage.asd"
export LAB_TRIAL_ASSET="$root/assets/02-rendering/crate.png"
sbcl --noinform --non-interactive --load "$root/scripts/binding-trial.lisp"
