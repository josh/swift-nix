# swift-nix

A Nix flake to install the latest Swift toolchain.

⚠️ Doesn't really work yet. Intended to get [@nakajima](https://github.com/nakajima) to use Nix.

## Usage

```sh
# Run swiftly installer,
# Though you probably don't want to do this. Skip to the next step.
# It's an alternative to
# curl -L https://swiftlang.github.io/swiftly/swiftly-install.sh | bash
$ nix run github:josh/swift-nix#swiftly-install
```

```sh
# Run swiftly,
# Though it expects a bunch of other configuration to be added to your profile
# first. So maybe you should have ignored me and ran the installer anyway. It
# should work if you already used swiftly once before.
$ nix run github:josh/swift-nix#swiftly install latest
```
