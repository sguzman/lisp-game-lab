# Current state

Active: experiment 01 (foundation), local QA gate.

## Verified evidence

[CI run 45680276205](https://github.com/sguzman/lisp-game-lab/actions/runs/45680276205), code commit `c308cb1`:

| Gate | Linux | macOS |
| --- | --- | --- |
| Committed lockfile, style, unit tests, native bridge, ABI probe | Pass | queued; prior run passed |
| Playground compilation | Pass | queued; prior run passed |
| Bounded graphical smoke | Pass: exactly 3 frames | Not configured |

Linux job 139438669650 logged "World tests passed.", "Raylib bridge ABI probe passed.", Mesa llvmpipe (LLVM 21.1.8) and "Rendered 3 frames successfully." The original GLX failure is resolved in hosted Linux CI. The Nix lockfile is tracked and validated against HEAD. Prior macOS job 139435973587 passed its build and ABI gates; the current macOS job must still be checked if unfinished.

[Raylib binding assessment](raylib-bindings.md) records the provisional baseline decision. No comparative binding runtime test has been performed yet.

## Local visual/input QA

On the Linux development machine, clone or update the repository and run:

```sh
nix develop -c make run
```

Expected: an 800x480 window, dark background, amber square, heading, arrow keys move the square and stop at the viewport edges, Escape closes the window. Confirm that the window opens, the controls work, and the process exits cleanly. The ordinary shell does not force software rendering. If graphics initialization fails, retain the terminal output; use the separate CI shell as a diagnostic only (`nix develop .#ci -c make run`), not the preferred GPU configuration.

No local visual/input QA has been reported yet. Linux on the user's host (including GPU integration) is not proven by hosted CI.

## Next unfinished gates

1. Obtain local QA and inspect the current macOS CI result.
2. Fix any real failures before marking experiment 01 complete.
3. Advance to experiment 02 (rendering) and the narrow existing-binding trial after foundation acceptance.

Windows distribution and macOS graphical execution remain unverified. See [roadmap](roadmap.md).

## Nix release policy

Per user direction, flake.nix now names nixos-26.05 and flake.lock retains the identical previously verified locked revision and hash. Only the original input reference metadata changed; CI must confirm no lockfile rewrite. The user reported the local build is underway; visual/input QA remains pending.
