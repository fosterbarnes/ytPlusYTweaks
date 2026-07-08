#!/bin/bash
set -e

YTPLUS_VERSION=""; YTPLUS_VERSION_PROVIDED=false
YTPLUS_DEFAULT_VERSION="5.2.1"
DISPLAY_NAME="YouTube"; DISPLAY_NAME_PROVIDED=false
BUNDLE_ID="com.google.ios.youtube"; BUNDLE_ID_PROVIDED=false
IPA_SOURCE=""
ROOT_DIR="$(pwd)"
BUILD_DIR="$(pwd)/build"
MY_DEBS=false
TEST_MODE=false
THEOS_COMMIT="3913415ce82614e66bdbcf0e2538288dd94f5011"
SDK_VERSION="16.5"
APP_VERSION=""

TWEAKS=(
    "YTVideoOverlay|ytvo.deb|https://github.com/PoomSmart/YTVideoOverlay.git||"
    "YouPiP|youpip.deb|https://github.com/PoomSmart/YouPiP.git||"
    "YTUHD|ytuhd.deb|https://github.com/PoomSmart/YTUHD.git|--recurse-submodules --shallow-submodules|SIDELOAD=1"
    "YouQuality|yq.deb|https://github.com/PoomSmart/YouQuality.git||"
    "Return-YouTube-Dislikes|ryd.deb|https://github.com/PoomSmart/Return-YouTube-Dislikes.git||"
    "DontEatMyContent|demc.deb|https://github.com/therealFoxster/DontEatMyContent.git|--recurse-submodules|"
    "YTABConfig|yabc.deb|https://github.com/PoomSmart/YTABConfig.git||"
    "YTweaks|ytwks.deb|https://github.com/fosterbarnes/YTweaks.git||"
    "Gonerino|gonerino.deb|https://github.com/fosterbarnes/YGonerino.git||"
    "YouGroupSettings|ygs.deb|https://github.com/fosterbarnes/YouGroupSettings.git||"
    "YouMute|youmute.deb|https://github.com/PoomSmart/YouMute.git||"
    "YouLoop|youloop.deb|https://github.com/bhackel/YouLoop.git||"
    "YouSpeed|youspeed.deb|https://github.com/PoomSmart/YouSpeed.git||"
    "YouGetCaption|yougetcaption.deb|https://github.com/PoomSmart/YouGetCaption.git||"
)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
ok() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
    cat << EOF
YTPlusYTweaks Build Script

Usage: $0 [options]

Default (no flags): builds using the IPA in the ipa/ directory, integrating all default integrated tweaks.
By default, all tweaks are cloned and built from source. Use '--myDebs' to use your local files in the deb/ directory.

Options:
    -ipa <URL>                          Download IPA from URL to ipa/ before building
    -myDebs, -md                        Use existing .deb files in deb/ 
    -sdk <version>                      iOS SDK version: 16.5, 17.5, or 18.6 (default: 16.5)
    -ytPlusVersion, -ytpv <version>     Version of YTPlus tweak (default: auto-detect latest)
    -displayName, -dn <name>            App display name (default: YouTube)
    -bundleID, -bid <id>                Bundle ID (default: com.google.ios.youtube)
    -test                               Quickly change display name and bundle ID when testing
                                        Display Name: YTest | Bundle ID: com.google.ios.youtube2
    -help, -h                           Show this help message

Examples:
    $0
    $0 --ipa https://example.com/youtube.ipa
    $0 --myDebs
    $0 --sdk 17.5 --displayName "YT"

EOF
}

parseArgs() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --ipa)
                if [[ $# -gt 1 && "$2" != --* && "$2" =~ ^https?:// ]]; then IPA_SOURCE="$2"; shift 2
                else IPA_SOURCE=""; shift; fi
                ;;
            --myDebs|--md|-myDebs|-md) MY_DEBS=true; shift ;;
            --test|--t|-test|-t) TEST_MODE=true; shift ;;
            --sdk|-sdk)
                SDK_VERSION="$2"
                case "$SDK_VERSION" in
                    16.5|17.5|18.6) ;;
                    *) err "Unsupported SDK version: $SDK_VERSION (use 16.5, 17.5, or 18.6)"; usage; exit 1 ;;
                esac
                shift 2
                ;;
            --ytPlusVersion|--ytpv|-ytPlusVersion|-ytpv) YTPLUS_VERSION="$2"; YTPLUS_VERSION_PROVIDED=true; shift 2 ;;
            --displayName|--dn|-displayName|-dn) DISPLAY_NAME="$2"; DISPLAY_NAME_PROVIDED=true; shift 2 ;;
            --bundleID|--bid|-bundleID|-bid) BUNDLE_ID="$2"; BUNDLE_ID_PROVIDED=true; shift 2 ;;
            --help|--h|-help|-h) usage; exit 0 ;;
            *) err "Unknown option: $1"; usage; exit 1 ;;
        esac
    done

    if [[ "$TEST_MODE" == "true" ]]; then
        [[ "$DISPLAY_NAME_PROVIDED" != "true" ]] && DISPLAY_NAME="YTest"
        [[ "$BUNDLE_ID_PROVIDED" != "true" ]] && BUNDLE_ID="com.google.ios.youtube2"
    fi
}

