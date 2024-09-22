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

      checks = eachSystem (pkgs: {
        treefmt = treefmt.${pkgs.system}.config.build.check self;

        swiftly-install =
          pkgs.runCommandLocal "swiftly-install-check"
            { buildInputs = [ self.packages.${pkgs.system}.swiftly-install ]; }
            ''
              swiftly-install --help
              swiftly-install --version
              echo "ok" >$out
            '';

        swiftly =
          pkgs.runCommandLocal "swiftly-check" { buildInputs = [ self.packages.${pkgs.system}.swiftly ]; }
            ''
              swiftly --help
              swiftly --version
              echo "ok" >$out
            '';

        swift-toolchain =
          pkgs.runCommandLocal "swift-toolchain-check"
            { buildInputs = [ self.packages.${pkgs.system}.swift-toolchain ]; }
            ''
              swift --version
              echo "ok" >$out
            '';
      });

      packages = {
        x86_64-linux =
          let
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
          in
          {
            swiftly-install = pkgs.callPackage ./swiftly-install.nix { };
            swiftly-config = pkgs.callPackage ./swiftly-config.nix { };
            swiftly = pkgs.callPackage ./swiftly.nix {
              arch = "x86_64";
              version = "0.3.0";
              sha256 = "1gll8rq5qrs4wblk8vds9wcfkva0sdmp88kpj2dwvxwjc04x680q";
            };
            swift-toolchain = pkgs.callPackage ./swift-toolchain.nix {
              version = "6.0";
              sha256 = "sha256-ozA7ZMuxHSzYvve+vwxLCatRK5kClGpkuOcwD79vhZc=";
            };
          };

        aarch64-linux =
          let
            pkgs = nixpkgs.legacyPackages.aarch64-linux;
          in
          {
            swiftly-install = pkgs.callPackage ./swiftly-install.nix { };
            swiftly-config = pkgs.callPackage ./swiftly-config.nix { };
            swiftly = pkgs.callPackage ./swiftly.nix {
              arch = "aarch64";
              version = "0.3.0";
              sha256 = "sPxzc+Su/CVI+yrzUYnNhppwd1A+taMwSFMmSBKI/Tw=";
            };
            swift-toolchain = pkgs.callPackage ./swift-toolchain.nix {
              arch = "aarch64";
              version = "6.0";
              sha256 = "sha256-yOyR5UkGv8NYbIlkiF/hnmB1Lt/PcsAHUH3SP9AxTFg=";
            };
          };
      };
    };
}
