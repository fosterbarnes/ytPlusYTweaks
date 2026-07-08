echo "=========================================="
echo "ytPlusYTweaks Build Dependencies Setup"
echo "=========================================="
echo ""

echo "[Step 1/7] Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo ""
echo "[Step 2/7] Configuring Homebrew..."
if [ -f "/opt/homebrew/bin/brew" ]; then
    BREW_PATH="/opt/homebrew/bin/brew"
    echo "   Detected Apple Silicon Homebrew installation"
elif [ -f "/usr/local/bin/brew" ]; then
    BREW_PATH="/usr/local/bin/brew"
    echo "   Detected Intel Homebrew installation"
else
    BREW_PATH=$(which brew)
    [ -z "$BREW_PATH" ] && { echo "Error: Could not find Homebrew installation"; exit 1; }
    echo "   Found Homebrew in PATH: $BREW_PATH"
fi

if [ -f "$HOME/.zprofile" ]; then PROFILE="$HOME/.zprofile"
elif [ -f "$HOME/.zshrc" ]; then PROFILE="$HOME/.zshrc"
elif [ -f "$HOME/.bash_profile" ]; then PROFILE="$HOME/.bash_profile"
else PROFILE="$HOME/.zprofile"; fi
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

echo 'export PATH="$(brew --prefix make)/libexec/gnubin:$PATH"' >> "$PROFILE"
source "$PROFILE"

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

SDKS=(
    "iPhoneOS16.5.sdk|https://github.com/theos/sdks/|sdks"
    "iPhoneOS17.5.sdk|https://github.com/Tonwalter888/iOS-SDKs|iOS-SDKs"
    "iPhoneOS18.6.sdk|https://github.com/Tonwalter888/iOS-SDKs|iOS-SDKs"
)
n=1
for spec in "${SDKS[@]}"; do
    IFS='|' read -r sdk repo repoDir <<< "$spec"
    echo "   [$n/3] $sdk ($repo)..."
    (
        tmp=$(mktemp -d)
        cd "$tmp"
        git clone --quiet --no-tags --single-branch --depth=1 -n --filter=tree:0 "$repo"
        cd "$repoDir"
        git sparse-checkout set --no-cone "$sdk"
        git checkout
        mv *.sdk "$THEOS_DIR/sdks/"
        rm -rf "$tmp"
    )
    ((n++))
done
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
source "$PROFILE"

echo "1. System Tools:"
echo "   Xcode CLI: $(xcode-select -p)"
if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
    if ! xcrun --sdk iphoneos --show-sdk-path &>/dev/null; then
        echo "   WARNING: iphoneos SDK not available (xcode-select may point to CLT, not Xcode)"
        echo "   Fix: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    else
        echo "   iphoneos SDK: $(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)"
    fi
else
    echo "   WARNING: Xcode.app not found — required for YTUHD (libvpx) builds"
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
    echo "   Theos exists: yes"
    echo "   SDKs installed:"
    ls "$THEOS/sdks/" 2>/dev/null | sed 's/^/     - /' || echo "     (none)"
else
    echo "   Theos exists: no"
fi
echo ""

echo "4. Cyan:"
if command -v cyan &> /dev/null; then
    echo "   Cyan installed: yes"
else
    echo "   Cyan installed: no (Terminal may need to be restarted for changes to take effect)"
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