# xcrun must resolve the iphoneos SDK for YTUHD's libvpx/dav1d builds
ensureXcode() {
    xcrun --sdk iphoneos --show-sdk-path &>/dev/null && return

    local xcodeDev="/Applications/Xcode.app/Contents/Developer"
    if [[ -d "$xcodeDev" ]]; then
        export DEVELOPER_DIR="$xcodeDev"
        if xcrun --sdk iphoneos --show-sdk-path &>/dev/null; then
            warn "xcode-select points to Command Line Tools; using Xcode at $xcodeDev"
            info "Run 'sudo xcode-select -s $xcodeDev' to fix this permanently"
            return
        fi
    fi

    err "Cannot locate iphoneos SDK (xcrun --sdk iphoneos failed)."
    err "Install Xcode from the App Store, then run:"
    err "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    exit 1
}

ensureBuildTools() {
    command -v meson &>/dev/null && return
    if command -v brew &>/dev/null; then
        info "Installing meson (required for YTUHD)..."
        brew install meson
        return
    fi
    err "meson is required to build YTUHD but was not found."
    err "Install it with: brew install meson"
    exit 1
}

ensureTheos() {
    if [[ -z "${THEOS:-}" ]]; then
        THEOS="$HOME/theos"; export THEOS
        info "THEOS not set; using $THEOS"
    fi
    [[ -d "$THEOS" ]] || { err "THEOS directory not found: $THEOS. Run build_dependencies.sh first."; exit 1; }
}

ensureSdk() {
    ensureTheos
    mkdir -p "$THEOS/sdks"
    local sdkDir="$THEOS/sdks/iPhoneOS${SDK_VERSION}.sdk"
    [[ -d "$sdkDir" ]] && { info "iOS SDK $SDK_VERSION already present at $sdkDir"; return; }

    info "Downloading iOS $SDK_VERSION SDK..."
    local tmpSdk=$(mktemp -d)
    (
        cd "$tmpSdk"
        case "$SDK_VERSION" in
            16.5)
                git clone --quiet -n --depth=1 --filter=tree:0 https://github.com/theos/sdks/
                cd sdks
                git sparse-checkout set --no-cone iPhoneOS16.5.sdk
                git checkout
                mv *.sdk "$THEOS/sdks/"
                ;;
            17.5|18.6)
                git clone --quiet --no-tags --single-branch --depth=1 -n --filter=tree:0 https://github.com/Tonwalter888/iOS-SDKs
                cd iOS-SDKs
                git sparse-checkout set --no-cone "iPhoneOS${SDK_VERSION}.sdk"
                git checkout
                mv *.sdk "$THEOS/sdks/"
                ;;
            *) err "Unsupported SDK version: $SDK_VERSION"; exit 1 ;;
        esac
    )
    rm -rf "$tmpSdk"
    [[ -d "$sdkDir" ]] || { err "Failed to install iOS SDK $SDK_VERSION"; exit 1; }
    ok "iOS SDK $SDK_VERSION installed"
}

getAppVersion() {
    info "Extracting app version from IPA..."
    local infoPlist
    infoPlist=$(unzip -l "$BUILD_DIR/youtube.ipa" | grep -o "Payload/[^/]*\.app/Info\.plist" | head -n 1)
    [[ -n "$infoPlist" ]] || { err "Could not find Info.plist in IPA"; exit 1; }

    local extractDir="$BUILD_DIR/ipa_extract"
    mkdir -p "$extractDir"
    unzip -p "$BUILD_DIR/youtube.ipa" "$infoPlist" > "$extractDir/Info.plist"
    APP_VERSION=$(plutil -p "$extractDir/Info.plist" 2>/dev/null | grep "CFBundleShortVersionString" | sed -E 's/.*"CFBundleShortVersionString"[[:space:]]*=>[[:space:]]*"([^"]+)".*/\1/')
    [[ -n "$APP_VERSION" ]] || { err "Could not extract app version from Info.plist"; exit 1; }
    ok "App version: $APP_VERSION"
}

