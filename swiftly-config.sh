#!/usr/bin/env bash

read_input_with_default() {
  echo -n "> "
  read -r READ_INPUT_RETURN
  if [ -z "$READ_INPUT_RETURN" ]; then
    READ_INPUT_RETURN="$1"
  fi
}

read_yn_input() {
  while true; do
    read_input_with_default "$1"

    case "$READ_INPUT_RETURN" in
    "y" | "Y")
      READ_INPUT_RETURN="true"
      return
      ;;
    "n" | "N")
      READ_INPUT_RETURN="false"
      return
      ;;
    "$1")
      return
      ;;
    *)
      echo 'Please input either "y" or "n", or press ENTER to use the default.'
      ;;
    esac
  done
}

set_platform_ubuntu() {
  PLATFORM_NAME="ubuntu$1$2"
  PLATFORM_NAME_FULL="ubuntu$1.$2"
  PLATFORM_NAME_PRETTY="Ubuntu $1.$2"
}

set_platform_amazonlinux() {
  PLATFORM_NAME="amazonlinux$1"
  PLATFORM_NAME_FULL="amazonlinux$1"
  PLATFORM_NAME_PRETTY="Amazon Linux $1"
}

set_platform_rhel() {
  PLATFORM_NAME="ubi$1"
  PLATFORM_NAME_FULL="ubi$1"
  PLATFORM_NAME_PRETTY="RHEL 9"
}

detect_platform() {
  if [[ -f "/etc/os-release" ]]; then
    OS_RELEASE="/etc/os-release"
  elif [[ -f "/usr/lib/os-release" ]]; then
    OS_RELEASE="/usr/lib/os-release"
  else
    manually_select_platform
  fi

  # shellcheck disable=SC1090
  source "$OS_RELEASE"

  case "$ID$ID_LIKE" in
  *"amzn"*)
    if [[ $VERSION_ID != "2" ]]; then
      manually_select_platform
    else
      set_platform_amazonlinux "2"
    fi
    ;;

  *"ubuntu"*)
    case "$UBUNTU_CODENAME" in
    "jammy")
      set_platform_ubuntu "22" "04"
      ;;
    "focal")
      set_platform_ubuntu "20" "04"
      ;;
    "bionic")
      set_platform_ubuntu "18" "04"
      ;;
    *)
      manually_select_platform
      ;;
    esac
    ;;

  *"rhel"*)
    if [[ $VERSION_ID != 9* ]]; then
      manually_select_platform
    else
      set_platform_rhel "9"
    fi
    ;;

  *)
    manually_select_platform
    ;;
  esac
}

manually_select_platform() {
  echo "$PRETTY_NAME is not an officially supported platform, but the toolchains for another platform may still work on it."
  echo ""
  echo "Please select the platform to use for toolchain downloads:"

  echo "0) Cancel"
  echo "1) Ubuntu 22.04"
  echo "2) Ubuntu 20.04"
  echo "3) Ubuntu 18.04"
  echo "4) RHEL 9"
  echo "5) Amazon Linux 2"

  read_input_with_default "0"
  case "$READ_INPUT_RETURN" in
  "1" | "1)")
    set_platform_ubuntu "22" "04"
    ;;
  "2" | "2)")
    set_platform_ubuntu "20" "04"
    ;;
  "3" | "3)")
    set_platform_ubuntu "18" "04"
    ;;
  "4" | "4)")
    set_platform_rhel "9"
    ;;
  "5" | "5)")
    set_platform_amazonlinux "2"
    ;;
  *)
    echo "Cancelling installation."
    exit 0
    ;;
  esac
}

set -o errexit
shopt -s extglob

detect_platform

RAW_ARCH="$(uname -m)"
case "$RAW_ARCH" in
"x86_64")
  PLATFORM_ARCH="null"
  ;;
"aarch64" | "arm64")
  PLATFORM_ARCH='"aarch64"'
  ;;
*)
  echo "Error: Unsupported CPU architecture: $RAW_ARCH"
  exit 1
  ;;
esac

cat <<EOF
{
  "platform": {
    "name": "$PLATFORM_NAME",
    "nameFull": "$PLATFORM_NAME_FULL",
    "namePretty": "$PLATFORM_NAME_PRETTY",
    "architecture": $PLATFORM_ARCH
  },
  "installedToolchains": [],
  "inUse": null
}
EOF
