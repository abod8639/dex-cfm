#!/bin/sh

INSTALL_DIR="/usr/local/bin/"
GIT_URL="https://github.com/nothingfr87/cfm.git"

cat << 'EOF'
  /$$$$$$  /$$$$$$$$ /$$      /$$
 /$$__  $$| $$_____/| $$$    /$$$
| $$  \__/| $$      | $$$$  /$$$$
| $$      | $$$$$   | $$ $$/$$ $$
| $$      | $$__/   | $$  $$$| $$
| $$    $$| $$      | $$\  $ | $$
 \______/ |__/      |__/  \  |__/
EOF

sleep 0.7

printf "\n\n\n\n\n"
printf "Do you want to install CFM? (y/n): "
read -r choice < /dev/tty

if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
  echo "Checking Dependencies..."

  # Detect system package manager dynamically
  if command -v apt-get >/dev/null 2>&1; then
    PKG_MANAGER="apt"
  elif command -v dnf >/dev/null 2>&1; then
    PKG_MANAGER="dnf"
  elif command -v yum >/dev/null 2>&1; then
    PKG_MANAGER="yum"
  elif command -v pacman >/dev/null 2>&1; then
    PKG_MANAGER="pacman"
  elif command -v zypper >/dev/null 2>&1; then
    PKG_MANAGER="zypper"
  else
    PKG_MANAGER="unknown"
  fi

  MISSING_PKGS=""

  # Check binary dependencies using 'command -v'
  if ! command -v git >/dev/null 2>&1; then
    MISSING_PKGS="git $MISSING_PKGS"
  fi

  if ! command -v pkg-config >/dev/null 2>&1; then
    MISSING_PKGS="pkg-config $MISSING_PKGS"
  fi

  if ! command -v gcc >/dev/null 2>&1 || ! command -v make >/dev/null 2>&1; then
    case "$PKG_MANAGER" in
      apt) MISSING_PKGS="build-essential $MISSING_PKGS" ;;
      dnf|yum) MISSING_PKGS="gcc make $MISSING_PKGS" ;;
      pacman) MISSING_PKGS="base-devel $MISSING_PKGS" ;;
      zypper) MISSING_PKGS="gcc make $MISSING_PKGS" ;;
      *) MISSING_PKGS="build-tools $MISSING_PKGS" ;;
    esac
  fi

  # Check for ncurses header (pkg-config check or file test)
  if ! pkg-config --exists ncurses >/dev/null 2>&1 && ! [ -f /usr/include/ncurses.h ]; then
    case "$PKG_MANAGER" in
      apt) MISSING_PKGS="libncurses-dev $MISSING_PKGS" ;;
      dnf|yum|zypper) MISSING_PKGS="ncurses-devel $MISSING_PKGS" ;;
      pacman) MISSING_PKGS="ncurses $MISSING_PKGS" ;;
    esac
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    MISSING_PKGS="fzf $MISSING_PKGS"
  fi

  # Check for 'fd' (Debian/Ubuntu binary is fd-find, others use fd)
  if ! command -v fd >/dev/null 2>&1 && ! command -v fdfind >/dev/null 2>&1; then
    case "$PKG_MANAGER" in
      apt) MISSING_PKGS="fd-find $MISSING_PKGS" ;;
      *) MISSING_PKGS="fd $MISSING_PKGS" ;;
    esac
  fi

  # Install missing packages if any are found
  if [ -n "$MISSING_PKGS" ]; then
    echo "The following missing packages are required: $MISSING_PKGS"
    echo "Requesting sudo permissions to install them..."

    case "$PKG_MANAGER" in
      apt)
        sudo apt-get update
        sudo apt-get install -y $MISSING_PKGS
        ;;
      dnf)
        sudo dnf install -y $MISSING_PKGS
        ;;
      yum)
        sudo yum install -y $MISSING_PKGS
        ;;
      pacman)
        sudo pacman -Sy --needed --noconfirm $MISSING_PKGS
        ;;
      zypper)
        sudo zypper install -y $MISSING_PKGS
        ;;
      *)
        echo "Error: Could not identify package manager to auto-install: $MISSING_PKGS"
        echo "Please install them manually and re-run this script."
        exit 1
        ;;
    esac
  else
    echo "All dependencies are already installed!"
  fi

  echo "Cloning CFM Repo..."
  rm -rf cfm
  git clone "$GIT_URL" --depth 1
  cd cfm || exit 1

  echo "Building & Installing CFM..."
  sudo make all install

  echo "Done! CFM Installed in $INSTALL_DIR"

  echo "Removing CFM Directory..."
  cd ..
  rm -rf cfm

else
  echo "Installation canceled."
  exit 0
fi
