# Raylib binding assessment

Source inspection, 2026-11-25. No comparative build or performance measurement yet.

| Approach | Strengths | Costs |
| --- | --- | --- |
| Current primitive SB-ALIEN bridge | No additional Lisp dependencies; Nix controls Raylib version; explicit GPU ownership | Every new API requires our own wrapper; SBCL-specific |
| [fosskers/raylib](https://github.com/fosskers/raylib/tree/4ab295114348a84a1d2a6d1472fd1610a5c706ff) | Handwritten SBCL/ECL FFI, only trivial-garbage Lisp dependency, existing game usage | Partial API coverage, upstream vendored Raylib and shim, separate compiler-specific implementations, MPL-2.0 |
| [claw-raylib](https://github.com/bohonghuang/claw-raylib/tree/ec32486cd9db51b6d88f6242b7d652ca20526c15) | Generated extensive API, CLOS-friendly wrappers, higher-level and low-level access, Apache-2.0 | Multiple Lisp dependencies, generated adapters and more involved reproducible build; generation instructions use Clozure CL |

Both existing bindings address Raylib's by-value structs using native adapters. Neither eliminates the ABI problem; they differ primarily in ownership, coverage, build complexity and API ergonomics. Performance statements in upstream READMEs are not our measurements.

## Provisional decision

Keep the current tiny bridge as the controlled baseline until foundation verification passes. Do not evolve it into a full Raylib reimplementation by default. Evaluate fosskers first for a narrow texture/input/resource-lifetime trial because its handwritten native FFI approach is close to our baseline. Consider claw when broader API coverage or CLOS interop justifies the dependency graph. Any trial must use immutable source pins, establish Raylib version compatibility and native library discovery, and demonstrate the same rendering and cleanup tests. Do not couple domain types to either binding. No binding is selected for production yet.
