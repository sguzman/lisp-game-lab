# Experiment roadmap

These are small, independently demonstrable experiments, not a production engine.

| ID | Experiment | Acceptance gate |
| --- | --- | --- |
| 01 | Foundation | Nix shell, style, ASDF compile, headless tests, ABI probe, bounded render, human input/visual QA |
| 02 | Rendering | Textures, layers, camera and draw ordering using disposable assets |
| 03 | Live code | Change a function while preserving world identity; demonstrate failure recovery |
| 04 | Live assets | Swap texture/audio/data without restarting; invalid replacements retain working assets |
| 05 | Interactive development | Opt-in local REPL/inspector, main-thread queue, safe shutdown |
| 06 | Object playground | Drag/drop, rotate, stack, deterministic domain tests |
| 07 | Scene DSL | Declarative room description; validation and reload migration |
| 08 | Audio | Effects, looping ambience, volume, resource cleanup |
| 09 | Benchmarks | Repeatable timings for builds, reloads, FPS and memory; record environment |
| 10 | Distribution | Native Linux/Windows/macOS build and run evidence; document portability limitations |

Proceed in order unless a dependency forces a documented change. See [current state](status.md) for the active milestone. Compare existing Common Lisp Raylib bindings before extending the primitive bridge. Keep production game assets out of this public repository.

## Closure

All ten experiments accepted on 2026-11-25, with platform limitations recorded in [conclusions](conclusions.md). No approved experiments remain. New work requires a new scope.
