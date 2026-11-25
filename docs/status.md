# Current state

Active: experiment 01 (foundation).

## Verified evidence

[CI run 45679462842](https://github.com/sguzman/lisp-game-lab/actions/runs/45679462842), commit `b591470`:

| Gate | Linux | macOS |
| --- | --- | --- |
| Nix shell | Pass | Pass |
| Style, domain tests, native adapter and ABI probe | Pass | Pass |
| Compile playground | Pass | Pass |
| Bounded graphical smoke | Fail: GLX framebuffer unavailable | Not run |

Linux Raylib initialization reached GLFW, which reported no GLXFBConfigs; no game frames were rendered. The macOS job succeeded in full for its configured gates. No visual QA has occurred.

## Current iteration

[CI run 45680088856](https://github.com/sguzman/lisp-game-lab/actions/runs/45680088856), commit `dd1d149`: Linux successfully generated flake.lock, then failed the drift check because Nix automatically makes newly generated locks visible to Git. The graphical fix was not exercised. macOS was still running when inspected.

Recovered the exact generated lockfile from Linux job 139438006582, committed it and changed CI to check drift against HEAD. See [binding assessment](raylib-bindings.md) for the source-only comparison; no dependency change was made.

The separate Mesa CI shell and exact-frame smoke assertion are still awaiting execution.

## Next unfinished gates

1. Inspect CI against the committed lockfile; resolve actual failures and verify the bounded graphical smoke.
2. Batch first local visual/input QA; document Linux host graphics integration if needed.
3. Advance the rendering experiment only after the foundation gate is met.

Windows distribution and macOS graphical execution remain unverified. See [roadmap](roadmap.md).
