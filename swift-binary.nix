{
  stdenv,
  fetchurl,
  arch ? "x86_64",
  platform,
  platformFull,
  version,
  sha256,
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
  installPhase = ''
    cp -r usr/ $out
  '';
}
