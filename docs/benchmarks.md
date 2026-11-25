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

## Verified baseline — 2026-11-25

Source: [CI run 45716780965](https://github.com/sguzman/lisp-game-lab/actions/runs/45716780965), revision `cbd490783cae0a86f2f6f96b101254f55c198d2a`. Linux job 139564753215, macOS job 139564753632. Both succeeded with SBCL 2.6.4, pinned Nix lock and ABI 6.

| Environment | Linux | macOS |
| --- | --- | --- |
| Runner | ubuntu-24.04, x86_64 | macos-15, arm64 |
| CPU reported | AMD EPYC 9V74 | Apple M1 (Virtual) |
| Graphics | Mesa llvmpipe LLVM 21.1.8, Xvfb | Not run |
| Internal timer nominal units/sec | 1000000 | 1000000 |

### ASDF loading, milliseconds

| Trial | Linux cold | Linux warm | macOS cold | macOS warm |
| --- | ---: | ---: | ---: | ---: |
| 1 | 333.998 | 26.999 | 382.358 | 29.957 |
| 2 | 329.998 | 26.999 | 479.105 | 36.533 |
| 3 | 353.999 | 26.999 | 429.527 | 28.410 |
| Median | 333.998 | 26.999 | 429.527 | 29.957 |

### Headless workloads

| Host | Workload | N | Median ms | P95 ms | Max ms | Allocated bytes (total) |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Linux | Code reload | 50 | 0.000 | 1.000 | 1.000 | 5477264 |
| Linux | Room parse and migrate (4) | 200 | 0.000 | 0.000 | 1.000 | 1510144 |
| Linux | Data asset install | 200 | 0.000 | 0.000 | 1.000 | 47232 |
| macOS | Code reload | 50 | 0.132 | 0.220 | 0.645 | 5845120 |
| macOS | Room parse and migrate (4) | 200 | 0.012 | 0.016 | 0.062 | 1485696 |
| macOS | Data asset install | 200 | 0.001 | 0.001 | 0.011 | 88832 |

The Linux observations are quantized at approximately 1 ms despite the nominal microsecond timer units; zero readings mean below observed clock granularity, not zero execution time. Do not infer a relative speedup from these zero medians. Allocations are cumulative bytes consed, not peak memory.

### Graphics (Linux, 64 objects, 800x480)

| Workload | N | FPS | Median ms | P95 ms | Max ms | Allocated bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Uncapped | 180 | 343.52 | 3.000 | 3.000 | 5.000 | 811648 |
| 60 FPS target | 180 | 60.12 | 16.999 | 17.000 | 17.000 | 825728 |

Managed heap after full GC: Linux headless 30667056 bytes (29.25 MiB), Linux graphics 30597552 bytes (29.18 MiB), macOS headless 38572256 bytes (36.79 MiB). Native libraries, graphics allocations and total process RSS are excluded. This demonstrates the small laboratory workload, not production-scale game performance. No hardware GPU or macOS graphics results are inferred.
