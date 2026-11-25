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

### Native floating-point environment

SBCL enables floating-point traps that C graphics drivers may not expect. The graphical composition roots enter a scoped trap-masked environment before opening a window and restore the caller's settings on exit. Headless domain execution is unchanged. This is a mitigation for the observed intermittent native SIGFPE; the specific faulting instruction is not established.

### Experiment 03: live behavior replacement

The development-only ASDF system compiles a single anonymous lambda from a trusted local file with reader evaluation disabled. It validates its two integer results for all nine keyboard inputs before publishing the function at a frame boundary. The existing CLOS world is never passed into the candidate; only checked movement deltas are applied to it. Source text, not filesystem timestamp, determines whether to recompile. Runtime errors roll back to the prior function (or the baseline if needed). This is a deliberately narrow function replacement contract, not transactional arbitrary Lisp evaluation, a sandbox, or general class migration. Arbitrary trusted Lisp can still have side effects or hang; do not use untrusted files. No network or background thread is involved. The default world and rendering demos do not load the reload system.

### Experiment 04: live asset transactions

Each resource slot owns its current value and uses a loader/disposer pair. A bounded byte snapshot is compared to the previous observation (not the modification timestamp). Native loaders decode the snapshot from a separate scratch file on the window thread. A validated new resource is published before releasing its predecessor; rejection preserves the previous resource and revision. The disposer contract is non-signaling. Shutdown releases slots before closing the audio device and window. Scene data is a strict pair of decimal coordinates, not evaluated Lisp. The interactive workspace and CI workspace are separate ignored directories. This is a per-resource transaction, not an atomic multi-file scene transaction; large assets, concurrent writers, untrusted binary decoders and multiple simultaneous sessions sharing a workspace are outside this narrow trial. Audio CI uses a null device and cannot verify audible output.

### Experiment 05: local interactive console

Only the explicit console ASDF system starts a reader. It accepts one line at a time on the process terminal, never listens on a socket, and puts copied strings into a bounded mutex-protected FIFO. The reader does not evaluate code or touch world/graphics state. The game owner dequeues at most one command per frame and reads/evaluates it in the console package. The state/move/teleport/quit helpers enforce thread ownership. Reader evaluation is disabled, but ordinary EVAL intentionally executes trusted local Lisp with full process authority; it is not a sandbox, and arbitrary code can block or mutate state outside the helper contract. Error recovery is not transactional for arbitrary Lisp side effects. Quit or window close closes the queue, cancels pending work, joins the polling reader and closes the graphics window. EOF stops only the reader, not the game. Input is line-oriented, not a full editor integration; network/Slynk access is not part of this trial.

### Experiment 06: object placement

The headless board owns stable item instances, with integer footprints, quarter-turn orientation and optional support IDs. The held object is picked from reverse draw order; a grab offset preserves the cursor anchor through rotation. Pickup saves an exact position/orientation/support snapshot. Drop validates bounds (excluding the HUD), overlap, complete footprint containment and a single unoccupied stackable support; overlap with ancestors of that support is permitted. Invalid placement restores the entire snapshot. Only topmost items can be moved; moving a support with a child is rejected, preventing cycles and accidental group moves. Drawing orders by stack depth, then stable list order, with the held object last. The primitive C ABI supplies mouse/key queries and rectangle drawing only. The board assumes valid initial items with unique IDs and acyclic supports; initial scene validation/migration belongs to experiment 07. No physics, inventory, production assets or generalized container system in this trial.

### Experiment 07: declarative room migration

The versioned room DSL is a single data-only S-expression, with bounded input and reader evaluation disabled. The object domain validates authored definitions and a separate staged board before publishing changes. Existing IDs retain object identity and gameplay position/rotation/support, new IDs use authored defaults, removed IDs disappear. Invalid migrated placement rejects the whole change instead of silently moving objects. Publication copies only validated definition properties into existing instances on the owner thread. File polling reuses the asset replacement protocol and is deferred during active drags. See [room format](room-format.md) for the precise contract and limitations.

### Experiment 08: audio mixer and stream

The headless mixer holds integer master volume, mute and ambience state; gain computation uses independent relative effect and ambience levels. The Raylib adapter owns opaque Sound and Music handles; streamed ambience is updated on the window thread each frame and configured to loop. Muting changes gain, not playback state; toggling ambience stops or restarts the stream. Resources are stopped and unloaded before closing the audio device, even on partial acquisition. The two buses are deliberately small, not a polyphonic voice allocator or production mixer. Null-device CI tests transport state and loop progression, not actual sound pressure or perceived quality.
