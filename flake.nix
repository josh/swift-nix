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
      });

      packages =
        lib.attrsets.recursiveUpdate
          (eachSystem (pkgs: {
            swiftly-install = pkgs.callPackage ./swiftly-install.nix { };

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
            x86_64-linux.swiftly = nixpkgs.legacyPackages.x86_64-linux.callPackage ./swiftly.nix {
              arch = "x86_64";
              version = "0.3.0";
              sha256 = "1gll8rq5qrs4wblk8vds9wcfkva0sdmp88kpj2dwvxwjc04x680q";
            };

            aarch64-linux.swiftly = nixpkgs.legacyPackages.aarch64-linux.callPackage ./swiftly.nix {
              arch = "aarch64";
              version = "0.3.0";
              sha256 = "sPxzc+Su/CVI+yrzUYnNhppwd1A+taMwSFMmSBKI/Tw=";
            };
          };
    };
}
