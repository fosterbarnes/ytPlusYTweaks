#!/bin/bash

# YTPlusYTweaks Build Script
# Usage: ./build.sh --ipa-url <URL> [options]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
ENABLE_YOUPIP=true
ENABLE_YTUHD=true
ENABLE_YQ=true
ENABLE_RYD=true
ENABLE_DEMC=true
ENABLE_YTABCONFIG=true
ENABLE_YTWEAKS=true
ENABLE_YTICONS=false
ENABLE_YOUGROUPSETTINGS=true
ENABLE_GONERINO=false
ENABLE_AUTOFLEX=false
TWEAK_VERSION=""
TWEAK_VERSION_PROVIDED=false
DISPLAY_NAME="YouTube"
BUNDLE_ID="com.google.ios.youtube"
IPA_SOURCE=""
IPA_PROVIDED=false
ROOT_DIR="$(pwd)"
BUILD_DIR="$(pwd)/build"
USE_PREBUILT_DEBS=false
THEOS_COMMIT="67db2ab8d950910161730de77c322658ea3e6b44"
SDK_VERSION="16.5"
APP_VERSION=""

# Functions to print colored output
print_info() { echo -e "${BLUE}[INFO]${NC} $1" 
}
print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}
print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
    cat << EOF
YTPlusYTweaks Build Script

Usage: $0 --ipa [URL] [options]

IPAs Source:
    --ipa [URL]                  If URL provided: download IPA from URL (saves to ipa/)
                                  If no URL: use local IPA from ipa/ folder (looks for *.ipa files)

Optional Arguments:
    --deb                        Use pre-built .deb files from deb/ folder. Otherwise, build from source.
    --sdk <version>              iOS SDK version: 16.5, 17.5, or 18.6 (default: 16.5)
    --tweak-version <version>    Version of YTLite tweak (default: auto-detect latest)
    --display-name <name>        App display name (default: YouTube)
    --bundle-id <id>             Bundle ID (default: com.google.ios.youtube)

Tweak Integration Flags:
    --enable-all                 Enable all tweaks
    --disable-all                Disable all tweaks
    
    --enable-youpip              YouPiP (default: true)
    --enable-ytuhd               YTUHD (default: true)
    --enable-yq                  YouQuality (default: true)
    --enable-ryd                 Return YouTube Dislikes (default: true)
    --enable-demc                DontEatMyContent (default: true)
    --enable-ytabconfig          YTABConfig (default: true)
    --enable-ytweaks             YTweaks (default: true)
    --enable-yougroupsettings    Settings (default: true)
    --enable-yticons             YTIcons (default: false)
    --enable-gonerino            Gonerino (default: false)
    --enable-autoflex            AutoFLEX (default: false)

    --disable-youpip             YouPiP
    --disable-ytuhd              YTUHD
    --disable-yq                 YouQuality
    --disable-ryd                Return YouTube Dislikes
    --disable-demc               DontEatMyContent
    --disable-ytabconfig         YTABConfig
    --disable-ytweaks            YTweaks
    --disable-yougroupsettings   YouGroupSettings
    --disable-yticons            YTIcons
    --disable-gonerino           Gonerino
    --disable-autoflex           AutoFLEX

Other Options:
    -h, --help                   Show this help message

