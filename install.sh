#!/usr/bin/bash
# One-line installer:
#   curl -fsSL https://raw.githubusercontent.com/shashwat-kalpvaig/Revancify/main/install.sh | bash

REPO="shashwat-kalpvaig/Revancify"
BRANCH="main"

if [ -z "$PREFIX" ] || [[ "$PREFIX" != *com.termux* ]]; then
    echo "Termux not detected !!"
    exit 1
fi

BIN="$PREFIX/bin/revancify"

if ! curl -fsSL "https://raw.githubusercontent.com/$REPO/$BRANCH/revancify" -o "$BIN"; then
    echo "Unable to download Revancify. Check your internet connection and try again."
    exit 1
fi
chmod +x "$BIN"

# This script is usually piped into bash, so stdin is not the terminal.
# Reattach it, otherwise prompts and the dialog UI can't read keypresses.
exec "$BIN" "$@" < /dev/tty
