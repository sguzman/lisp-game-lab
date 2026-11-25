# Architecture

## Direction of dependencies

```text
experiment/application (composition root)
        |                       |
        v                       v
  domain/core              raylib adapter
 (plain Lisp)                  |
                               v
                         primitive C ABI
                               |
                               v
                             Raylib
```

ASDF systems define build boundaries; packages define namespaces and public interfaces. Dependencies are explicit and acyclic. The domain system must be runnable without a graphical display or foreign library.

## How this grows into large software

| Layer | Responsibility | Rule |
| --- | --- | --- |
| Domain | World, items, inventory, rules | No rendering or I/O |
| Application | Commands, transitions, orchestration | Compose domain operations |
| Presentation | Render snapshots, UI, input mapping | No direct rule mutation |
| Infrastructure | Raylib, files, audio, saves | Explicit adapters and resource lifetimes |
| Development | Reload, inspector, REPL | Opt-in, excluded from releases |

Split packages by coherent capability, not one file per class. Start with functions and explicit state; use CLOS when identity, extensibility or dispatch pays for itself. Prefer ordinary functions before macros; introduce DSLs only after repeated patterns are understood. Avoid a giant package, universal global state, and cyclic dependencies. Introduce new ASDF systems when independent testing, loading or deployment justifies them.

## State and live development

The first world is a CLOS object owned by the application. Keeping identity stable allows later redefinitions of functions and compatible class changes; incompatible schema changes require explicit migration or a controlled reset. Redefinition is not automatically transactional. Future reload experiments must compile candidate code, preserve the last known good behavior on error, and apply changes at a safe frame boundary.

Raylib operations and GPU-resource ownership remain on the window thread. Use unwind-protect for cleanup and explicit disposal for textures/audio. A future evaluator can submit work to a main-thread queue; never call graphics APIs arbitrarily from a network or editor thread. Development evaluation is trusted local code only.

## Initial FFI decision

SBCL's SB-ALIEN API plus a small C shim isolates ABI issues (Raylib passes structures by value). This keeps the first experiment dependency-light and exposes a useful control baseline. Compare maintained Lisp Raylib bindings before expanding the API; replace the shim if a binding provides better coverage and portability. C is limited to ABI adaptation, not gameplay. See the [SBCL manual](https://www.sbcl.org/manual/) and [Raylib](https://www.raylib.com/).

## Testing

Headless domain tests exercise rules; adapter probes test linking; bounded window smoke exercises initialization, rendering and cleanup. Visual QA verifies actual pixels and interaction. Future tests should cover reload failure recovery, resource lifetime, migration, and deterministic save/load. Cross-platform compilation is distinct from native execution and portable release packaging.

See [Raylib binding assessment](raylib-bindings.md) for the pinned upstream source comparison and provisional decision.
