{
  lib,
  stdenv,
  makeWrapper,
  bash,
  coreutils,
  getopt,
}:
let
  runtimeInputs = [
    bash
    coreutils
    getopt
  ];
in
stdenv.mkDerivation {
  name = "swiftly-config";
  src = ./swiftly-config.sh;
  dontUnpack = true;
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/swiftly-config
    chmod +x $out/bin/swiftly-config
    wrapProgram "$out/bin/swiftly-config" \
      --prefix PATH : ${lib.makeBinPath runtimeInputs}
  '';
}
