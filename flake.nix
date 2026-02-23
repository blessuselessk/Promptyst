{
  description = "Promptyst: A contract-first Typst DSL for structured AI prompts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            typst
            # You can add other tools like `just` or `git` here if needed
            just
          ];

          shellHook = ''
            echo "Promptyst Typst Dev Environment Loaded!"
            typst --version
          '';
        };

        # A basic check to ensure compilation passes in the Nix environment
        checks.default = pkgs.stdenv.mkDerivation {
          name = "promptyst-tests";
          src = ./.;
          buildInputs = [ pkgs.typst ];
          phases = [ "unpackPhase" "buildPhase" ];
          buildPhase = ''
            typst compile tests/test.typ out.pdf
            # If the above passes without panic, the tests succeed.
            touch $out
          '';
        };
      }
    );
}
