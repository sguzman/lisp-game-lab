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

Added a separate Linux CI shell with the pinned Nixpkgs Mesa llvmpipe setup hook, explicitly configured Xvfb's 24-bit screen/GLX, and made the bounded smoke assert the exact number of rendered frames. The regular development shell does not force software rendering. CI now prints the real generated lockfile for persistence and checks for drift once it is tracked.

These changes require a new CI run. No graphics success is claimed yet.

## Next unfinished gates

1. Inspect new CI and fix any failures; recover and commit the generated flake.lock from CI logs.
2. Verify CI against the committed lockfile.
3. Batch first local visual/input QA; document Linux host graphics integration if needed.
4. Advance the rendering experiment only after the foundation gate is met.

Windows distribution and macOS graphical execution remain unverified. See [roadmap](roadmap.md).
