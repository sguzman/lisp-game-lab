# Raylib binding assessment

Source inspection and Linux compatibility trial, 2026-11-25. No comparative performance measurement yet.

| Approach | Strengths | Costs |
| --- | --- | --- |
| Current primitive SB-ALIEN bridge | No additional Lisp dependencies; Nix controls Raylib version; explicit GPU ownership | Every new API requires our own wrapper; SBCL-specific |
| [fosskers/raylib](https://github.com/fosskers/raylib/tree/4ab295114348a84a1d2a6d1472fd1610a5c706ff) | Handwritten SBCL/ECL FFI, only trivial-garbage Lisp dependency, existing game usage | Partial API coverage, upstream vendored Raylib and shim, separate compiler-specific implementations, MPL-2.0 |
| [claw-raylib](https://github.com/bohonghuang/claw-raylib/tree/ec32486cd9db51b6d88f6242b7d652ca20526c15) | Generated extensive API, CLOS-friendly wrappers, higher-level and low-level access, Apache-2.0 | Multiple Lisp dependencies, generated adapters and more involved reproducible build; generation instructions use Clozure CL |

Both existing bindings address Raylib's by-value structs using native adapters. Neither eliminates the ABI problem; they differ primarily in ownership, coverage, build complexity and API ergonomics. Performance statements in upstream READMEs are not our measurements.

## Provisional decision

Keep the current tiny bridge as the controlled baseline until foundation verification passes. Do not evolve it into a full Raylib reimplementation by default. Evaluate fosskers first for a narrow texture/input/resource-lifetime trial because its handwritten native FFI approach is close to our baseline. Consider claw when broader API coverage or CLOS interop justifies the dependency graph. Any trial must use immutable source pins, establish Raylib version compatibility and native library discovery, and demonstrate the same rendering and cleanup tests. Do not couple domain types to either binding. No binding is selected for production yet.

## Narrow trial

The pinned fosskers source vendors Raylib 5.5. Its SBCL loader expects two libraries in a working-directory-relative lib/ directory and has Linux/Windows branches but no macOS loader branch. The current Nix Raylib reports 5.6-dev at runtime. The isolated [trial workflow](../.github/workflows/binding-trial.yml) tests whether the upstream shim can link against our exact shared library and whether its Lisp API can load/draw/unload a PNG and apply a camera transformation. The only additional Lisp dependency is pinned trivial-garbage (f0663f7b0c900ed78ac19f6db306e7c6cac999fd). The source checkout and build live under ignored build/; no changes to the development shell or lockfile. [Trial run 45690735898](https://github.com/sguzman/lisp-game-lab/actions/runs/45690735898), job 139475189291, succeeded: texture validity/dimensions, camera transform, input query, three frames and unload. This establishes narrow Linux compatibility with the current Nix Raylib, not macOS or Windows portability or full API coverage.

## Decision after trial

Keep the small baseline adapter for the present experiments. The upstream binding is a viable Linux candidate, but the missing macOS loader and lack of an exported scaled-texture draw API in the inspected source mean migration would still need platform and rendering work. Keep its trial isolated and revisit adoption when the object/audio experiments require a broader API. Do not duplicate its entire API or change dependencies merely to replace the now-working baseline. No performance ranking is justified by this smoke test.