Examples:
    $0 --ipa https://example.com/youtube.ipa
    $0 --ipa --sdk 17.5
    $0 --ipa --deb --disable-all
    $0 --ipa --disable-yticons --enable-ytweaks

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --ipa)
                IPA_PROVIDED=true
                # Check if next argument is a URL or another flag
                if [[ $# -gt 1 ]] && [[ "$2" != --* ]] && [[ "$2" =~ ^https?:// ]]; then
                    IPA_SOURCE="$2"
                    shift 2
                else
                    # No URL provided, use local IPA
                    IPA_SOURCE=""
                    shift
                fi
                ;;
            --sdk)
                SDK_VERSION="$2"
                case "$SDK_VERSION" in
                    16.5|17.5|18.6) ;;
                    *)
                        print_error "Unsupported SDK version: $SDK_VERSION (use 16.5, 17.5, or 18.6)"
                        usage
                        exit 1
                        ;;
                esac
                shift 2
                ;;
            --tweak-version)
                TWEAK_VERSION="$2"
                TWEAK_VERSION_PROVIDED=true
                shift 2
                ;;
            --display-name)
                DISPLAY_NAME="$2"
                shift 2
                ;;
            --bundle-id)
                BUNDLE_ID="$2"
                shift 2
                ;;
            --enable-all)
                ENABLE_YOUPIP=true
                ENABLE_YTUHD=true
                ENABLE_YQ=true
                ENABLE_RYD=true
                ENABLE_DEMC=true
                ENABLE_YTABCONFIG=true
                ENABLE_YTWEAKS=true
                ENABLE_YTICONS=true
                ENABLE_YOUGROUPSETTINGS=true
                ENABLE_GONERINO=true
                ENABLE_AUTOFLEX=true
                shift
                ;;
            --disable-all)
                ENABLE_YOUPIP=false
                ENABLE_YTUHD=false
                ENABLE_YQ=false
                ENABLE_RYD=false
                ENABLE_DEMC=false
                ENABLE_YTABCONFIG=false
                ENABLE_YTWEAKS=false
                ENABLE_YTICONS=false
                ENABLE_YOUGROUPSETTINGS=false
                ENABLE_GONERINO=false
                ENABLE_AUTOFLEX=false
                shift
                ;;
            --enable-*)
                # Extract tweak name from flag (e.g., --enable-youpip -> youpip)
                local tweak_name="${1#--enable-}"
                # Map tweak names to variable names
                case "$tweak_name" in
                    youpip) ENABLE_YOUPIP=true ;;
                    ytuhd) ENABLE_YTUHD=true ;;
                    yq) ENABLE_YQ=true ;;
                    ryd) ENABLE_RYD=true ;;
                    demc) ENABLE_DEMC=true ;;
                    ytabconfig) ENABLE_YTABCONFIG=true ;;
                    ytweaks) ENABLE_YTWEAKS=true ;;
                    yticons) ENABLE_YTICONS=true ;;
                    yougroupsettings) ENABLE_YOUGROUPSETTINGS=true ;;
                    gonerino) ENABLE_GONERINO=true ;;
                    autoflex) ENABLE_AUTOFLEX=true ;;
                    *)
                        print_error "Unknown tweak: $tweak_name"
                        usage
                        exit 1
                        ;;
                esac
                shift
                ;;
            --disable-*)
                # Extract tweak name from flag 
                local tweak_name="${1#--disable-}"
                # Map tweak names to variable names
                case "$tweak_name" in
                    youpip) ENABLE_YOUPIP=false ;;
                    ytuhd) ENABLE_YTUHD=false ;;
                    yq) ENABLE_YQ=false ;;
                    ryd) ENABLE_RYD=false ;;
                    demc) ENABLE_DEMC=false ;;
                    ytabconfig) ENABLE_YTABCONFIG=false ;;
                    ytweaks) ENABLE_YTWEAKS=false ;;
                    yticons) ENABLE_YTICONS=false ;;
                    yougroupsettings) ENABLE_YOUGROUPSETTINGS=false ;;
                    gonerino) ENABLE_GONERINO=false ;;
                    autoflex) ENABLE_AUTOFLEX=false ;;
                    *)
                        print_error "Unknown tweak: $tweak_name"
                        usage
                        exit 1
                        ;;
                esac
                shift
                ;;
            --use-prebuilt-debs|--deb)
                USE_PREBUILT_DEBS=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Validate IPA source
    if [[ "$IPA_PROVIDED" != "true" ]]; then
        print_error "You must specify --ipa (with optional URL) to provide an IPA source"
        usage
        exit 1
    fi
}

# Ensure THEOS is set (e.g. from build_dependencies.sh or environment)
ensure_theos() {
    if [[ -z "${THEOS:-}" ]]; then
        THEOS="$HOME/theos"
        export THEOS
        print_info "THEOS not set; using $THEOS"
    fi
    if [[ ! -d "$THEOS" ]]; then
        print_error "THEOS directory not found: $THEOS. Run build_dependencies.sh first."
        exit 1
    fi
}

# Download and install the selected iOS SDK if not already present.
ensure_sdk() {
    ensure_theos
    mkdir -p "$THEOS/sdks"
    local sdk_dir="$THEOS/sdks/iPhoneOS${SDK_VERSION}.sdk"
    if [[ -d "$sdk_dir" ]]; then
        print_info "iOS SDK $SDK_VERSION already present at $sdk_dir"
        return
    fi
    print_info "Downloading iOS $SDK_VERSION SDK..."
    local tmp_sdk=$(mktemp -d)
    (
        cd "$tmp_sdk"
        case "$SDK_VERSION" in
            16.5)
                git clone --quiet -n --depth=1 --filter=tree:0 https://github.com/theos/sdks/
                cd sdks
                git sparse-checkout set --no-cone iPhoneOS16.5.sdk
                git checkout
                mv *.sdk "$THEOS/sdks/"
                ;;
            17.5)
                git clone --quiet --no-tags --single-branch --depth=1 -n --filter=tree:0 https://github.com/Tonwalter888/iOS-SDKs
                cd iOS-SDKs
                git sparse-checkout set --no-cone iPhoneOS17.5.sdk
                git checkout
                mv *.sdk "$THEOS/sdks/"
                ;;
            18.6)
                git clone --quiet --no-tags --single-branch --depth=1 -n --filter=tree:0 https://github.com/Tonwalter888/iOS-SDKs
                cd iOS-SDKs
                git sparse-checkout set --no-cone iPhoneOS18.6.sdk
                git checkout
                mv *.sdk "$THEOS/sdks/"
                ;;
            *)
                print_error "Unsupported SDK version: $SDK_VERSION"
                exit 1
                ;;
        esac
    )
    rm -rf "$tmp_sdk"
    if [[ ! -d "$sdk_dir" ]]; then
        print_error "Failed to install iOS SDK $SDK_VERSION"
        exit 1
    fi
    print_success "iOS SDK $SDK_VERSION installed"
}

