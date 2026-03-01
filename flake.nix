{
  description = "Promptyst: A contract-first Typst DSL for structured AI prompts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    typix = {
      url = "github:loqusion/typix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, flake-utils, typix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        typixLib = typix.lib.${system};
        src = pkgs.lib.cleanSourceWith {
          src = ./.;
          filter = path: type:
            type == "directory"
            || pkgs.lib.hasSuffix ".typ" path
            || pkgs.lib.hasSuffix ".toml" path;
        };

        mkTestCheck = testFile: typixLib.mkTypstDerivation {
          name = "promptyst-${builtins.replaceStrings ["/"] ["-"] testFile}";
          inherit src;
          buildPhaseTypstCommand = "typst compile --root . ${testFile} output.pdf";
          installPhaseCommand = "touch $out";
        };
      in {
        checks = {
          test-core    = mkTestCheck "tests/test.typ";
          test-ingest  = mkTestCheck "tests/test-ingest.typ";
          test-helpers = mkTestCheck "tests/test-helpers.typ";
        };

        devShells.default = typixLib.devShell {
          packages = [ pkgs.just ];
        };
      }
    );
}
