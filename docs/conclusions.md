# Campaign conclusions — Common Lisp for game development

**Status: complete, 2026-11-25.** This laboratory is independent of For Keeps and does not authorize production development. Its purpose was to determine whether Common Lisp with SBCL and Raylib offers a practical foundation for iterative game development and a maintainable architecture.

## Decision

Common Lisp is a viable candidate for a small-to-medium 2D object-oriented game with rapid iteration. The evidence supports pursuing it, not an assertion that it is the best language for every game or that a production engine is already finished. The ability to replace behavior and assets while retaining gameplay state is particularly relevant to a room-based object placement game.

## Acceptance ledger

| Experiment | Outcome |
| --- | --- |
| 01 Foundation | Nix, ASDF, structural checks, headless tests, ABI and bounded window; local software-rendering input QA accepted |
| 02 Rendering | Layered textures, camera and ordering; repeated Linux graphics smoke |
| 03 Live code | Validated function replacement, preserved world identity, rollback on failure |
| 04 Live assets | Transactional texture, sound and data replacement; bad candidate retains old resource |
| 05 Interactive development | Opt-in local terminal evaluator, bounded owner-thread queue and clean shutdown |
| 06 Object playground | Mouse drag, rotation, stacking, invalid drop rollback; user-confirmed gameplay |
| 07 Scene DSL | Versioned room data, staged validation, identity-preserving migration and conflict rejection |
| 08 Audio | Effects, gain/mute, streamed looping ambience, stop/restart and cleanup; final local release QA accepted |
| 09 Benchmarks | Repeatable cold/warm loads, reload/migration timing, 64-object FPS and managed heap baseline |
| 10 Distribution | Native Linux x86_64, Windows x86_64 and macOS ARM64 executable builds and relocated self-tests; Linux and Windows software graphics passed, macOS GUI failed on hosted runner |

## What the measurements establish

Hosted Linux median cold ASDF interval 333.998 ms, warm 26.999 ms; macOS ARM64 429.527/29.957 ms. macOS median validated code replacement 0.132 ms, four-object scene migration 0.012 ms. Linux 64-object software-rendering workload 343.52 FPS uncapped and 60.12 FPS at the 60 FPS target, 3 ms uncapped p95 frame interval. Managed heap after full GC approximately 29 MiB Linux, 37 MiB macOS. These are small workloads, not total process memory or production performance. Linux submillisecond timing is limited by observed clock granularity; no direct speed comparison against other languages was performed. Full protocol and results: [benchmarks](benchmarks.md).

## Architecture worth carrying forward

Use explicit ASDF systems/packages; pure domain state and deterministic tests independent of graphics/audio; a narrow owner-thread FFI boundary; transactional validation before publication of code and asset changes; stable object identity; disposable development-only tooling excluded from release composition. The small C bridge is a pragmatic tested adapter, not a full binding or a production dependency decision. Keep pinned Nix dependencies for Linux/macOS, and treat Windows as a separate native toolchain until a reproducible release strategy is established.

## Remaining limitations (not additional approved work)

- User Linux hardware rendering on Wayland/NVIDIA is not verified; X11/llvmpipe is the working development path.
- Windows native graphics passed only with CI-only software OpenGL; the original driver launch failed WGL 65542. Windows audio and macOS GUI/audio are unverified. macOS GUI attempt failed NSGL 65545 on the hosted runner.
- Linux/macOS builds retain their Nix closure, so the zipped artifacts are not universally portable binaries. Signing, notarization, installers, license review and broader OS coverage were not evaluated.
- Benchmarks do not prove scalability to a production workload; long-session stability, complex asset pipelines and richer production content were outside scope. Hot reload is trusted local development tooling, not a sandbox.
- Local final release log shows successful device/audio asset initialization and cleanup, not objective audio quality; the user's completion report is the manual acceptance evidence.

## Evidence and handoff

- [Regression run](https://github.com/sguzman/lisp-game-lab/actions/runs/45718401081)
- [Distribution run and artifacts](https://github.com/sguzman/lisp-game-lab/actions/runs/45718400937)
- [Distribution evidence and platform caveats](distribution.md)
- [Architecture](architecture.md)
- [Project status and historical evidence](status.md)

No further implementation is required for this campaign. The repository remains a reusable reference, not the production game. Any subsequent work requires a new scope.
