# Current state

Completed: experiment 01 (foundation, with software-rendering development path).
Completed: experiment 02 (rendering).
Completed: experiment 03 (live code).
Completed: experiment 04 (live assets).
Completed: experiment 05 (interactive development).
Completed: experiment 06 (object playground).
Completed: experiment 07 (scene DSL).
Active next: experiment 08 (audio).

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

1. Implement experiment 08: effects, looping ambience, volume and resource cleanup.
2. Retain all seven completed experiments' regression tests; automate verification and minimize manual QA.
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

## Experiment 04 — Linux verification passed

[CI run 45703417787](https://github.com/sguzman/lisp-game-lab/actions/runs/45703417787), code commit `03ed414`, Linux job 139519106821 passed all configured gates: locked dependencies, unit tests, ABI 3, all experiment compilations, graphical regressions and live asset smoke. The null audio device initialized and closed. All three asset slots accepted revisions 1 and 2, rejected malformed data at revision 2 while retaining the identical old resource values, and accepted revision 3. Four frames completed with world identity asserted. macOS job 139519106218 was still running at inspection. The silent CI device cannot establish audible playback on the user's host.

### Local QA

Use the recovered checkout and the established software graphics shell; no dependency update. In fish, pull is required:

```fish
cd ~/Code/Games/lisp-game-lab/lisp-game-lab-clean
and git pull --ff-only origin main
and nix develop .#ci -c env XDG_SESSION_TYPE=x11 make assets
```

Keep the window open. Move the crate with arrows and press Space to hear the low tone. In a second terminal, set an absolute base path:

```fish
set lab ~/Code/Games/lisp-game-lab/lisp-game-lab-clean
cp "$lab/assets/02-rendering/plant.png" "$lab/build/assets-live/sprite.png"
cp "$lab/assets/04-assets/high.wav" "$lab/build/assets-live/effect.wav"
cp "$lab/assets/04-assets/position-b.txt" "$lab/build/assets-live/position.txt"
```

Observe plant at retained movable position, changed fixed square position and high tone on Space. Then reject invalid replacements (only ignored disposable files):

```fish
printf 'invalid' > "$lab/build/assets-live/sprite.png"
printf 'invalid' > "$lab/build/assets-live/effect.wav"
printf 'invalid' > "$lab/build/assets-live/position.txt"
```

All three slots should show REJECTED while the plant, fixed square position and high tone remain working. Restore all three before closing the window:

```fish
cp "$lab/assets/02-rendering/crate.png" "$lab/build/assets-live/sprite.png"
cp "$lab/assets/04-assets/low.wav" "$lab/build/assets-live/effect.wav"
cp "$lab/assets/04-assets/position-a.txt" "$lab/build/assets-live/position.txt"
````

Confirm crate, original fixed position and low tone return without a restart. If audio initialization fails, report the error; do not silently disable audio or change host drivers. Text confirmation sufficient. Next: accept QA, check macOS result and move to experiment 05.

## Experiment 04 — accepted local QA (2026-11-25)

User confirmed completion and provided screenshots at accepted revisions 2 and 3, showing the plant/crate swap and fixed-square coordinate change. Local terminal evidence: PulseAudio backend initialized (48 kHz stereo); valid PNG/WAV/data accepted at revisions 1 and 2; intentionally corrupted PNG/WAV/data rejected at unchanged revision 2; repaired assets accepted at revision 3; old textures unloaded; audio device and window closed cleanly. No crash occurred. Audio resource replacement is verified; the user did not explicitly report hearing the two tones, so audible output remains to be confirmed in experiment 08. The warnings during intentional invalid input are expected. Accept the live asset transaction milestone; no repeat QA required.

macOS job 139519106218: success. macOS graphical execution and Linux hardware acceleration remain unverified. No Nix dependency changes. Next: experiment 05, opt-in local interactive development with queued main-thread operations and safe shutdown. No pull required for this documentation-only acceptance commit.

## Experiment 05 — initial implementation

Added opt-in terminal Lisp evaluator, bounded FIFO, nonblocking reader thread, owner-thread inspection and manipulation, one-expression-per-line evaluation and error reporting. No sockets, native ABI or dependency changes. The graphical smoke uses a real reader thread with a string input stream, queues five commands (inspection, movement, intentional error, teleport, quit), verifies outcomes and world identity, then closes the reader/window. Headless tests cover capacity, FIFO, EOF, owner-thread rejection, failed command recovery and closed sessions. Local terminal behavior remains unverified until QA; arbitrary trusted code is not sandboxed or preemptible. Next: verify CI; then batch terminal QA in recovered checkout with explicit pull. No human action yet.

## Experiment 05 — CI verified; local QA ready

[CI run 45708051657](https://github.com/sguzman/lisp-game-lab/actions/runs/45708051657), code commit `be4b18c`, succeeded on Linux (job 139534989997) and macOS (job 139534990394). Both passed headless console queue, evaluation, owner isolation and shutdown tests, ABI and compilation. Linux additionally passed all graphical regressions and console smoke: real reader thread queued five expressions, evaluated state and movement, reported intentional error, teleported to (448,238), processed quit and preserved world identity. macOS graphical execution is still untested. The smoke uses a string input stream, so terminal interaction and shutdown with real stdin remain local QA.

Pull required, in the recovered checkout:

```fish
cd ~/Code/Games/lisp-game-lab/lisp-game-lab-clean
and git pull --ff-only origin main
and nix develop .#ci -c env XDG_SESSION_TYPE=x11 make console
```

Use the same terminal that launched the window, not another shell. Focus the terminal and submit one Lisp expression per line: (state), (teleport 100 100), (+ 20 30), (error "test"), (move 150 80), (quit). The intentional error should not close the window; movement after the error should work, and quit should close the application and return to fish. No new Nix dependencies. Text confirmation sufficient. If terminal input is not accepted or quit hangs, report it; do not assume the string-stream CI smoke covers real TTY behavior. Next: accept interactive QA, then experiment 06.

## Experiment 05 — accepted local QA (2026-11-25)

User confirmed every interactive test worked. The real terminal log records (state) returning (368,208), teleport to (100,100), arithmetic returning 50, intentional error reported without closing the application, movement to (250,180), and quit returning :STOPPING followed by successful texture/shader cleanup and window closure. Screenshot confirms the teleported square and command count 2. The real terminal gate is satisfied in addition to the Linux/macOS CI evidence. No repeat QA required. The local evaluator is trusted, opt-in and not sandboxed; macOS graphical execution and Linux hardware acceleration remain unverified.

Next: experiment 06, object playground (drag/drop, rotate, stack, deterministic domain tests). No pull required for this documentation-only acceptance commit.

## Experiment 06 — initial implementation

Added deterministic headless board and item model with stable identity, mouse hit testing, drag offsets, quarter-turn rotation around the grabbed pixel, single-support stacking, bounds/overlap rejection and exact rollback. Four colored rectangular fixtures expose rotation and stacking without new art. Supports with children cannot be picked independently. Graphical smoke exercises drag/rotate/stack/reject/detach; headless tests cover rotation closure, hit order, occupied supports, rollback and cancel. ABI bumped to 4 for primitive mouse/keyboard and object drawing calls. No Nix changes. Next: inspect CI, fix actual failures, then batch local mouse QA using the recovered checkout. No human action yet.

## Experiment 06 — selection contract correction

[CI run 45709269740](https://github.com/sguzman/lisp-game-lab/actions/runs/45709269740), Linux job 139539175087, passed lock validation and the previous headless tests, then failed the new object test because PICK-ITEM returned :EMPTY (the SETF value) rather than NIL. The same defect existed in the occupied-support branch. Both branches now record their status and explicitly return NIL. Added assertions for empty pickup, occupied pickup and attempting a second pickup during a drag. The graphical smoke was skipped on the failing run; the correction remains unverified until new CI. No dependency changes or local QA required yet.

## Experiment 06 — CI verified; local mouse QA ready

[CI run 45709386243](https://github.com/sguzman/lisp-game-lab/actions/runs/45709386243), code commit `2475a60`, succeeded on Linux (job 139539723430) and macOS (job 139539723863). Both passed the corrected pickup contract, deterministic object placement, rotation, stacking and rollback tests, prior headless tests, ABI 4 and compilation. Linux passed the full graphical regression suite including "Object smoke: drag, rotate, stack, reject and detach passed." The object smoke calls the domain operations directly rather than injecting real mouse events; actual input remains the local gate. macOS graphical execution and hardware-accelerated Linux rendering remain unverified.

Pull required in the recovered checkout:

```fish
cd ~/Code/Games/lisp-game-lab/lisp-game-lab-clean
and git pull --ff-only origin main
and nix develop .#ci -c env XDG_SESSION_TYPE=x11 make objects
```

In the window: drag the small gold item 3 to an empty region and release (PLACED); hold it again and press R while dragging to rotate its rectangular footprint; drop it wholly inside brown item 1 (STACKED). Try dragging the exposed part of item 1 while item 3 rests on it (OCCUPIED, no movement). Pick item 3 up, drag it so that only part overlaps purple item 4, and release (REJECTED; exact previous stack position and orientation restored). Pick item 3 up again and drop it in an empty region (PLACED; detached); test C during a drag to cancel and restore the original placement. Escape closes the window. Intentional rejected placements are expected, not crashes. No second terminal or screenshot required; text confirmation suffices. No new Nix dependencies. Next: accept local mouse QA, then experiment 07.

## Experiment 06 — accepted local QA (2026-11-25)

The user confirmed all requested mouse interaction tests worked. Screenshots show the gold item 3 successfully moved to an empty region (PLACED), and subsequently rotated and stacked on brown item 1 (label 3 on 1). User confirmation covers the rest of the interactive test sequence; separate terminal logs were not supplied. Combined with passing Linux graphical smoke and Linux/macOS headless and compilation checks in run 45709386243, the object playground acceptance gate is complete. The deliberately limited stacking rule prohibits independently moving an occupied support. The stacked-item label slightly extends beyond its narrow rotated footprint in the screenshot; this is a cosmetic limitation of the debug playground, not a failed placement rule. Hardware-accelerated Linux rendering and macOS graphical execution remain unverified.

Next: experiment 07, declarative scene descriptions with validation and reload migration. No pull required for this documentation-only acceptance commit.

## Experiment 07 — initial implementation

Added versioned room S-expression DSL, validation of settled boards, atomic staged migration with stable IDs and preserved placement/rotation/support, reusable object playground input/drawing, three fixtures and a four-frame graphical smoke. Headless tests cover malformed/cyclic/overlapping definitions, removal of occupied supports, incompatible resized supports, drag rejection and identity preservation. No native ABI or Nix dependency changes. Existing IDs retain runtime placement rather than accepting changed authored coordinates; this is an explicit migration policy. Next: verify CI and then batch local QA. No human action yet.

## Experiment 07 — CI verified; local scene QA ready

[CI run 45714753492](https://github.com/sguzman/lisp-game-lab/actions/runs/45714753492), code commit `6aed627`, passed on Linux (job 139557834052) and macOS (job 139557834481). Both passed the headless room validation, identity migration and atomic rejection tests, all preceding unit tests, ABI 4 and compilation. Linux passed all graphical smoke tests; room smoke accepted revisions 1 and 2, rejected the valid-as-authored conflict fixture at unchanged revision 2 (unrelated items 3 and 6 overlap), then accepted revision 3. Object identity and retained coordinates were asserted. macOS graphical execution remains untested.

Local QA, pull required in the recovered checkout:

```fish
cd ~/Code/Games/lisp-game-lab/lisp-game-lab-clean
and git pull --ff-only origin main
and nix develop .#ci -c env XDG_SESSION_TYPE=x11 make rooms
```

The first launch seeds build/room-live.room from initial.room. The live file is ignored and disposable; subsequent launches retain it. Move gold object 3 into the lower-right empty space, approximately center (680,350) in the 800x480 logical window, and release. Keep the window open. In a second terminal:

```fish
set lab ~/Code/Games/lisp-game-lab/lisp-game-lab-clean
cp "$lab/assets/07-rooms/changed.room" "$lab/build/room-live.room"
```

Object 3 becomes purple without changing its current position, object 4 disappears, and new gold object 5 appears at lower left. Then:

```fish
cp "$lab/assets/07-rooms/conflict.room" "$lab/build/room-live.room"
```

If object 3 overlaps the proposed item 6 footprint (650..746,330..394), the reload is rejected and nothing changes. Otherwise this valid definition may be accepted; that is not a failure of validation. To ensure rejection in that case, restore changed.room, move item 3 to the indicated region, and repeat. Finally:

```fish
cp "$lab/assets/07-rooms/initial.room" "$lab/build/room-live.room"
```

Object 3 returns to gold at its moved position, item 5 disappears and item 4 returns. Escape closes the game. Text confirmation sufficient, no uploads needed. No Nix dependency changes. Next: accept local QA, then experiment 08 (audio).

## Experiment 07 — accepted local reload QA (2026-11-25)

User reported the room experiment working. Terminal evidence records accepted revisions 1 through 4 and clean window shutdown. The conflict fixture was accepted locally rather than rejected; the moved footprint evidently did not produce the intended conflict (exact local coordinates unavailable). Do not claim local rejection or independent visual identity verification. CI run 45714753492 already proves the conflict rejection and identity preservation via assertions, so no duplicate manual test is required. Accept this milestone on combined evidence. The local log also exposed two nonfatal SBCL style warnings from an IGNORE declaration placed inside the wrong lexical scope in ROTATE-HELD. Corrected declaration placement in this commit; verification deferred to next full CI. No gameplay change intended.

User feedback: repetitive multi-terminal engineering QA is burdensome. Prefer automated assertions and CI for behavior that can be tested there; reserve short, batched manual checks for actual subjective gameplay feel, audible output or otherwise inaccessible host-specific behavior. Do not require repeated screenshots or engineering chores to establish already automated behavior.

Next: experiment 08 (audio), then benchmarks and distribution. Hardware acceleration and macOS graphical execution remain unverified. No pull required now.
