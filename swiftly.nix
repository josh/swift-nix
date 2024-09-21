{
  stdenv,
  fetchurl,
  arch,
  version,
  sha256,
}:
stdenv.mkDerivation {
  name = "swiftly";
  inherit version;
  src = fetchurl {
    url = "https://github.com/swiftlang/swiftly/releases/download/${version}/swiftly-${arch}-unknown-linux-gnu";
    inherit sha256;
  };
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/swiftly
    chmod +x $out/bin/swiftly
  '';
}
