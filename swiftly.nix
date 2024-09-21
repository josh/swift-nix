{
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  zlib,
  arch,
  version,
  sha256,
}:
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
      --set SWIFTLY_BIN_DIR "${builtins.placeholder "out"}/bin"
  '';
}
