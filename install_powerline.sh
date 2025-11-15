#!/usr/bin/env bash
# Fail on any error, undefined var, or pipe failure.
set -euo pipefail

# Install Powerline for VIM via APT (no pip issues).
sudo apt update
sudo apt install -y python3-pip powerline fonts-powerline

# Copy VIM config (no sudo, so ~/.vimrc stays owned by the user).
cp configs/.vimrc "$HOME/.vimrc"

# Install patched fonts from the repo.
mkdir -p "$HOME/.fonts"
cp -a fonts/. "$HOME/.fonts/"

# Rebuild font cache so the new fonts are recognized.
fc-cache -vf "$HOME/.fonts/"