setupWorkspace() { info "Setting up workspace..."; mkdir -p "$BUILD_DIR"; cd "$BUILD_DIR"; }

setupIpa() {
    mkdir -p "$ROOT_DIR/ipa"

    if [[ -n "$IPA_SOURCE" ]]; then
        info "Downloading IPA from: $IPA_SOURCE"
        wget "$IPA_SOURCE" --no-verbose -O "$BUILD_DIR/youtube.ipa"
        [[ -f "$BUILD_DIR/youtube.ipa" ]] || { err "Failed to download IPA file"; exit 1; }
        cp "$BUILD_DIR/youtube.ipa" "$ROOT_DIR/ipa/youtube.ipa"
        info "Saved IPA to ipa/ folder for future use"
    else
        info "Looking for IPA in ipa/ folder..."
        local ipaFiles=("$ROOT_DIR/ipa"/*.ipa)
        if [[ -f "${ipaFiles[0]}" ]]; then
            info "Found IPA: $(basename "${ipaFiles[0]}")"
            cp "${ipaFiles[0]}" "$BUILD_DIR/youtube.ipa"
            ok "Using local IPA: $(basename "${ipaFiles[0]}")"
        else
            err "No IPA files found in ipa/ folder"
            info "Please place a .ipa file in the ipa/ directory, or use --ipa <URL> to download one"
            exit 1
        fi
    fi

    [[ -f "$BUILD_DIR/youtube.ipa" ]] || { err "IPA file not found"; exit 1; }

    local fileType=$(file --mime-type -b "$BUILD_DIR/youtube.ipa")
    if [[ "$fileType" != "application/x-ios-app" && "$fileType" != "application/zip" ]]; then
        err "Validation failed: The file is not a valid IPA. Detected type: $fileType"
        exit 1
    fi
    ok "IPA ready: $(basename "$BUILD_DIR/youtube.ipa")"
}

getLatestVersion() {
    if [[ "$YTPLUS_VERSION_PROVIDED" == "true" ]]; then info "Using provided version: $YTPLUS_VERSION"; return; fi
    YTPLUS_VERSION="$YTPLUS_DEFAULT_VERSION"
    ok "YTPlus version: $YTPLUS_VERSION"
}

downloadYtplus() {
    if [[ "$YTPLUS_VERSION_PROVIDED" == "true" ]]; then
        info "Downloading YouTube Plus ${YTPLUS_VERSION} from YTLite releases..."
        local debUrl="https://github.com/dayanch96/YTLite/releases/download/v${YTPLUS_VERSION}/com.dvntm.ytlite_${YTPLUS_VERSION}_iphoneos-arm.deb"
        wget "$debUrl" --no-verbose -O "$BUILD_DIR/ytplus.deb"
        [[ -f "$BUILD_DIR/ytplus.deb" ]] || { err "Failed to download YouTube Plus .deb"; exit 1; }
        mkdir -p "$ROOT_DIR/deb"
        cp "$BUILD_DIR/ytplus.deb" "$ROOT_DIR/deb/YTPlus.deb"
        ok "YouTube Plus downloaded"
        return
    fi

    info "Downloading YouTube Plus from repo..."
    wget "https://raw.githubusercontent.com/fosterbarnes/ytPlusYTweaks/main/Resources/deb/com.dvntm.ytlite_${YTPLUS_DEFAULT_VERSION}_iphoneos-arm.deb" \
        --no-verbose -O "$BUILD_DIR/ytplus.deb"
    [[ -f "$BUILD_DIR/ytplus.deb" ]] || { err "Failed to download YouTube Plus .deb"; exit 1; }
    mkdir -p "$ROOT_DIR/deb"
    cp "$BUILD_DIR/ytplus.deb" "$ROOT_DIR/deb/YTPlus.deb"
    ok "YouTube Plus downloaded (saved to deb/YTPlus.deb)"
}

cloneSafariExt() {
    info "Cloning Open in YouTube Safari extension..."
    [[ -e "$BUILD_DIR/OpenYoutubeSafariExtension.appex" ]] && { info "Safari extension already exists"; return; }

    local tmpExt=$(mktemp -d)
    cd "$tmpExt"
    git clone --quiet -n --depth=1 --filter=tree:0 https://github.com/CokePokes/YoutubeExtensions/
    cd YoutubeExtensions
    git sparse-checkout set --no-cone OpenYoutubeSafariExtension.appex
    git checkout --quiet

    shopt -s nullglob
    local appexFiles=(*.appex)
    shopt -u nullglob

    if [[ ${#appexFiles[@]} -gt 0 ]]; then
        mv "${appexFiles[0]}" "$BUILD_DIR/OpenYoutubeSafariExtension.appex"
        ok "Safari extension cloned"
    else
        local appexFile=$(find . -name "*.appex" -type f 2>/dev/null | head -n 1)
        if [[ -n "$appexFile" && -f "$appexFile" ]]; then
            mv "$appexFile" "$BUILD_DIR/OpenYoutubeSafariExtension.appex"
            ok "Safari extension cloned (from subdirectory)"
        else
            err "Failed to clone Safari extension - .appex file not found"
            info "Directory contents after checkout:"; ls -la
            info "Searching for .appex files:"; find . -type f -name "*.appex" 2>/dev/null || echo "No .appex files found"
            cd "$BUILD_DIR"; rm -rf "$tmpExt"
            exit 1
        fi
    fi

    cd "$BUILD_DIR"; rm -rf "$tmpExt"
}

# YouTubeHeader is needed by all tweaks; DontEatMyContent needs a YTHeaders copy of it
cloneYtHeader() {
    info "Cloning YouTubeHeader..."
    if [[ -d "$THEOS/include/YouTubeHeader" ]]; then
        info "YouTubeHeader exists. Pulling latest changes..."
        cd "$THEOS/include/YouTubeHeader"; git pull --quiet; cd "$BUILD_DIR"
    else
        info "YouTubeHeader does not exist. Cloning repository..."
        mkdir -p "$THEOS/include"; cd "$THEOS/include"
        git clone --quiet --depth=1 https://github.com/PoomSmart/YouTubeHeader.git
        cd "$BUILD_DIR"
    fi

    info "Copying YouTubeHeader to YTHeaders for DontEatMyContent..."
    rm -rf "$THEOS/include/YTHeaders"
    cp -r "$THEOS/include/YouTubeHeader" "$THEOS/include/YTHeaders"
    ok "YouTubeHeader setup complete"
}

clonePsHeader() {
    info "Cloning PSHeader..."
    if [[ -d "$THEOS/include/PSHeader" ]]; then
        info "PSHeader exists. Pulling latest changes..."
        cd "$THEOS/include/PSHeader"; git pull --quiet; cd "$BUILD_DIR"
    else
        info "PSHeader does not exist. Cloning repository..."
        mkdir -p "$THEOS/include"; cd "$THEOS/include"
        git clone --quiet --depth=1 https://github.com/PoomSmart/PSHeader.git
        cd "$BUILD_DIR"
    fi
    ok "PSHeader setup complete"
}

findPrebuiltDeb() {
    local name="$1" debName="$2"
    local prefix="${debName%.deb}"
    shopt -s nocaseglob nullglob
    local matches=("$ROOT_DIR/deb/${prefix}"*.deb "$ROOT_DIR/deb/${name}"*.deb)
    shopt -u nocaseglob nullglob
    [[ ${#matches[@]} -gt 0 ]] && { echo "${matches[0]}"; return 0; }
    return 1
}

processTweak() {
    local spec="$1"
    IFS='|' read -r name debName repo extraFlags makeExtra <<< "$spec"

    local prebuilt
    if prebuilt=$(findPrebuiltDeb "$name" "$debName"); then
        cp "$prebuilt" "$BUILD_DIR/$debName"
        info "Using pre-built $name .deb ($(basename "$prebuilt"))"
        # YouPiP/YouQuality #import a header from this repo via a relative
        # path, so its source must exist even when using a pre-built deb.
        if [[ "$name" == "YTVideoOverlay" && ! -d "$name" ]]; then
            info "Cloning YTVideoOverlay source anyway (needed as a header dependency)..."
            git clone --quiet --depth=1 "$repo" "$name"
        fi
        return
    fi

    info "No pre-built .deb found for $name, building from source..."
    if [[ ! -d "$name" ]]; then
        info "Cloning $name..."
        if [[ -n "$extraFlags" ]]; then git clone --quiet --depth=1 $extraFlags "$repo" "$name"
        else git clone --quiet --depth=1 "$repo" "$name"; fi
    fi

    info "Building $name..."
    cd "$name"
    [[ "$name" == "YTUHD" ]] && make libvpx dav1d $makeExtra
    make clean package DEBUG=0 FINALPACKAGE=1 $makeExtra
    mv packages/*.deb "$BUILD_DIR/$debName"
    cd ..

    mkdir -p "$ROOT_DIR/deb"
    cp "$BUILD_DIR/$debName" "$ROOT_DIR/deb/${name}.deb"
    ok "$name built (saved to deb/${name}.deb)"
}

buildTweaks() {
    cd "$BUILD_DIR"
    for spec in "${TWEAKS[@]}"; do processTweak "$spec"; done
    ok "All tweaks ready"
}

injectTweaks() {
    info "Injecting tweaks into IPA..."
    cd "$BUILD_DIR"
    local tweaks=""

    if [[ "$MY_DEBS" == "true" ]]; then
        tweaks="OpenYoutubeSafariExtension.appex"
        for f in "$ROOT_DIR/deb"/*.deb; do [[ -f "$f" ]] && tweaks="$tweaks $f"; done
    else
        tweaks="ytplus.deb OpenYoutubeSafariExtension.appex"
        for f in *.deb; do [[ -f "$f" ]] && tweaks="$tweaks $f"; done

        if [[ -d "$ROOT_DIR/deb" ]]; then
            for f in "$ROOT_DIR/deb"/*.deb; do
                [[ -f "$f" ]] || continue
                local debBasename=$(basename "$f")
                local alreadyUsed=false
                shopt -s nocasematch
                [[ "$debBasename" == ytplus*.deb ]] && alreadyUsed=true
                for spec in "${TWEAKS[@]}"; do
                    IFS='|' read -r name debName _ _ _ <<< "$spec"
                    local prefix="${debName%.deb}"
                    [[ "$debBasename" == ${prefix}*.deb || "$debBasename" == ${name}*.deb ]] && alreadyUsed=true
                done
                shopt -u nocasematch
                if [[ "$alreadyUsed" == "false" ]]; then
                    tweaks="$tweaks $f"
                    info "Including extra .deb from deb/ folder: $debBasename"
                fi
            done
        fi
    fi

    local baseName
    if [[ "$TEST_MODE" == "true" ]]; then baseName="YTest"
    else baseName="YTPlusYTweaks_${YTPLUS_VERSION}_SDK${SDK_VERSION}_v${APP_VERSION}"; fi

    local outputIpa="${baseName}.ipa" counter=1
    while [[ -f "$ROOT_DIR/$outputIpa" ]]; do outputIpa="${baseName}_${counter}.ipa"; ((counter++)); done

    info "Running cyan to inject tweaks..."
    cyan -i youtube.ipa -o "$outputIpa" -uwef $tweaks -n "$DISPLAY_NAME" -b "$BUNDLE_ID"
    [[ -f "$outputIpa" ]] || { err "Failed to create output IPA"; exit 1; }

    mv "$BUILD_DIR/$outputIpa" "$ROOT_DIR/$outputIpa"
    ok "IPA created: $outputIpa"
    info "Output location: $ROOT_DIR/$outputIpa"
}

cleanupBuild() { info "Cleaning up build directory..."; cd "$ROOT_DIR"; rm -rf "$BUILD_DIR"; ok "Build directory cleaned up"; }

main() {
    info "Starting YTPlusYTweaks build process..."
    info "Display name: $DISPLAY_NAME"
    info "Bundle ID: $BUNDLE_ID"
    info "Root directory: $ROOT_DIR"
    info "Build directory: $BUILD_DIR"

    if [[ "$MY_DEBS" == "true" ]]; then
        info "Mode: --myDebs (using every .deb in deb/, no downloads or builds)"
        mkdir -p "$ROOT_DIR/deb"
        setupWorkspace; setupIpa; getAppVersion; getLatestVersion
        cloneSafariExt; injectTweaks; cleanupBuild
        ok "Build complete!"
        return
    fi

    info "SDK version: $SDK_VERSION"
    info "YTPlus version: $YTPLUS_VERSION"
    info "Default tweaks: YouPiP, YTUHD, YouQuality, Return YouTube Dislikes,"
    info "                DontEatMyContent, YTABConfig, YTweaks, Gonerino, YouGroupSettings"

    setupWorkspace; setupIpa; getAppVersion; getLatestVersion
    ensureXcode; ensureBuildTools; ensureSdk
    downloadYtplus; cloneSafariExt; cloneYtHeader; clonePsHeader
    buildTweaks; injectTweaks; cleanupBuild
    ok "Build complete!"
}

parseArgs "$@"
main