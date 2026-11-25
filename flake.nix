{
  description = "Common Lisp game development laboratory";
  # Track a stable release branch; flake.lock fixes the exact revision.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    in {
      packages = nixpkgs.lib.genAttrs systems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          release = pkgs.stdenv.mkDerivation {
            pname = "lisp-game-lab";
            version = "0.1.0";
            src = self;
            nativeBuildInputs = with pkgs; [ sbcl pkg-config gnumake ];
            buildInputs = [ pkgs.raylib ];
            buildPhase = ''
              runHook preBuild
              export HOME="$TMPDIR/lab-home"
              export XDG_CACHE_HOME="$HOME/.cache"
              mkdir -p "$XDG_CACHE_HOME"
              make release
              runHook postBuild
            '';
            installPhase = ''
              mkdir -p "$out/bin"
              cp -R build/release/. "$out/bin/"
            '';
            # Keep the embedded SBCL core intact; native store dependencies
            # remain referenced by the executable and bridge.
            dontFixup = true;
          };
          default = self.packages.${system}.release;
        });
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
