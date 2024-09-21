{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  curl,
  cacert,
  getopt,
  # https://github.com/swiftlang/swiftly/commits/main/install/swiftly-install.sh
  commitSHA ? "bcfd8439a078893c11d3331c193e2b6a7b431887",
  sha256 ? "sha256-nWhuHRfZerImD4GvwZkx3csdBEVCTdQdi5axpeOuxGk=",
}:
let
  url = "https://raw.githubusercontent.com/swiftlang/swiftly/${commitSHA}/install/swiftly-install.sh";
  runtimeInputs = [
    curl
    getopt
  ];
in
stdenv.mkDerivation {
  name = "swiftly-install";
  src = fetchurl {
    inherit url sha256;
  };
  dontUnpack = true;
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/swiftly-install
    chmod +x $out/bin/swiftly-install
    wrapProgram "$out/bin/swiftly-install" \
      --prefix PATH : ${lib.makeBinPath runtimeInputs} \
      --set SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt"
  '';
}
