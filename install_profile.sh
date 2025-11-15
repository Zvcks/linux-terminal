#!/usr/bin/env bash
set -euo pipefail

# ----- Info / warnings -----

if [[ "$EUID" -eq 0 ]]; then
  echo "[!] Warning: this script is running as ROOT."
  echo "    It will install configuration into /root (root's home directory)."
  echo "    This is usually not recommended for daily use shells."
fi

echo "[+] Starting profile installation..."

# ----- Oh My Zsh detection -----

# Respect ZSH env var if set, fallback to ~/.oh-my-zsh
OH_MY_ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"

if [[ ! -d "$OH_MY_ZSH_DIR" ]]; then
  echo "[-] Oh My Zsh not found in: $OH_MY_ZSH_DIR"
  echo "    Install Oh My Zsh first, e.g.:"
  echo "      sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
  exit 1
fi

PLUGINS_DIR="$OH_MY_ZSH_DIR/custom/plugins"
THEMES_DIR="$OH_MY_ZSH_DIR/themes"

mkdir -p "$PLUGINS_DIR"

# ----- Plugins -----

echo "[+] Installing plugins into: $PLUGINS_DIR"
(
  cd "$PLUGINS_DIR"

  if [[ ! -d zsh-syntax-highlighting ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting
  else
    echo "  - zsh-syntax-highlighting already exists, skipping clone"
  fi

  if [[ ! -d zsh-autosuggestions ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions
  else
    echo "  - zsh-autosuggestions already exists, skipping clone"
  fi
)

# ----- .zshrc + theme -----

echo "[+] Installing .zshrc into: $HOME/.zshrc"
cp configs/.zshrc "$HOME/.zshrc"

echo "[+] Installing custom theme into: $THEMES_DIR"
cp configs/pixegami-agnoster.zsh-theme \
   "$THEMES_DIR/pixegami-agnoster.zsh-theme"

# ----- Optional: GNOME Terminal profile via dconf -----

PROFILE_ID="fb358fc9-49ea-4252-ad34-1d25c649e633"
PROFILE_PATH="/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/"

if command -v dconf >/dev/null 2>&1; then
  echo "[+] 'dconf' found, applying GNOME Terminal profile…"

  if [[ -f configs/terminal_profile.dconf ]]; then
    dconf load "$PROFILE_PATH" < configs/terminal_profile.dconf

    # Read current list of profiles (or default to empty list)
    OLD_LIST="$(dconf read /org/gnome/terminal/legacy/profiles:/list || echo '[]')"
    OLD_LIST_NO_BRACKETS="${OLD_LIST#\[}"
    OLD_LIST_NO_BRACKETS="${OLD_LIST_NO_BRACKETS%\]}"

    if [[ -z "$OLD_LIST_NO_BRACKETS" ]]; then
      NEW_LIST="['$PROFILE_ID']"
    else
      # Avoid duplicate entries
      if [[ "$OLD_LIST" == *"$PROFILE_ID"* ]]; then
        NEW_LIST="$OLD_LIST"
      else
        NEW_LIST="[$OLD_LIST_NO_BRACKETS, '$PROFILE_ID']"
      fi
    fi

    dconf write /org/gnome/terminal/legacy/profiles:/list "$NEW_LIST"
    dconf write /org/gnome/terminal/legacy/profiles:/default "'$PROFILE_ID'"
  else
    echo "[!] configs/terminal_profile.dconf not found, skipping terminal color profile."
  fi
else
  echo "[!] 'dconf' command not found. Skipping GNOME Terminal color profile."
fi

# ----- Switch default shell to zsh (already installed in previous step) -----

ZSH_BIN="$(command -v zsh || true)"
if [[ -n "$ZSH_BIN" ]]; then
  echo "[+] Setting default shell to: $ZSH_BIN"
  chsh -s "$ZSH_BIN" || echo '[!] chsh failed (maybe non-interactive or no passwd entry).'
else
  echo "[!] 'zsh' binary not found in PATH. Skipping chsh."
fi

echo "[+] Done. Open a new terminal (or re-login) to use the new zsh profile."
