{
  lib,
  stdenv,
  fetchFromGitHub,
  clang,
  cmake,
  ninja,
  python3,
  version ? "5.10",
}:
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
        fetchFromGitHub {
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
in
stdenv.mkDerivation {
  pname = "swift-toolchain";
  inherit version;

  unpackPhase = ''
    ${lib.concatStringsSep "\n" copySources."${version}"}
    chmod -R u+w .
  '';

  #dontPatch = true;
  dontConfigure = true;

  buildInputs = [
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
}
