{
  lib,
  system,
  stdenv,
  autoPatchelfHook,
  fetchurl,
  writeShellScriptBin,
  zlib,
  gnupg,
  version,
  sha256 ? null,
  mktemp,
}:
let
  arch = lib.strings.removeSuffix "-linux" system;

  urlHashes = import ./swift-downloads.nix;
  lookupURLHash =
    url:
    if (builtins.hasAttr url urlHashes) then
      (builtins.getAttr url urlHashes)
    else
      lib.warn "Missing sha256 hash for '${url}'" null;
  url = "https://github.com/swiftlang/swiftly/releases/download/${version}/swiftly-${arch}-unknown-linux-gnu";
  gpgkeys = fetchurl {
    url = "https://swift.org/keys/all-keys.asc";
    sha256 = "sha256-HHSfhJjq4Q63x8+cxCJ04jQKDkyAswR1BdsrnVpQnVY=";
  };
  wrapGPGHome = writeShellScriptBin "wrapGPGHome" ''
    echo "#!${stdenv.shell}"
    echo "set -x"
    echo "export GNUPGHOME=\"\$(${mktemp}/bin/mktemp -d)\""
    echo "${gnupg}/bin/gpg --import ${gpgkeys}"
    echo ""
    echo "exec -a \"\$0\" "$1" \"\$@\""
  '';
in
stdenv.mkDerivation {
  pname = "swiftly";
  inherit version;
  src = fetchurl {
    inherit url;
    sha256 = if sha256 == null then (lookupURLHash url) else sha256;
  };
  dontUnpack = true;
  nativeBuildInputs = [
    autoPatchelfHook
    wrapGPGHome
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    zlib
  ];
  installPhase = ''
    mkdir -p "$out/bin" "$out/share/swiftly"
    cp "$src" "$out/bin/.swiftly-wrapped"
    chmod +x "$out/bin/.swiftly-wrapped"

    wrapGPGHome "$out/bin/.swiftly-wrapped" >"$out/bin/swiftly"
    chmod +x "$out/bin/swiftly"
  '';
}
