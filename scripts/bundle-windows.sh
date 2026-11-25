#!/bin/sh
# Collect UCRT64 DLLs recursively, excluding Windows system DLLs.
set -eu
bundle=build/release
scan="$bundle/lisp-game-lab.exe $bundle/lab-raylib.dll"
while [ -n "$scan" ]; do
    next=""
    for binary in $scan; do
        for dll in $(objdump -p "$binary" | awk '/DLL Name:/ {print $3}'); do
            if [ -f "/ucrt64/bin/$dll" ] && [ ! -f "$bundle/$dll" ]; then
                cp "/ucrt64/bin/$dll" "$bundle/$dll"
                next="$next $bundle/$dll"
            fi
        done
    done
    scan="$next"
done
ls -lh "$bundle"
