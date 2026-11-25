# Working agreement

This repository is a standalone Common Lisp game-development laboratory. Follow the scope in docs/roadmap.md; do not import production game assets or invent extra milestones.

- Read docs/status.md and docs/architecture.md before resuming. Continue the first unfinished approved experiment.
- Use ASDF, SBCL and explicit packages. Keep platform/FFI code outside game state.
- Use a stable Nixpkgs release branch (currently nixos-26.05) and keep the committed lockfile unchanged during ordinary work. Coordinate deliberate updates to reuse the user's existing Nix store where possible.
- Keep dependencies pinned; no Quicklisp bootstrap from a floating URL, no npm, no Python tooling.
- Run make check and applicable smoke tests. Record actual commands/results and distinguish static review, automated execution and visual QA.
- Do not expose any remote Lisp evaluator; future interactive tooling must bind loopback by default, be opt-in and never ship in releases.
- Commit coherent changes and verify the remote ref. Preserve the user's existing files and batch visual QA.
- Keep README concise; maintain status and findings in docs, not in the README.
- If CI is pending or unavailable, report that rather than claiming green. Stop when the agreed experiment criteria are satisfied.

- For human QA, explicitly state whether a pull is required and provide the exact command. Prefer text confirmation over screenshots/log uploads when the user's connection is constrained.
