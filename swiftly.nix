{
  stdenv,
  fetchurl,
  autoPatchelfHook,
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
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    zlib
  ];
  installPhase = ''
    mkdir -p $out/bin $out/share/swiftly
    cp $src $out/bin/swiftly
    chmod +x $out/bin/swiftly
  '';
}
