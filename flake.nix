{
  description = "Swift toolchain";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
    }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      treefmt = forAllSystems (
        system:
        treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} {
          projectRootFile = "flake.nix";
          programs = {
            actionlint.enable = true;
            deadnix.enable = true;
            nixfmt.enable = true;
            prettier.enable = true;
            shellcheck.enable = true;
            shfmt.enable = true;
            statix.enable = true;
            ruff.check = true;
            ruff.format = true;
          };
        }
      );
    in
    {

      formatter = forAllSystems (system: treefmt.${system}.config.build.wrapper);

      checks = forAllSystems (system: {
        treefmt = treefmt.${system}.config.build.check self;
      });

      packages =
        lib.attrsets.recursiveUpdate
          (forAllSystems (
            system:
            let
              pkgs = nixpkgs.legacyPackages.${system};
            in
            {
              swiftly-install = pkgs.stdenv.mkDerivation {
                name = "swiftly-install";
                src = pkgs.fetchurl {
                  url = "https://swiftlang.github.io/swiftly/swiftly-install.sh";
                  sha256 = "m+2G82gj4XjW/pX84AWIuILsbpF8IDKkj+bNThVBFlc=";
                };
                dontUnpack = true;
                installPhase = ''
                  mkdir -p $out/bin
                  cp $src $out/bin/swiftly-install
                  chmod +x $out/bin/swiftly-install
                '';
              };

              swift-project-src =
                let
                  sources = (import ./sources.nix) {
                    inherit lib;
                    inherit (pkgs) fetchFromGitHub;
                  };
                in
                pkgs.stdenv.mkDerivation {
                  name = "swift-project";
                  unpackPhase = ''
                    mkdir -p $out
                    cp -r ${sources.llvm-project} $out/llvm-project
                    cp -r ${sources.swift-cmark} $out/swift-cmark
                    cp -r ${sources.swift} $out/swift
                  '';
                  dontPatch = true;
                  dontConfigure = true;
                  dontBuild = true;
                  dontInstall = true;
                  dontFixup = true;
                };
            }
          ))
          {
            x86_64-linux.swiftly =
              let
                pkgs = nixpkgs.legacyPackages.x86_64-linux;
              in
              pkgs.stdenv.mkDerivation {
                name = "swiftly";
                version = "0.3.0";
                src = pkgs.fetchurl {
                  url = "https://github.com/swiftlang/swiftly/releases/download/0.3.0/swiftly-x86_64-unknown-linux-gnu";
                  sha256 = "1gll8rq5qrs4wblk8vds9wcfkva0sdmp88kpj2dwvxwjc04x680q";
                };
                dontUnpack = true;
                installPhase = ''
                  mkdir -p $out/bin
                  cp $src $out/bin/swiftly
                  chmod +x $out/bin/swiftly
                '';
              };

            aarch64-linux.swiftly =
              let
                pkgs = nixpkgs.legacyPackages.aarch64-linux;
              in
              pkgs.stdenv.mkDerivation {
                name = "swiftly";
                version = "0.3.0";
                src = pkgs.fetchurl {
                  url = "https://github.com/swiftlang/swiftly/releases/download/0.3.0/swiftly-aarch64-unknown-linux-gnu";
                  sha256 = "sPxzc+Su/CVI+yrzUYnNhppwd1A+taMwSFMmSBKI/Tw=";
                };
                dontUnpack = true;
                installPhase = ''
                  mkdir -p $out/bin
                  cp $src $out/bin/swiftly
                  chmod +x $out/bin/swiftly
                '';
              };
          };
    };
}
