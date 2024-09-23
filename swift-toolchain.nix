{
  lib,
  system,
  stdenv,
  autoPatchelfHook,
  fetchurl,
  platform ? "ubuntu2404",
  platformFull ? "ubuntu24.04",
  version,
  sha256 ? null,
  binutils,
  curl,
  glibc,
  icu,
  libgcc,
  libedit,
  libuuid,
  libxml2,
  ncurses,
  python3,
  sqlite,
  z3,
}:
let
  arch = lib.strings.removeSuffix "-linux" system;
  archSuffix = if arch == "x86_64" then "" else "-aarch64";

  urlHashes = import ./swift-downloads.nix;
  lookupURLHash =
    url:
    if (builtins.hasAttr url urlHashes) then
      (builtins.getAttr url urlHashes)
    else
      lib.warn "Missing sha256 hash for '${url}'" null;
  url = "https://download.swift.org/swift-${version}-release/${platform}${archSuffix}/swift-${version}-RELEASE/swift-${version}-RELEASE-${platformFull}${archSuffix}.tar.gz";
in
stdenv.mkDerivation {
  pname = "swift-toolchain";
  inherit version;
  src = fetchurl {
    inherit url;
    sha256 = if sha256 == null then (lookupURLHash url) else sha256;
  };
  nativeBuildInputs = [
    autoPatchelfHook
  ];
  buildInputs = [
    binutils
    curl
    glibc
    icu
    libedit
    libgcc.lib
    libuuid.lib
    libxml2
    ncurses
    python3
    sqlite
    z3.lib
  ];
  autoPatchelfIgnoreMissingDeps = [ "libedit.so.2" ];
  installPhase = ''
    cp -r usr/ $out
  '';
  meta.mainProgram = "swift";
}
