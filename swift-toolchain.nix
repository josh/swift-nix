{
  stdenv,
  autoPatchelfHook,
  fetchurl,
  arch ? "x86_64",
  platform ? "ubuntu2404",
  platformFull ? "ubuntu24.04",
  version,
  sha256,
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
  archSuffix = if arch == "x86_64" then "" else "-aarch64";
  url = "https://download.swift.org/swift-${version}-release/${platform}${archSuffix}/swift-${version}-RELEASE/swift-${version}-RELEASE-${platformFull}${archSuffix}.tar.gz";
in
stdenv.mkDerivation {
  pname = "swift-toolchain";
  inherit version;
  src = fetchurl {
    inherit url sha256;
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
}
