# Current state

Completed: experiment 01 (foundation, with software-rendering development path).
Active next: experiment 02 (rendering).

## Verified evidence

[CI run 45680276205](https://github.com/sguzman/lisp-game-lab/actions/runs/45680276205), code commit `c308cb1`:

| Gate | Linux | macOS |
| --- | --- | --- |
| Committed lockfile, style, unit tests, native bridge, ABI probe | Pass | Prior build passed; newer jobs cancelled |
| Playground compilation | Pass | Prior build passed; newer jobs cancelled |
| Bounded graphical smoke | Pass: exactly 3 frames | Not configured |

Linux job 139438669650 logged "World tests passed.", "Raylib bridge ABI probe passed.", Mesa llvmpipe (LLVM 21.1.8) and "Rendered 3 frames successfully." The original GLX failure is resolved in hosted Linux CI. The Nix lockfile is tracked and validated against HEAD. Prior macOS job 139435973587 passed its build and ABI gates; the newer macOS jobs were cancelled, so the earlier pass remains the available evidence.

[Raylib binding assessment](raylib-bindings.md) records the provisional baseline decision. No comparative binding runtime test has been performed yet.

## Local visual/input QA

On the Linux development machine, clone or update the repository and run:

```sh
nix develop -c make run
```

Expected: an 800x480 window, dark background, amber square, heading, arrow keys move the square and stop at the viewport edges, Escape closes the window. Confirm that the window opens, the controls work, and the process exits cleanly. The ordinary shell does not force software rendering. If graphics initialization fails, retain the terminal output; use the separate CI shell as a diagnostic only (`nix develop .#ci -c make run`), not the preferred GPU configuration.

Local QA report: all six Lisp source files compiled in 0–6 ms per file and the C bridge compiled and loaded. GLFW then failed to obtain an EGL display (65542), so no window was rendered. Fontconfig also emitted configuration warnings; these are not the fatal error. This is a host graphics initialization failure, not a Lisp compile failure.

First diagnostic, with no Nix input changes: `nix develop -c env XDG_SESSION_TYPE=x11 make run`. GLFW 3.4 selects X11 when both backends are compiled in and DISPLAY is available. On Hyprland this uses XWayland. If that fails, try the existing software-rendering CI shell: `nix develop .#ci -c env XDG_SESSION_TYPE=x11 make run`. The latter may require additional cached packages. User subsequently confirmed the second command (CI software-rendering shell with X11 session selection) worked, without pulling the documentation-only commit. No screenshot or full log was uploaded due to connectivity. The user explicitly confirmed on 2026-11-25 that the square was controllable and the experiment worked. Accept local visual/input QA on that basis; viewport clamping is covered by the headless world tests and bounded shutdown by the Linux graphical smoke. Individual manual boundary and Escape checks were not separately reported. Hardware acceleration remains unverified. The result supports using this route for interim development; it does not isolate the underlying EGL/vendor failure. Investigate host GL integration separately without forcing a dependency upgrade. Do not change system graphics drivers or lockfile merely to diagnose this.

## Next unfinished gates

1. Advance to experiment 02: narrow existing-binding trial, texture rendering, layers, camera and draw ordering using disposable assets.
2. Retain the passing baseline and headless/graphical CI checks; batch local visual QA.
3. Track hardware-accelerated Linux graphics integration separately; the confirmed software-rendering path is sufficient for initial 2D experiments. Do not block rendering work on this or request duplicate foundation QA.

Windows distribution and macOS graphical execution remain unverified. See [roadmap](roadmap.md).

## Nix release policy

Per user direction, flake.nix now names nixos-26.05 and flake.lock retains the identical previously verified locked revision and hash. Only the original input reference metadata changed. [CI run 45681665724](https://github.com/sguzman/lisp-game-lab/actions/runs/45681665724) passed every Linux gate including lock validation and graphical smoke; the macOS job was cancelled, with the earlier macOS build/ABI pass still the available evidence. Local software-rendering startup is user-confirmed.

## Experiment 02 — first implementation

Added a headless sprite/camera model, stable layer/depth ordering, a separate rendering ASDF system, four original disposable PNG textures, explicit texture cache ownership with unwind cleanup, and a bounded smoke checking four unique texture handles and three completed frames. The existing foundation demo remains runnable. The ABI version is now 2.

No flake or lockfile changes. The upstream binding comparison confirmed fosskers has texture and camera wrappers, but its separate vendored Raylib build and shim require a separate reproducible trial. Keep the small baseline adapter for this scene; do not claim upstream runtime validation. Next: inspect new CI, complete the upstream trial, then batch local visual QA. For the next QA, explicitly request git pull --ff-only and use the known working software shell.

## Experiment 02 — CI evidence and binding trial

[CI run 45690527757](https://github.com/sguzman/lisp-game-lab/actions/runs/45690527757), code commit `fd2f9c9`: Linux job 139474471448 passed lock validation, style, unit tests, ABI probe, both ASDF compilation steps and both graphical smoke tests. Logs show four 32x32 RGBA PNGs loaded, "Rendering smoke: 3 frames, 4 unique textures." and all four texture IDs unloaded from VRAM. macOS was still running when inspected. Actual visual appearance and camera input await human QA; ordering/camera logic is covered by headless tests.

Added an isolated Linux CI binding trial with pinned fosskers/raylib and trivial-garbage source checkouts. It builds the upstream shim against the existing Nix Raylib header/library rather than compiling the vendored copy, and checks texture dimensions/validity, camera transform, input query, bounded rendering and explicit unload. No default dependencies or Nix pins changed. This is a compatibility experiment, not yet a verified alternative adapter. Next: inspect binding trial CI and any outstanding macOS results; then request a single rendering QA pass (pull required, existing software shell).