# Extract app version (CFBundleShortVersionString) from the IPA for output naming
get_app_version() {
    print_info "Extracting app version from IPA..."
    local info_plist
    info_plist=$(unzip -l "$BUILD_DIR/youtube.ipa" | grep -o "Payload/[^/]*\.app/Info\.plist" | head -n 1)
    if [[ -z "$info_plist" ]]; then
        print_error "Could not find Info.plist in IPA"
        exit 1
    fi
    local extract_dir="$BUILD_DIR/ipa_extract"
    mkdir -p "$extract_dir"
    unzip -p "$BUILD_DIR/youtube.ipa" "$info_plist" > "$extract_dir/Info.plist"
    APP_VERSION=$(plutil -p "$extract_dir/Info.plist" 2>/dev/null | grep "CFBundleShortVersionString" | sed -E 's/.*"CFBundleShortVersionString"[[:space:]]*=>[[:space:]]*"([^"]+)".*/\1/')
    if [[ -z "$APP_VERSION" ]]; then
        print_error "Could not extract app version from Info.plist"
        exit 1
    fi
    print_success "App version: $APP_VERSION"
}

# Check if any tweaks are enabled
any_tweaks_enabled() {
    [[ "$ENABLE_YOUPIP" == "true" ]] || \
    [[ "$ENABLE_YTUHD" == "true" ]] || \
    [[ "$ENABLE_YQ" == "true" ]] || \
    [[ "$ENABLE_RYD" == "true" ]] || \
    [[ "$ENABLE_DEMC" == "true" ]] || \
    [[ "$ENABLE_YTABCONFIG" == "true" ]] || \
    [[ "$ENABLE_YTWEAKS" == "true" ]] || \
    [[ "$ENABLE_YTICONS" == "true" ]] || \
    [[ "$ENABLE_YOUGROUPSETTINGS" == "true" ]] || \
    [[ "$ENABLE_GONERINO" == "true" ]] || \
    [[ "$ENABLE_AUTOFLEX" == "true" ]]
}

# Setup workspace
setup_workspace() {
    print_info "Setting up workspace..."
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    
    cd "$BUILD_DIR"
}

