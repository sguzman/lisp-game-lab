# Distribution experiment

A native SBCL executable includes the runtime and compiled Lisp core. The shipped composition root combines the object playground with looping ambience and successful-drop sound effects. It does not load development packages, tests, hot reload or the evaluator. The bridge and two original WAV assets are located relative to the running core, not the launch directory.

## Build and run

Linux/macOS, pinned Nix inputs:

```sh
nix build .#release
./result/bin/lisp-game-lab --self-test
./result/bin/lisp-game-lab
```

Development-tree bundle: `nix develop -c make release` then `build/release/lisp-game-lab`. Linux software-rendering fallback uses `nix develop .#ci -c env XDG_SESSION_TYPE=x11 build/release/lisp-game-lab`.

Windows x86_64 uses native SBCL, GCC and Raylib from MSYS2 UCRT64. Run `make release OS=Windows_NT CC=gcc`, then `sh scripts/bundle-windows.sh` in that shell. The Windows CI records installed tool versions; the rolling MSYS2 toolchain is not pinned to the Nix lock. The build collects non-system DLLs referenced by the executable and bridge. The relocated self-test runs with only system directories on PATH and SBCL_HOME unset.

The `--self-test` switch validates native ABI, relocated assets, stacking and exclusion of dev packages without opening a window. `--smoke` opens and renders four frames with a scripted stack; `--audio-smoke` adds a three-second audio run. Real controls: mouse drag, R rotate, C cancel, M ambience, V mute, up/down volume, Space effect, Escape exit. Successful drops play a sound.

## Scope and portability

Linux/macOS Nix output is native, but not a universal redistributable tarball: it retains the Nix store runtime closure. Use Nix to transfer the closure (e.g. nix copy) or rebuild from the lock. CI artifacts alone are not sufficient on a host without the closure. Windows DLL collection is a candidate native portable folder, not an installer or signed release. macOS is not yet a signed/notarized app bundle. No multi-architecture universal binary, driver bundling or OS compatibility beyond tested runner evidence is claimed. CI attempts packaged graphics on each OS separately; hosted GUI availability may limit execution. Record actual outcomes and never infer GUI success from ABI self-test. Source and third-party license notices require a distribution review before public release; CI artifacts are laboratory candidates.

References: [SBCL manual](https://www.sbcl.org/manual/index.html), [MSYS2 SBCL](https://packages.msys2.org/packages/mingw-w64-ucrt-x86_64-sbcl), [MSYS2 Raylib](https://packages.msys2.org/packages/mingw-w64-ucrt-x86_64-raylib).
