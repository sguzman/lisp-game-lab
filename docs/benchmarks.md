# Benchmark protocol

Run in the pinned Nix shell from the repository root. The build script uses three isolated XDG caches, each followed by a warm load. It reports wall time and the ASDF load interval; neither includes downloading Nix dependencies. Headless trials warm up three iterations, force a full GC, then measure actual validated code compilation (50 trials), four-object room parse/migration and data asset installation (200 each). Median, nearest-rank p95, maximum and allocated bytes are reported. Timer resolution can yield zero-duration individual samples.

The rendering workload draws 64 deterministic objects in an 800x480 window for 180 measured frames after 20 warmup frames, uncapped and at the normal 60 FPS target. Includes frame presentation and cap wait, excludes startup. Display synchronization or driver behavior may cap the uncapped result. The native renderer is identified in Raylib's log. SBCL dynamic-space usage after full GC is managed Lisp heap usage, not total process RSS or GPU memory.

Commands:

```sh
nix develop -c make bench-build
nix develop -c make bench-headless
nix develop -c make bench-graphics
```

Linux CI uses the software-rendering shell and Xvfb for graphics. Hosted measurements are noisy reference points, not hardware-specific performance promises or regression thresholds. No production-scale workload is claimed. Baseline results will be recorded from actual CI execution.
