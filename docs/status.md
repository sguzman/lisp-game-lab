# Current state

Completed: experiment 01 (foundation, with software-rendering development path).
Completed: experiment 02 (rendering).
Completed: experiment 03 (live code).
Active next: experiment 04 (live assets).

## Verified evidence

[CI run 45680276205](https://github.com/sguzman/lisp-game-lab/actions/runs/45680276205), code commit `c308cb1`:

| Gate | Linux | macOS |
| --- | --- | --- |
| Committed lockfile, style, unit tests, native bridge, ABI probe | Pass | Prior build passed; newer jobs cancelled |
| Playground compilation | Pass | Prior build passed; newer jobs cancelled |
| Bounded graphical smoke | Pass: exactly 3 frames | Not configured |

Linux job 139438669650 logged "World tests passed.", "Raylib bridge ABI probe passed.", Mesa llvmpipe (LLVM 21.1.8) and "Rendered 3 frames successfully." The original GLX failure is resolved in hosted Linux CI. The Nix lockfile is tracked and validated against HEAD. Prior macOS job 139435973587 passed its build and ABI gates; the newer macOS jobs were cancelled, so the earlier pass remains the available evidence.

[Raylib binding assessment](raylib-bindings.md) records the provisional baseline decision. A later Linux compatibility trial passed; see the latest entry below.

## Local visual/input QA

On the Linux development machine, clone or update the repository and run:

```sh
nix develop -c make run
```

Expected: an 800x480 window, dark background, amber square, heading, arrow keys move the square and stop at the viewport edges, Escape closes the window. Confirm that the window opens, the controls work, and the process exits cleanly. The ordinary shell does not force software rendering. If graphics initialization fails, retain the terminal output; use the separate CI shell as a diagnostic only (`nix develop .#ci -c make run`), not the preferred GPU configuration.

Local QA report: all six Lisp source files compiled in 0–6 ms per file and the C bridge compiled and loaded. GLFW then failed to obtain an EGL display (65542), so no window was rendered. Fontconfig also emitted configuration warnings; these are not the fatal error. This is a host graphics initialization failure, not a Lisp compile failure.

First diagnostic, with no Nix input changes: `nix develop -c env XDG_SESSION_TYPE=x11 make run`. GLFW 3.4 selects X11 when both backends are compiled in and DISPLAY is available. On Hyprland this uses XWayland. If that fails, try the existing software-rendering CI shell: `nix develop .#ci -c env XDG_SESSION_TYPE=x11 make run`. The latter may require additional cached packages. User subsequently confirmed the second command (CI software-rendering shell with X11 session selection) worked, without pulling the documentation-only commit. No screenshot or full log was uploaded due to connectivity. The user explicitly confirmed on 2026-11-25 that the square was controllable and the experiment worked. Accept local visual/input QA on that basis; viewport clamping is covered by the headless world tests and bounded shutdown by the Linux graphical smoke. Individual manual boundary and Escape checks were not separately reported. Hardware acceleration remains unverified. The result supports using this route for interim development; it does not isolate the underlying EGL/vendor failure. Investigate host GL integration separately without forcing a dependency upgrade. Do not change system graphics drivers or lockfile merely to diagnose this.

## Next unfinished gates

1. Implement experiment 04: replace textures, audio and scene data without restarting; retain working assets on invalid replacements.
2. Retain foundation, rendering and live-code regression tests; batch human QA.
3. Track hardware-accelerated Linux graphics integration separately; the confirmed software-rendering path is sufficient for initial 2D experiments. Do not block rendering work on this or request duplicate foundation QA.

Windows distribution and macOS graphical execution remain unverified. See [roadmap](roadmap.md).

## Nix release policy

Per user direction, flake.nix now names nixos-26.05 and flake.lock retains the identical previously verified locked revision and hash. Only the original input reference metadata changed. [CI run 45681665724](https://github.com/sguzman/lisp-game-lab/actions/runs/45681665724) passed every Linux gate including lock validation and graphical smoke; the macOS job was cancelled, with the earlier macOS build/ABI pass still the available evidence. Local software-rendering startup is user-confirmed.

## Experiment 02 — first implementation

Added a headless sprite/camera model, stable layer/depth ordering, a separate rendering ASDF system, four original disposable PNG textures, explicit texture cache ownership with unwind cleanup, and a bounded smoke checking four unique texture handles and three completed frames. The existing foundation demo remains runnable. The ABI version is now 2.

No flake or lockfile changes. The upstream binding comparison confirmed fosskers has texture and camera wrappers, but its separate vendored Raylib build and shim require a separate reproducible trial. Keep the small baseline adapter for this scene; do not claim upstream runtime validation. Next: inspect new CI, complete the upstream trial, then batch local visual QA. For the next QA, explicitly request git pull --ff-only and use the known working software shell.

## Experiment 02 — CI evidence and binding trial

[CI run 45690527757](https://github.com/sguzman/lisp-game-lab/actions/runs/45690527757), code commit `fd2f9c9`: Linux job 139474471448 passed lock validation, style, unit tests, ABI probe, both ASDF compilation steps and both graphical smoke tests. Logs show four 32x32 RGBA PNGs loaded, "Rendering smoke: 3 frames, 4 unique textures." and all four texture IDs unloaded from VRAM. macOS was subsequently cancelled. Actual visual appearance and camera input await human QA; ordering/camera logic is covered by headless tests.

Added an isolated Linux CI binding trial with pinned fosskers/raylib and trivial-garbage source checkouts. It builds the upstream shim against the existing Nix Raylib header/library rather than compiling the vendored copy, and checks texture dimensions/validity, camera transform, input query, bounded rendering and explicit unload. No default dependencies or Nix pins changed. This is a compatibility experiment, not yet a verified alternative adapter. Next: inspect binding trial CI and any outstanding macOS results; then request a single rendering QA pass (pull required, existing software shell).

## Experiment 02 — compatibility result and intermittent regression

The [binding trial](https://github.com/sguzman/lisp-game-lab/actions/runs/45690735898), job 139475189291, passed on Linux. Keep the baseline adapter for now: migration has unresolved scaling/API and macOS loader work. The successful upstream trial is narrow, not a portability or performance claim.

The repeat regression [run 45690735940](https://github.com/sguzman/lisp-game-lab/actions/runs/45690735940), Linux job 139475365762, passed lock validation, headless tests, ABI, both compilations, and the foundation smoke, but the rendering process exited 136 (SIGFPE) after successfully loading all four textures. This contradicts a claim of consistently passing smoke. macOS was still in progress at inspection.

Mitigation: SBCL trap masking scoped to the full native window session (before creating driver threads), restored on exit. Headless tests retain normal arithmetic behavior. This is a hypothesis, not a proven root cause. Separate the foundation virtual display from rendering and require five consecutive rendering processes to succeed in the latter. No input/lock changes. Next: verify the mitigation in CI, then issue explicit pull and visual QA commands. If it fails, collect a native stack trace rather than hiding the failure with retries.

## Experiment 02 — stress test passed; local QA ready

[CI run 45691089838](https://github.com/sguzman/lisp-game-lab/actions/runs/45691089838), code commit `e35b172`, completed successfully on both platforms. Linux job 139476433299 passed world and scene tests, ABI probe, both compilation steps, the foundation smoke and five consecutive rendering processes, each reporting 3 frames and 4 unique textures. macOS job 139476432682 passed lock validation, style, world/scene tests, ABI probe and both compilation steps; graphical execution remains untested on macOS. The scoped floating-point mitigation held in these five launches; exact SIGFPE root cause remains unproven.

Local QA (pull required):

```sh
git pull --ff-only
nix develop .#ci -c env XDG_SESSION_TYPE=x11 make render
```

Expected: pixel-art tiled floor, rug, overlapping crate and plant sprites; arrow keys pan across the room, Escape exits. A simple text confirmation is sufficient. No Nix inputs changed; reuse the already working software-rendering shell. Hardware-accelerated host graphics remain a separate unresolved issue. On acceptance, proceed to experiment 03.

## Experiment 02 — accepted local QA (2026-11-25)

The user confirmed arrow-key camera panning and supplied a screenshot showing the tiled floor, rug, plant and crate with the expected foreground overlap. Local terminal evidence shows successful compilation, X11 initialization with Mesa llvmpipe, loading all four 32x32 RGBA textures, unloading all four texture IDs and clean window shutdown. Rendering acceptance is complete. Hardware acceleration remains unverified, and the precise prior SIGFPE cause remains unproven.

The original checkout had an unresolved HEAD and staged files. It was preserved; the user recovered a separate clean checkout, on main tracking origin/main, via a local clone of the previously fetched Git objects. Future QA should use that recovered checkout (lisp-game-lab-clean), not the original directory. No destructive cleanup is needed. Explicitly identify pull requirements; use fast-forward-only pulls and stop if they fail. No new QA or pull required for this documentation-only acceptance commit.

Next: experiment 03, live code replacement with state identity and failure recovery.

## Experiment 03 — initial implementation

Added development-only anonymous behavior compilation, content-based file polling every 15 frames, validation over the finite input domain, frame-boundary publication and fallback on runtime error. The active CLOS world survives every change; only validated deltas reach it. An ignored build/live-behavior.lisp file is seeded if absent and never overwritten by an ordinary launch. A separate four-frame smoke writes valid, faster, malformed and repaired sources to build/live-smoke-behavior.lisp, asserting movement, revision and identity. Headless tests cover accepted/rejected forms, disabled read-time evaluation, output contract and runtime rollback. This is trusted local code, not a sandbox. No Nix or lockfile changes.

Next: inspect CI and fix actual failures; batch local QA only after verified execution, using the recovered checkout and explicit fast-forward-only pull. No human action yet.

## Experiment 03 — Linux verification passed

[CI run 45701615224](https://github.com/sguzman/lisp-game-lab/actions/runs/45701615224), code commit `a73962e`, Linux job 139512889919: lockfile, headless world/scene/reload tests, ABI, all three compilation steps, foundation smoke, five rendering launches and live smoke passed. Live smoke accepted revisions 1 and 2, rejected malformed source at revision 2, accepted revision 3, and asserted movement and original object identity across all four frames. The macOS job was still running at inspection. No dependency changes.

Local QA: use the recovered checkout, pull required. In fish:

```fish
cd ~/Code/Games/lisp-game-lab/lisp-game-lab-clean
and git pull --ff-only origin main
and nix develop .#ci -c env XDG_SESSION_TYPE=x11 make live
```

Leave the game open. In a separate terminal in the same checkout, replace the disposable ignored build/live-behavior.lisp file with these expressions in succession (using printf or an editor). Test movement after each:

- `(lambda (dx dy) (values (* 12 dx) (* 12 dy)))`: ACCEPTED, faster movement, position unchanged at publication.
- `(lambda (dx dy)`: REJECTED, previous speed still works.
- `(lambda (dx dy) (values (* 2 dx) (* 2 dy)))`: ACCEPTED, slower movement without restarting.

Text confirmation is sufficient; no screenshot necessary. The file is deliberately trusted local Lisp, not a sandbox. Exit with Escape. Next: accept local QA and check the macOS result; then advance to experiment 04 (live assets).

## Experiment 03 — accepted local QA (2026-11-25)

The user confirmed all three interactive tests worked. Their terminal evidence records ACCEPTED revision 2, REJECTED at unchanged revision 2, ACCEPTED revision 3, and successful window shutdown. The prior automated smoke independently asserted preservation of world identity and positions. The initial QA commands in the second terminal failed because relative paths were resolved outside the checkout; absolute paths fixed the issue without modifying the program. For future multi-terminal QA use explicit absolute paths or a single guarded directory change for each terminal. No additional local QA is necessary for this milestone.

macOS job 139512890449: success. Graphical execution on macOS and host hardware acceleration remain unverified. No new dependencies or changes to the Nix lock.

Next: experiment 04 (live assets). No pull required for this documentation-only commit.

## Experiment 04 — initial implementation

Added a generic asset transaction slot, byte-snapshot polling, strict scene position data, native sound loading/playback/disposal, two original tone fixtures, and a separate live asset scene using an existing movable world object. The four-frame smoke swaps PNG/WAV/data, rejects invalid bytes, checks that the resource identities and revisions survive rejection, then repairs them. Headless tests exercise disposal and data validation; CI will use a null ALSA device to exercise the sound path without speakers. ABI bumped to 3; no Nix inputs changed. Next: inspect CI, address actual failures, then batch local visual/audio QA with absolute paths. No human action yet.