# Setup IPA file
setup_ipa() {
    mkdir -p "$ROOT_DIR/ipa"
    
    if [[ -n "$IPA_SOURCE" ]]; then
        print_info "Downloading IPA from: $IPA_SOURCE"
        wget "$IPA_SOURCE" --no-verbose -O "$BUILD_DIR/youtube.ipa"
        
        if [[ ! -f "$BUILD_DIR/youtube.ipa" ]]; then
            print_error "Failed to download IPA file"
            exit 1
        fi
        
        cp "$BUILD_DIR/youtube.ipa" "$ROOT_DIR/ipa/youtube.ipa"
        print_info "Saved IPA to ipa/ folder for future use"
    else
        print_info "Looking for IPA in ipa/ folder..."
        local ipa_files=("$ROOT_DIR/ipa"/*.ipa)
        
        if [[ -f "${ipa_files[0]}" ]]; then
            local ipa_file="${ipa_files[0]}"
            print_info "Found IPA: $(basename "$ipa_file")"
            cp "$ipa_file" "$BUILD_DIR/youtube.ipa"
            print_success "Using local IPA: $(basename "$ipa_file")"
        else
            print_error "No IPA files found in ipa/ folder"
            print_info "Please place a .ipa file in the ipa/ directory, or use --ipa <URL> to download one"
            exit 1
        fi
    fi
    
    if [[ ! -f "$BUILD_DIR/youtube.ipa" ]]; then
        print_error "IPA file not found"
        exit 1
    fi
    
    file_type=$(file --mime-type -b "$BUILD_DIR/youtube.ipa")
    
    if [[ "$file_type" != "application/x-ios-app" && "$file_type" != "application/zip" ]]; then
        print_error "Validation failed: The file is not a valid IPA. Detected type: $file_type"
        exit 1
    fi
    
    print_success "IPA ready: $(basename "$BUILD_DIR/youtube.ipa")"
}

# Get latest YTLite version from GitHub
get_latest_version() {
    if [[ "$TWEAK_VERSION_PROVIDED" == "true" ]]; then
        print_info "Using provided version: $TWEAK_VERSION"
        return
    fi
    
    print_info "Fetching latest YTLite version from GitHub..."
    
    # Try different methods to parse JSON response
    local api_response=""
    local latest_tag=""
    
    # Try to get the latest release tag from GitHub API
    if [[ -n "$GITHUB_TOKEN" ]]; then
        api_response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/repos/dayanch96/YTLite/releases/latest")
    else
        api_response=$(curl -s -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/repos/dayanch96/YTLite/releases/latest")
    fi
    
    # Check if we got a valid response
    if [[ -z "$api_response" ]] || [[ "$api_response" == *"Not Found"* ]] || [[ "$api_response" == *"rate limit"* ]]; then
        print_warning "Failed to fetch latest version from GitHub API"
        print_warning "Falling back to default version: 5.2b4"
        TWEAK_VERSION="5.2b4"
        return
    fi
    
    # Try to parse with jq if available
    if command -v jq &> /dev/null; then
        latest_tag=$(echo "$api_response" | jq -r '.tag_name // empty')
    # Try with Python if available
    elif command -v python3 &> /dev/null; then
        latest_tag=$(echo "$api_response" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tag_name', ''))" 2>/dev/null)
    # Fall back to grep/sed parsing
    else
        latest_tag=$(echo "$api_response" | grep -o '"tag_name": "[^"]*' | head -n 1 | sed 's/"tag_name": "//')
    fi
    
    if [[ -z "$latest_tag" ]] || [[ "$latest_tag" == "null" ]]; then
        print_warning "Failed to parse version from GitHub API response"
        print_warning "Falling back to default version: 5.2b4"
        TWEAK_VERSION="5.2b4"
        return
    fi
    
    # Remove 'v' prefix if present (e.g., v5.2b4 -> 5.2b4)
    VERSION="${latest_tag#v}"
    TWEAK_VERSION="$VERSION"
    print_success "Latest version found: $TWEAK_VERSION (tag: $latest_tag)"
}

# Download YouTube Plus
download_ytplus() {
    print_info "Downloading YouTube Plus..."
    
    deb_url="https://github.com/dayanch96/YTLite/releases/download/v${TWEAK_VERSION}/com.dvntm.ytlite_${TWEAK_VERSION}_iphoneos-arm.deb"
    
    wget "$deb_url" --no-verbose -O "$BUILD_DIR/ytplus.deb"
    
    if [[ ! -f "$BUILD_DIR/ytplus.deb" ]]; then
        print_error "Failed to download YouTube Plus .deb"
        exit 1
    fi
    
    print_success "YouTube Plus downloaded"
}

# Clone Safari extension
clone_safari_extension() {
    print_info "Cloning Open in YouTube Safari extension..."
    
    if [[ -f "$BUILD_DIR/OpenYoutubeSafariExtension.appex" ]]; then
        print_info "Safari extension already exists"
        return
    fi
    
    temp_ext_dir=$(mktemp -d)
    cd "$temp_ext_dir"
    
    git clone --quiet -n --depth=1 --filter=tree:0 https://github.com/CokePokes/YoutubeExtensions/
    cd YoutubeExtensions
    git sparse-checkout set --no-cone OpenYoutubeSafariExtension.appex
    git checkout --quiet
    
    # Check for .appex file - use shopt to handle globs properly
    shopt -s nullglob
    appex_files=(*.appex)
    shopt -u nullglob
    
    if [[ ${#appex_files[@]} -gt 0 ]]; then
        # Move the first .appex file found
        mv "${appex_files[0]}" "$BUILD_DIR/OpenYoutubeSafariExtension.appex"
        print_success "Safari extension cloned"
    else
        # Try finding in subdirectories
        appex_file=$(find . -name "*.appex" -type f 2>/dev/null | head -n 1)
        if [[ -n "$appex_file" && -f "$appex_file" ]]; then
            mv "$appex_file" "$BUILD_DIR/OpenYoutubeSafariExtension.appex"
            print_success "Safari extension cloned (from subdirectory)"
        else
            print_error "Failed to clone Safari extension - .appex file not found"
            print_info "Directory contents after checkout:"
            ls -la
            print_info "Searching for .appex files:"
            find . -type f -name "*.appex" 2>/dev/null || echo "No .appex files found"
            cd "$BUILD_DIR"
            rm -rf "$temp_ext_dir"
            exit 1
        fi
    fi
    
    cd "$BUILD_DIR"
    rm -rf "$temp_ext_dir"
}

# Clone YouTubeHeader
clone_youtube_header() {
    if ! any_tweaks_enabled; then
        return
    fi
    
    print_info "Cloning YouTubeHeader..."
    
    if [[ -d "$THEOS/include/YouTubeHeader" ]]; then
        print_info "YouTubeHeader exists. Pulling latest changes..."
        cd "$THEOS/include/YouTubeHeader"
        git pull --quiet
        cd "$BUILD_DIR"
    else
        print_info "YouTubeHeader does not exist. Cloning repository..."
        mkdir -p "$THEOS/include"
        cd "$THEOS/include"
        git clone --quiet --depth=1 https://github.com/PoomSmart/YouTubeHeader.git
        cd "$BUILD_DIR"
    fi
    
    # Copy to YTHeaders if DontEatMyContent is enabled
    if [[ "$ENABLE_DEMC" == "true" ]]; then
        print_info "Copying YouTubeHeader to YTHeaders for DontEatMyContent..."
        rm -rf "$THEOS/include/YTHeaders"
        cp -r "$THEOS/include/YouTubeHeader" "$THEOS/include/YTHeaders"
    fi
    
    print_success "YouTubeHeader setup complete"
}

# Clone PSHeader
clone_ps_header() {
    if ! any_tweaks_enabled; then
        return
    fi
    
    print_info "Cloning PSHeader..."
    
    if [[ -d "$THEOS/include/PSHeader" ]]; then
        print_info "PSHeader exists. Pulling latest changes..."
        cd "$THEOS/include/PSHeader"
        git pull --quiet
        cd "$BUILD_DIR"
    else
        print_info "PSHeader does not exist. Cloning repository..."
        mkdir -p "$THEOS/include"
        cd "$THEOS/include"
        git clone --quiet --depth=1 https://github.com/PoomSmart/PSHeader.git
        cd "$BUILD_DIR"
    fi
    
    print_success "PSHeader setup complete"
}

# Helper function to clone a single tweak
# Usage: clone_tweak <enable_flag> <name> <deb_name> <repo_url> [extra_git_flags]
clone_tweak() {
    local enable_flag="$1"
    local name="$2"
    local deb_name="$3"
    local repo_url="$4"
    local extra_flags="${5:-}"
    
    if [[ "$enable_flag" != "true" ]]; then
        return
    fi
    
    if [[ "$USE_PREBUILT_DEBS" == "true" ]] && [[ -f "$BUILD_DIR/$deb_name" ]]; then
        print_info "Skipping $name clone (using pre-built)"
        return
    fi
    
    if [[ ! -d "$name" ]]; then
        print_info "Cloning $name..."
        if [[ -n "$extra_flags" ]]; then
            git clone --quiet --depth=1 $extra_flags "$repo_url" "$name"
        else
            git clone --quiet --depth=1 "$repo_url" "$name"
        fi
    fi
}

# Clone tweak repositories
clone_tweaks() {
    if ! any_tweaks_enabled; then
        return
    fi
    
    print_info "Cloning tweak repositories..."
    
    cd "$BUILD_DIR"
    
    clone_tweak "$ENABLE_YOUPIP" "YouPiP" "youpip.deb" "https://github.com/PoomSmart/YouPiP.git"
    clone_tweak "$ENABLE_YTUHD" "YTUHD" "ytuhd.deb" "https://github.com/Tonwalter888/YTUHD.git"
    clone_tweak "$ENABLE_RYD" "Return-YouTube-Dislikes" "ryd.deb" "https://github.com/PoomSmart/Return-YouTube-Dislikes.git"
    clone_tweak "$ENABLE_YOUGROUPSETTINGS" "YouGroupSettings" "ygs.deb" "https://github.com/fosterbarnes/YouGroupSettings.git"
    clone_tweak "$ENABLE_YQ" "YouQuality" "yq.deb" "https://github.com/PoomSmart/YouQuality.git"
    clone_tweak "$ENABLE_YTABCONFIG" "YTABConfig" "yabc.deb" "https://github.com/PoomSmart/YTABConfig.git"
    clone_tweak "$ENABLE_YTWEAKS" "YTweaks" "ytwks.deb" "https://github.com/fosterbarnes/YTweaks.git"
    clone_tweak "$ENABLE_YTICONS" "YTIcons" "yticons.deb" "https://github.com/PoomSmart/YTIcons.git"
    clone_tweak "$ENABLE_DEMC" "DontEatMyContent" "demc.deb" "https://github.com/therealFoxster/DontEatMyContent.git" "--recurse-submodules"
    clone_tweak "$ENABLE_GONERINO" "Gonerino" "gonerino.deb" "https://github.com/fosterbarnes/YGonerino.git"
    clone_tweak "$ENABLE_AUTOFLEX" "AutoFLEX" "autoflex.deb" "https://github.com/pwnless/AutoFLEX.git"
    
    # YTVideoOverlay is required if YouPiP or YouQuality is enabled
    if [[ "$ENABLE_YQ" == "true" ]] || [[ "$ENABLE_YOUPIP" == "true" ]]; then
        clone_tweak "true" "YTVideoOverlay" "ytvo.deb" "https://github.com/PoomSmart/YTVideoOverlay.git"
    fi
    
    print_success "Tweak repositories cloned"
}

# Helper function to copy a pre-built deb file
# Usage: copy_prebuilt_deb <enable_flag> <deb_name> <display_name> <pattern1> [pattern2]
# Returns: 0 if found and copied, 1 if not found
copy_prebuilt_deb() {
    local enable_flag="$1"
    local deb_name="$2"
    local display_name="$3"
    local pattern1="$4"
    local pattern2="${5:-}"
    
    if [[ "$enable_flag" != "true" ]]; then
        return 1
    fi
    
    local search_patterns="$pattern1"
    if [[ -n "$pattern2" ]]; then
        search_patterns="$pattern1 $pattern2"
    fi
    
    if ls $search_patterns 2>/dev/null | head -n 1 | grep -q .; then
        local deb_file=$(ls $search_patterns 2>/dev/null | head -n 1)
        if cp "$deb_file" "$BUILD_DIR/$deb_name" 2>/dev/null; then
            print_info "Found pre-built $display_name .deb"
            return 0
        fi
    fi
    
    return 1
}

# Copy pre-built debs from deb folder
copy_prebuilt_debs() {
    print_info "Using pre-built .deb files from deb/ folder..."
    
    mkdir -p "$ROOT_DIR/deb"
    cd "$ROOT_DIR/deb"
    
    local deb_count=0
    local missing_debs=()
    
    # Copy matching deb files based on enabled tweaks (supports both naming patterns)
    if copy_prebuilt_deb "$ENABLE_YOUPIP" "youpip.deb" "YouPiP" "youpip*.deb" "YouPiP.deb"; then
        ((deb_count++))
    else
        [[ "$ENABLE_YOUPIP" == "true" ]] && missing_debs+=("YouPiP")
    fi
    
    if copy_prebuilt_deb "$ENABLE_YTUHD" "ytuhd.deb" "YTUHD" "ytuhd*.deb" "YTUHD.deb"; then
        ((deb_count++))
    else
        [[ "$ENABLE_YTUHD" == "true" ]] && missing_debs+=("YTUHD")
    fi
    
    if copy_prebuilt_deb "$ENABLE_RYD" "ryd.deb" "Return-YouTube-Dislikes" "ryd*.deb" "Return-YouTube-Dislikes.deb"; then
        ((deb_count++))
    else
        [[ "$ENABLE_RYD" == "true" ]] && missing_debs+=("Return-YouTube-Dislikes")
    fi
    
    if copy_prebuilt_deb "$ENABLE_YOUGROUPSETTINGS" "ygs.deb" "YouGroupSettings" "ygs*.deb" "YouGroupSettings.deb"; then
        ((deb_count++))
    else
        [[ "$ENABLE_YOUGROUPSETTINGS" == "true" ]] && missing_debs+=("YouGroupSettings")
    fi
    
    if copy_prebuilt_deb "$ENABLE_YQ" "yq.deb" "YouQuality" "yq*.deb" "YouQuality.deb"; then
        ((deb_count++))
    else
        [[ "$ENABLE_YQ" == "true" ]] && missing_debs+=("YouQuality")
    fi
    
    if copy_prebuilt_deb "$ENABLE_YTABCONFIG" "yabc.deb" "YTABConfig" "yabc*.deb" "YTABConfig.deb"; then
        ((deb_count++))
    else
        [[ "$ENABLE_YTABCONFIG" == "true" ]] && missing_debs+=("YTABConfig")
    fi
    
    if copy_prebuilt_deb "$ENABLE_YTWEAKS" "ytwks.deb" "YTweaks" "ytwks*.deb" "YTweaks.deb"; then
        ((deb_count++))
    else
        [[ "$ENABLE_YTWEAKS" == "true" ]] && missing_debs+=("YTweaks")
    fi
    
    if copy_prebuilt_deb "$ENABLE_YTICONS" "yticons.deb" "YTIcons" "yticons*.deb" "YTIcons.deb"; then
        ((deb_count++))
    else
        [[ "$ENABLE_YTICONS" == "true" ]] && missing_debs+=("YTIcons")
    fi
    
    if copy_prebuilt_deb "$ENABLE_DEMC" "demc.deb" "DontEatMyContent" "demc*.deb" "DontEatMyContent.deb"; then
        ((deb_count++))
    else
        [[ "$ENABLE_DEMC" == "true" ]] && missing_debs+=("DontEatMyContent")
    fi
    
    if copy_prebuilt_deb "$ENABLE_GONERINO" "gonerino.deb" "Gonerino" "gonerino*.deb" "Gonerino.deb"; then
        ((deb_count++))
    else
        [[ "$ENABLE_GONERINO" == "true" ]] && missing_debs+=("Gonerino")
    fi
    
    if copy_prebuilt_deb "$ENABLE_AUTOFLEX" "autoflex.deb" "AutoFLEX" "autoflex*.deb" "AutoFLEX.deb"; then
        ((deb_count++))
    else
        [[ "$ENABLE_AUTOFLEX" == "true" ]] && missing_debs+=("AutoFLEX")
    fi
    
    # YTVideoOverlay is required if YouPiP or YouQuality is enabled
    if [[ "$ENABLE_YQ" == "true" ]] || [[ "$ENABLE_YOUPIP" == "true" ]]; then
        if copy_prebuilt_deb "true" "ytvo.deb" "YTVideoOverlay" "ytvo*.deb" "YTVideoOverlay.deb"; then
            ((deb_count++))
        else
            missing_debs+=("YTVideoOverlay")
        fi
    fi
    
    cd "$BUILD_DIR"
    
    if [[ $deb_count -gt 0 ]]; then
        print_success "Copied $deb_count pre-built .deb file(s) from deb/ folder"
    fi
    
    if [[ ${#missing_debs[@]} -gt 0 ]]; then
        print_warning "Missing pre-built .deb files for: ${missing_debs[*]}"
        print_info "Will build missing tweaks"
    fi
}

# Helper function to build a single tweak
# Usage: build_tweak <enable_flag> <name> <deb_name>
build_tweak() {
    local enable_flag="$1"
    local name="$2"
    local deb_name="$3"
    
    if [[ "$enable_flag" != "true" ]]; then
        return
    fi
    
    if [[ "$USE_PREBUILT_DEBS" == "true" ]] && [[ -f "$BUILD_DIR/$deb_name" ]]; then
        print_info "Skipping $name build (using pre-built)"
        return
    fi
    
    print_info "Building $name..."
    cd "$name"
    make clean package DEBUG=0 FINALPACKAGE=1
    mv packages/*.deb "$BUILD_DIR/$deb_name"
    cd ..
}

# Build tweaks
build_tweaks() {
    if ! any_tweaks_enabled; then
        return
    fi
    
    # Check if we should use pre-built debs
    if [[ "$USE_PREBUILT_DEBS" == "true" ]]; then
        copy_prebuilt_debs
    fi
    
    print_info "Building tweaks..."
    
    cd "$BUILD_DIR"
    export THEOS="$THEOS"
    
    build_tweak "$ENABLE_YOUPIP" "YouPiP" "youpip.deb"
    build_tweak "$ENABLE_YTUHD" "YTUHD" "ytuhd.deb"
    build_tweak "$ENABLE_RYD" "Return-YouTube-Dislikes" "ryd.deb"
    build_tweak "$ENABLE_YOUGROUPSETTINGS" "YouGroupSettings" "ygs.deb"
    build_tweak "$ENABLE_YQ" "YouQuality" "yq.deb"
    build_tweak "$ENABLE_YTABCONFIG" "YTABConfig" "yabc.deb"
    build_tweak "$ENABLE_YTWEAKS" "YTweaks" "ytwks.deb"
    build_tweak "$ENABLE_YTICONS" "YTIcons" "yticons.deb"
    build_tweak "$ENABLE_DEMC" "DontEatMyContent" "demc.deb"
    build_tweak "$ENABLE_GONERINO" "Gonerino" "gonerino.deb"
    
    if [[ "$ENABLE_AUTOFLEX" == "true" ]]; then
        if [[ "$USE_PREBUILT_DEBS" == "true" ]] && [[ -f "$BUILD_DIR/autoflex.deb" ]]; then
            print_info "Skipping AutoFLEX build (using pre-built)"
        else
            print_info "Building AutoFLEX..."
            cd AutoFLEX
            chmod +x build.sh
            ./build.sh
            mv packages/*.deb "$BUILD_DIR/autoflex.deb"
            cd ..
        fi
    fi
    
    # YTVideoOverlay is required if YouPiP or YouQuality is enabled
    if [[ "$ENABLE_YQ" == "true" ]] || [[ "$ENABLE_YOUPIP" == "true" ]]; then
        build_tweak "true" "YTVideoOverlay" "ytvo.deb"
    fi
    
    print_success "All tweaks built"
}

# Inject tweaks into IPA
inject_tweaks() {
    print_info "Injecting tweaks into IPA..."
    
    cd "$BUILD_DIR"
    
    # Start with required tweaks
    tweaks="ytplus.deb OpenYoutubeSafariExtension.appex"
    
    # Add all .deb files from workspace
    for f in *.deb; do
        if [[ -f "$f" ]]; then
            tweaks="$tweaks $f"
        fi
    done
    
    # Also check deb/ folder for any unrecognized debs (always check)
    # These are debs that don't match our known patterns
    if [[ -d "$ROOT_DIR/deb" ]]; then
        for f in "$ROOT_DIR/deb"/*.deb; do
            if [[ -f "$f" ]]; then
                local deb_name=$(basename "$f")
                local lower_name=$(echo "$deb_name" | tr '[:upper:]' '[:lower:]')
                
                # Check if this matches any known pattern
                local is_recognized=false
                # Check if name starts with known prefixes or matches exact names
                if [[ "$lower_name" =~ ^youpip ]] || [[ "$deb_name" == "YouPiP.deb" ]] || \
                   [[ "$lower_name" =~ ^ytuhd ]] || [[ "$deb_name" == "YTUHD.deb" ]] || \
                   [[ "$lower_name" =~ ^ryd ]] || [[ "$deb_name" == "Return-YouTube-Dislikes.deb" ]] || \
                   [[ "$lower_name" =~ ^ygs ]] || [[ "$deb_name" == "YouGroupSettings.deb" ]] || \
                   [[ "$lower_name" =~ ^yq\. ]] || [[ "$deb_name" == "YouQuality.deb" ]] || \
                   [[ "$lower_name" =~ ^yabc ]] || [[ "$deb_name" == "YTABConfig.deb" ]] || \
                   [[ "$lower_name" =~ ^ytwks ]] || [[ "$deb_name" == "YTweaks.deb" ]] || \
                   [[ "$lower_name" =~ ^yticons ]] || [[ "$deb_name" == "YTIcons.deb" ]] || \
                   [[ "$lower_name" =~ ^demc ]] || [[ "$deb_name" == "DontEatMyContent.deb" ]] || \
                   [[ "$lower_name" =~ ^gonerino ]] || [[ "$deb_name" == "Gonerino.deb" ]] || \
                   [[ "$lower_name" =~ ^autoflex ]] || [[ "$deb_name" == "AutoFLEX.deb" ]] || \
                   [[ "$lower_name" =~ ^ytvo ]] || [[ "$deb_name" == "YTVideoOverlay.deb" ]]; then
                    is_recognized=true
                fi
                
                # Only include unrecognized debs (recognized ones should already be in build dir)
                if [[ "$is_recognized" == "false" ]]; then
                    tweaks="$tweaks $f"
                    print_info "Including unrecognized .deb from deb/ folder: $deb_name"
                fi
            fi
        done
    fi
    
    # Workflow-style output name: YTPlusYTweaks_<tweak>_SDK<version>_v<app>.ipa
    # If file exists, use _1, _2, _3 ... before .ipa
    base_name="YTPlusYTweaks_${TWEAK_VERSION}_SDK${SDK_VERSION}_v${APP_VERSION}"
    output_ipa="${base_name}.ipa"
    counter=1
    while [[ -f "$ROOT_DIR/$output_ipa" ]]; do
        output_ipa="${base_name}_${counter}.ipa"
        ((counter++))
    done
    
    print_info "Running cyan to inject tweaks..."
    cyan -i youtube.ipa -o "$output_ipa" -uwef $tweaks -n "$DISPLAY_NAME" -b "$BUNDLE_ID"
    
    if [[ ! -f "$output_ipa" ]]; then
        print_error "Failed to create output IPA"
        exit 1
    fi
    
    # Move final IPA to root directory
    mv "$BUILD_DIR/$output_ipa" "$ROOT_DIR/$output_ipa"
    
    print_success "IPA created: $output_ipa"
    print_info "Output location: $ROOT_DIR/$output_ipa"
}

# Cleanup build directory
cleanup_build() {
    print_info "Cleaning up build directory..."
    cd "$ROOT_DIR"
    rm -rf "$BUILD_DIR"
    print_success "Build directory cleaned up"
}

# Main function
main() {
    print_info "Starting YTPlusYTweaks build process..."
    print_info "SDK version: $SDK_VERSION"
    print_info "Tweak version: $TWEAK_VERSION"
    print_info "Display name: $DISPLAY_NAME"
    print_info "Bundle ID: $BUNDLE_ID"
    print_info "Root directory: $ROOT_DIR"
    print_info "Build directory: $BUILD_DIR"
    
    # Show enabled tweaks
    print_info "Enabled tweaks:"
    [[ "$ENABLE_YOUPIP" == "true" ]] && echo "  - YouPiP"
    [[ "$ENABLE_YTUHD" == "true" ]] && echo "  - YTUHD"
    [[ "$ENABLE_YQ" == "true" ]] && echo "  - YouQuality"
    [[ "$ENABLE_RYD" == "true" ]] && echo "  - Return YouTube Dislikes"
    [[ "$ENABLE_DEMC" == "true" ]] && echo "  - DontEatMyContent"
    [[ "$ENABLE_YTABCONFIG" == "true" ]] && echo "  - YTABConfig"
    [[ "$ENABLE_YTWEAKS" == "true" ]] && echo "  - YTweaks"
    [[ "$ENABLE_YTICONS" == "true" ]] && echo "  - YTIcons"
    [[ "$ENABLE_YOUGROUPSETTINGS" == "true" ]] && echo "  - YouGroupSettings"
    [[ "$ENABLE_GONERINO" == "true" ]] && echo "  - Gonerino"
    [[ "$ENABLE_AUTOFLEX" == "true" ]] && echo "  - AutoFLEX"
    
    setup_workspace
    setup_ipa
    get_app_version
    get_latest_version
    if any_tweaks_enabled; then
        ensure_sdk
    fi
    download_ytplus
    clone_safari_extension
    clone_youtube_header
    clone_ps_header
    
    # Check for pre-built debs early if flag is set (before cloning/building)
    if [[ "$USE_PREBUILT_DEBS" == "true" ]]; then
        copy_prebuilt_debs
    fi
    
    clone_tweaks
    build_tweaks
    inject_tweaks
    cleanup_build
    
    print_success "Build complete!"
}

parse_args "$@"
main