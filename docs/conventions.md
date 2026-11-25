# Engineering conventions

- ANSI Common Lisp where practical; isolate SBCL extensions in infrastructure.
- ASDF systems and packages are declared explicitly. Export only supported interfaces. Use qualified calls across layers rather than importing entire project packages.
- Lowercase kebab-case source names, earmuffs for special variables, plus signs for constants, predicate suffix -p, percent prefix for internal low-level functions.
- Use idiomatic Lisp indentation, spaces (no tabs in Lisp), LF, final newline, no trailing whitespace. Use make format to reindent with Emacs and make style to check basic style and balanced delimiters. CI also compiles and tests source; delimiter checking is not a Lisp compiler.
- Prefer docstrings for public abstractions, lexical state, explicit dependencies, and clear conditions. Use check-type at boundaries and unwind-protect for resource cleanup.
- Use the Nix development shell and exact stable nixpkgs revision. Generate and commit flake.lock from an actual Nix invocation (CI emits it); CI checks tracked lockfile drift. Do not invent hashes. Do not fetch unpinned dependencies at runtime.
- Tests must run noninteractively, fail with nonzero status, and not require a GPU unless explicitly marked graphical. Start with standard ASSERT; adopt a dedicated test library if the suite warrants it.
- Record evidence, platform, commit, and outstanding QA in status/findings. No unsupported performance claims.
