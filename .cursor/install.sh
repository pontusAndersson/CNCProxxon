#!/usr/bin/env bash
# Idempotent setup for the Proxxon MF70 / GRBL Arduino firmware project.
# Installs the Arduino toolchain (arduino-cli + AVR core) and the bundled
# GRBL library so the sketches under Arduino/ can be compiled/verified.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARDUINO_CLI_VERSION="1.5.1"

echo "==> Ensuring arduino-cli is installed"
if ! command -v arduino-cli >/dev/null 2>&1; then
  # Install pinned arduino-cli into /usr/local/bin (on the default PATH).
  curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh \
    | sudo env BINDIR=/usr/local/bin sh -s "${ARDUINO_CLI_VERSION}"
fi
arduino-cli version

echo "==> Configuring arduino-cli"
arduino-cli config init --overwrite
# Required to install the bundled GRBL library from a local .zip archive.
arduino-cli config set library.enable_unsafe_install true

echo "==> Installing Arduino AVR core (for Arduino Uno / ATmega328p)"
arduino-cli core update-index
arduino-cli core install arduino:avr

echo "==> Installing bundled GRBL library"
USER_LIB_DIR="$(arduino-cli config get directories.user)/libraries"
if [ ! -d "${USER_LIB_DIR}/grbl" ]; then
  arduino-cli lib install --zip-path "${REPO_DIR}/Arduino/grbl.zip"
else
  echo "GRBL library already installed at ${USER_LIB_DIR}/grbl"
fi

echo "==> Installed cores:"
arduino-cli core list
echo "==> Installed libraries:"
arduino-cli lib list

echo "==> Environment setup complete."
