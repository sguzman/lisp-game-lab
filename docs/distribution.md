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

## First distribution trial and corrective action

[Run 45717526458](https://github.com/sguzman/lisp-game-lab/actions/runs/45717526458): Windows native build and relocated headless self-test passed (ABI 6, assets, stacking, absence of development packages). Its ordinary graphical launch failed with GLFW WGL error 65542 (host driver does not support OpenGL); the step's continue-on-error makes the job green, not the graphical test. Linux and macOS Nix derivation builds failed during ASDF loading, with only the final 25 lines visible. The next trial assigns a writable build-local HOME and XDG cache (hypothesis, not confirmed root cause) and enables full Nix build logs. Windows additionally attempts Mesa llvmpipe using a separate CI-only folder after uploading the original hardware-driver bundle; the software DLLs are not shipped in that bundle. See [MSYS2 UCRT64 Mesa package](https://packages.msys2.org/packages/mingw-w64-ucrt-x86_64-mesa) for the provided OpenGL and Gallium DLLs.

## Verified native release evidence — 2026-11-25

[Distribution CI 45718400937](https://github.com/sguzman/lisp-game-lab/actions/runs/45718400937), revision `f91e9098f98644cb22c11d15e041b8999d4f6c17`.

| Target | Native build | Relocated executable self-test | Packaged GUI | Packaged audio | Artifact |
| --- | --- | --- | --- | --- | --- |
| Linux x86_64 | Pass | Pass | Pass, 180 frames, Xvfb/llvmpipe | Pass, null device; not audible | [12,521,717 bytes](https://github.com/sguzman/lisp-game-lab/actions/runs/45718400937/artifacts/15070249473) |
| macOS ARM64 | Pass | Pass | Failed: NSGL 65545, no suitable pixel format | Not run | [12,276,265 bytes](https://github.com/sguzman/lisp-game-lab/actions/runs/45718400937/artifacts/15070349318) |
| Windows x86_64 | Pass | Pass, system-only PATH and SBCL_HOME unset | Pass, 4 frames with CI-only llvmpipe; original driver failed WGL 65542 | Not run | [14,132,621 bytes](https://github.com/sguzman/lisp-game-lab/actions/runs/45718400937/artifacts/15070328250) |

Artifacts are CI candidates, subject to retention. The Windows artifact does not include the Mesa fallback used for testing. The Unix artifacts retain Nix closure requirements. The macOS executable runs headlessly outside the source tree; graphical compatibility cannot be established on this runner. No claim of hardware acceleration, signing, broad OS compatibility, audible output on all platforms or production-ready redistributables. The final local Linux QA combines gameplay and actual audible playback. Separate [regression CI 45718401081](https://github.com/sguzman/lisp-game-lab/actions/runs/45718401081) passed both configured platforms.

## Final local acceptance

On 2026-11-25 the user completed the combined release QA at checkout `da757d9`. The supplied log shows successful compilation, window creation (GLFW/X11, llvmpipe), PulseAudio initialization, loading both packaged WAV assets, and orderly stream, device, graphics and window shutdown. The user's completion response is accepted as the manual check; no independent recording of audible quality or individual input events was supplied. No further local QA is required. The platform limitations above remain unchanged.
