{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  zlib,
  gnupg,
  arch,
  version,
  sha256,
}:
let
  runtimeInputs = [ gnupg ];
in
stdenv.mkDerivation {
  pname = "swiftly";
  inherit version;
  src = fetchurl {
    url = "https://github.com/swiftlang/swiftly/releases/download/${version}/swiftly-${arch}-unknown-linux-gnu";
    inherit sha256;
  };
  dontUnpack = true;
  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    zlib
  ];
  installPhase = ''
    mkdir -p $out/bin $out/share/swiftly
    cp $src $out/bin/swiftly
    chmod +x $out/bin/swiftly
    wrapProgram "$out/bin/swiftly" \
      --prefix PATH : ${lib.makeBinPath runtimeInputs}
  '';
}
