{
  description = "Common Lisp game development laboratory";
  # Stable nixos-26.05 revision; intentionally immutable even before lock generation.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/0dc498bfe49baeb18b0f9891e800b53bb2603193";

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
        });
    };
}
