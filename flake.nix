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
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      treefmt = forAllSystems (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    in
    {
      formatter = forAllSystems (pkgs: treefmt.${pkgs.system}.config.build.wrapper);

      checks = forAllSystems (pkgs: {
        treefmt = treefmt.${pkgs.system}.config.build.check self;

        swiftly-install =
          pkgs.runCommandLocal "swiftly-install"
            { buildInputs = [ self.packages.${pkgs.system}.swiftly-install ]; }
            ''
              swiftly-install --help
              echo "ok" >$out
            '';

        swiftly =
          pkgs.runCommandLocal "swiftly" { buildInputs = [ self.packages.${pkgs.system}.swiftly ]; }
            ''
              swiftly --help
              echo "ok" >$out
            '';
      });

      packages =
        lib.attrsets.recursiveUpdate
          (forAllSystems (pkgs: {
            swiftly-install = pkgs.stdenv.mkDerivation {
              name = "swiftly-install";
              src = swiftly;
              nativeBuildInputs = [ pkgs.makeWrapper ];
              installPhase = ''
                mkdir -p $out/bin
                cp $src/install/swiftly-install.sh $out/bin/swiftly-install
                wrapProgram "$out/bin/swiftly-install" --prefix PATH : ${
                  pkgs.lib.makeBinPath [
                    pkgs.curl
                    pkgs.getopt
                  ]
                }
                chmod +x $out/bin/swiftly-install
              '';
            };

            swift-toolchain =
              let
                # Parse sources lockfile
                sourcesLock = builtins.fromJSON (builtins.readFile ./sources.json);

                # Fetch sources mapping version :: repo -> storePath
                # e.g. "6.0" -> { swift = "/nix/store/..."; llvm-project = "/nix/store/..."; }
                sources = lib.mapAttrs (
                  version: repos:
                  (lib.mapAttrs (
                    repo:
                    (
                      source:
                      pkgs.fetchFromGitHub {
                        inherit (source.locked) owner repo rev;
                        name = "swift-project-${version}-${repo}-source";
                        sha256 = source.locked.narHash;
                      }
                    )
                  ) repos)
                ) sourcesLock;

                # Flatten sources by version into cp statements to unpack full swift-project directory.
                # e.g. "6.0" -> [ "cp -r /nix/store/... swift", "cp -r /nix/store/... llvm-project" ]
                copySources = lib.mapAttrs (
                  _version: sources: lib.mapAttrsToList (repo: source: "cp -r ${source} ${repo}") sources
                ) sources;

                # Try to get things working with a specific version to start
                version = "5.10";
              in
              pkgs.stdenv.mkDerivation {
                pname = "swift-toolchain";
                inherit version;

                unpackPhase = ''
                  ${lib.concatStringsSep "\n" copySources."${version}"}
                  chmod -R u+w .
                '';

                #dontPatch = true;
                dontConfigure = true;

                buildInputs = with pkgs; [
                  clang
                  cmake
                  ninja
                  python3
                ];

                buildPhase = ''
                  swift/utils/build-script --release-debuginfo
                '';

                #dontUpdateAutotoolsGnuConfigScripts = true;
                #updateAutotoolsGnuConfigScriptsPhase = '''';

                installPhase = ''
                  mkdir -p $out
                  cp -r build $out
                '';

                #dontFixup = true;
              };
          }))
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
