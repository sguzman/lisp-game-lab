{
  description = "Common Lisp game development laboratory";
  # Track a stable release branch; flake.lock fixes the exact revision.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    in {
      devShells = nixpkgs.lib.genAttrs systems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              sbcl raylib pkg-config gnumake stdenv.cc emacs-nox
            ];
          };
        } // nixpkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
          # Use the matching Nix Mesa implementation in headless CI only.
          # Interactive development must retain the host GPU driver.
          ci = pkgs.mkShell {
            packages = with pkgs; [
              sbcl raylib pkg-config gnumake stdenv.cc emacs-nox
              mesa.llvmpipeHook
            ];
          };
        });
    };
}
