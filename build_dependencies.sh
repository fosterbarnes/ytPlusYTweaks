echo "=========================================="
echo "Build Dependencies Setup Script"
echo "=========================================="
echo ""

echo "[Step 1/7] Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo ""
echo "[Step 2/7] Configuring Homebrew..."
#detect homebrew path (Apple Silicon uses /opt/homebrew, Intel uses /usr/local)
if [ -f "/opt/homebrew/bin/brew" ]; then
    BREW_PATH="/opt/homebrew/bin/brew"
    echo "   Detected Apple Silicon Homebrew installation"
elif [ -f "/usr/local/bin/brew" ]; then
    BREW_PATH="/usr/local/bin/brew"
    echo "   Detected Intel Homebrew installation"
else
    # Try to find brew in PATH after installation
    BREW_PATH=$(which brew)
    if [ -z "$BREW_PATH" ]; then
        echo "Error: Could not find Homebrew installation"
        exit 1
    fi
    echo "   Found Homebrew in PATH: $BREW_PATH"
fi

#add to shell profile (detect which profile to use)
if [ -f "$HOME/.zprofile" ]; then
    PROFILE="$HOME/.zprofile"
elif [ -f "$HOME/.zshrc" ]; then
    PROFILE="$HOME/.zshrc"
elif [ -f "$HOME/.bash_profile" ]; then
    PROFILE="$HOME/.bash_profile"
else
    PROFILE="$HOME/.zprofile"
fi
echo "   Using shell profile: $PROFILE"

echo >> "$PROFILE"
echo "eval \"\$($BREW_PATH shellenv)\"" >> "$PROFILE"
eval "$($BREW_PATH shellenv)"
echo "   Homebrew version: $(brew --version | head -n1)"

echo ""
echo "[Step 3/7] Installing build tools (wget, make, ldid, pipx)..."
echo "   Installing wget..."
brew install wget

echo "   Installing make, ldid, pipx, and meson..."
brew install make ldid pipx meson

#update path for new version of make
echo 'export PATH="$(brew --prefix make)/libexec/gnubin:$PATH"' >> "$PROFILE"
source "$PROFILE"

#pipx to path
echo "   Configuring pipx..."
pipx ensurepath

echo ""
echo "[Step 4/7] Setting up Theos..."
THEOS_DIR="$HOME/theos"
echo "   Creating Theos directory: $THEOS_DIR"
mkdir -p "$THEOS_DIR"
cd "$THEOS_DIR"
if [ -d ".git" ]; then
    echo "   Theos already exists. Pulling latest changes..."
    git pull --recurse-submodules
else
    echo "   Cloning Theos repository (this may take a moment)..."
    git clone --recursive https://github.com/theos/theos.git .
fi
echo "   Adding Theos to shell profile..."
echo "export THEOS=\"$THEOS_DIR\"" >> "$PROFILE"
echo 'export PATH=$THEOS/bin:$PATH' >> "$PROFILE"
export THEOS="$THEOS_DIR"
echo "   Theos installed at: $THEOS"

echo ""
echo "[Step 5/7] Downloading iOS SDKs..."
cd "$THEOS_DIR"
rm -rf sdks
mkdir -p sdks

echo "   [1/3] iPhoneOS16.5.sdk (theos/sdks)..."
(
    tmp=$(mktemp -d)
    cd "$tmp"
    git clone --quiet -n --depth=1 --filter=tree:0 https://github.com/theos/sdks/
    cd sdks
    git sparse-checkout set --no-cone iPhoneOS16.5.sdk
    git checkout
    mv *.sdk "$THEOS_DIR/sdks/"
    rm -rf "$tmp"
)

echo "   [2/3] iPhoneOS17.5.sdk (Tonwalter888/iOS-SDKs)..."
(
    tmp=$(mktemp -d)
    cd "$tmp"
    git clone --quiet --no-tags --single-branch --depth=1 -n --filter=tree:0 https://github.com/Tonwalter888/iOS-SDKs
    cd iOS-SDKs
    git sparse-checkout set --no-cone iPhoneOS17.5.sdk
    git checkout
    mv *.sdk "$THEOS_DIR/sdks/"
    rm -rf "$tmp"
)

echo "   [3/3] iPhoneOS18.6.sdk (Tonwalter888/iOS-SDKs)..."
(
    tmp=$(mktemp -d)
    cd "$tmp"
    git clone --quiet --no-tags --single-branch --depth=1 -n --filter=tree:0 https://github.com/Tonwalter888/iOS-SDKs
    cd iOS-SDKs
    git sparse-checkout set --no-cone iPhoneOS18.6.sdk
    git checkout
    mv *.sdk "$THEOS_DIR/sdks/"
    rm -rf "$tmp"
)
echo "   Done! Installed $(ls "$THEOS_DIR/sdks/" | wc -l | xargs) SDK(s)"

echo ""
echo "[Step 6/7] Installing Cyan..."
echo "   Installing Cyan via pipx..."
pipx install --force https://github.com/asdfzxcvbn/pyzule-rw/archive/main.zip
echo "   Done!"


echo ""
echo "[Step 7/7] Verifying installation..."
echo ""
echo "=== Build Environment Test ==="
echo ""
source $PROFILE

echo "1. System Tools:"
echo "   Xcode CLI: $(xcode-select -p)"
if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
    if ! xcrun --sdk iphoneos --show-sdk-path &>/dev/null; then
        echo "   ⚠️  iphoneos SDK not available (xcode-select may point to CLT, not Xcode)"
        echo "   Fix: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    else
        echo "   iphoneos SDK: $(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)"
    fi
else
    echo "   ⚠️  Xcode.app not found — required for YTUHD (libvpx) builds"
fi
echo "   Homebrew: $(brew --version | head -n1)"
echo "   Git: $(git --version)"
echo "   wget: $(wget --version | head -n1)"
echo ""

echo "2. Build Tools:"
echo "   Make: $(make --version | head -n1)"
echo "   ldid: $(ldid 2>&1 | head -n1)"
echo "   pipx: $(pipx --version)"
echo ""

echo "3. Theos:"
echo "   THEOS: $THEOS"
if [ -d "$THEOS" ]; then
    echo "   Theos exists: ✓"
    echo "   SDKs installed:"
    ls "$THEOS/sdks/" 2>/dev/null | sed 's/^/     - /' || echo "     (none)"
else
    echo "   Theos exists: ✗"
fi
echo ""

echo "4. Cyan:"
if command -v cyan &> /dev/null; then
    echo "   Cyan installed: ✓"
else
    echo "   Cyan installed: ✗ (Terminal may need to be restarted for changes to take effect)"
fi
echo ""

echo "=== Test Complete ==="
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo "All dependencies have been installed and configured."
echo "You may need to restart your terminal or run 'source $PROFILE'"
echo "for all changes to take effect."
echo ""