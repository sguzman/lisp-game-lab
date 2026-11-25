# Lisp Game Lab

A reproducible Common Lisp / SBCL / Raylib laboratory for interactive game development and scalable game architecture. Independent of any production game.

## Start

On Linux with Nix flakes enabled:

```sh
nix develop -c make check
nix develop -c make run
```

The first playground is a small window with a movable square. Arrow keys move it; Escape closes the window. No external art is needed.

| Command | Purpose |
| --- | --- |
| `make test` | Headless Lisp unit tests |
| `make style` | Lisp whitespace and structural checks |
| `make format` | Emacs Lisp-mode indentation and whitespace cleanup |
| `make check` | Style, headless tests, native bridge build and ABI probe |
| `make run` | Interactive playground |
| `make render` | Layered texture and camera playground |
| `make render-smoke` | Bounded texture rendering smoke |
| `make live` | Live behavior replacement playground |
| `make live-smoke` | Automated live reload demonstration |
| `make assets` | Live texture, sound and data replacement |
| `make assets-smoke` | Automated live asset demonstration |
| `make console` | Opt-in local terminal Lisp REPL |
| `make console-smoke` | Queued evaluation and shutdown smoke |
| `make smoke` | Open a window, render three frames and exit (display required) |

Run these from the repository root inside the Nix shell. Linux is the primary development platform; macOS and Windows are planned targets, not yet validated releases.

## Laboratory map

- [Architecture](docs/architecture.md): system boundaries, state, resources and reload design.
- [Conventions](docs/conventions.md): Lisp style, testing and tools.
- [Roadmap](docs/roadmap.md): experiments and acceptance criteria.
- [Current state](docs/status.md): evidence and next unfinished step.

The initial Raylib adapter uses a deliberately small C ABI shim and SBCL's native FFI. All gameplay is Lisp. The shim is an experiment, not a commitment to writing a game in C. Established Lisp bindings will be evaluated before expanding the adapter.
