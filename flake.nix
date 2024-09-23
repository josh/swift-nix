{
  description = "Swift toolchain";

  nixConfig = {
    extra-substituters = [ "https://swift-nix.cachix.org" ];
    extra-trusted-public-keys = [
      "swift-nix.cachix.org-1:MyKX026S4WH0LMxUyLF6hSUSpG02uufCB/CMql8AhIM="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    swiftly = {
      url = "github:swiftlang/swiftly/main";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      swiftly,
    }:
    let
      inherit (nixpkgs) lib;
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      eachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      treefmt = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    in
    {
      formatter = eachSystem (pkgs: treefmt.${pkgs.system}.config.build.wrapper);

      checks = eachSystem (
        pkgs:
        let
          inherit (pkgs) system;
          allPkgs = pkgs // self.packages.${system};
        in
        {

          treefmt = treefmt.${system}.config.build.check self;

          swiftly-install =
            pkgs.runCommandLocal "swiftly-install-check" { buildInputs = [ allPkgs.swiftly-install ]; }
              ''
                swiftly-install --help
                swiftly-install --version
                echo "ok" >$out
              '';

          swiftly = pkgs.runCommandLocal "swiftly-check" { buildInputs = [ allPkgs.swiftly ]; } ''
            swiftly --help
            swiftly --version
            echo "ok" >$out
          '';

          swift-toolchain =
            pkgs.runCommandLocal "swift-toolchain-check" { buildInputs = [ allPkgs.swift-toolchain ]; }
              ''
                swift --version
                echo "ok" >$out
              '';

          swift-toolchain510 =
            pkgs.runCommandLocal "swift-toolchain510-check" { buildInputs = [ allPkgs.swift-toolchain510 ]; }
              ''
                swift --version
                echo "ok" >$out
              '';
        }
      );

      packages = eachSystem (
        pkgs:
        let
          callPackage = pkgs.lib.callPackageWith (pkgs // packages);
          packages = {
            swiftly-install = callPackage ./swiftly-install.nix { };
            swiftly-config = callPackage ./swiftly-config.nix { };
            swiftly = callPackage ./swiftly.nix {
              version = "0.3.0";
            };
            swift-toolchain6 = callPackage ./swift-toolchain.nix {
              version = "6.0";
            };
            swift-toolchain510 = packages.swift-toolchain.override {
              version = "5.10.1";
            };
            swift-toolchain = packages.swift-toolchain6;
            default = packages.swift-toolchain;
          };
        in
        packages
      );
    };
}
