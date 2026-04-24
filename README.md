# YouTube Plus (With more tweaks!)
[YouTube Plus](https://github.com/dayanch96/YTLite) with added plugins.

v20.10.4 is ***strongly*** recommended for proper compatibility

[NOTE] Some users are reporting a prompt to update, blocking app usage on 20.10.4. This is a known issue and is being looked into

This repo focuses on simplifying the build process of YouTube Plus, and adding more optional tweaks to bundle with it (specifically [YTweaks](https://github.com/fosterbarnes/YTweaks)). No changes have been made to the YouTube Plus .deb itself, just the tweaks that get packaged with it. 

When building the app, the latest stable YouTube Plus .deb is downloaded from the original repo, then other tweaks are built from source. All tweaks are then injected into your IPA.

YTweaks added settings:
- **Fullscreen to the right or left:** Locks fullscreen orientation.
- **Night Mode**: Lowers brightness below device minimum by "faking it" with an app-wide semi-transparent black overlay. Works best on OLED devices.
- **Disable floating miniplayer:** Restores the old miniplayer by disabling the floating miniplayer.
- **Virtual fullscreen bezels:** Adds invisible touch-safe zones on black bars to prevent accidental taps and skips.
- **Fix Casting** - Attempts to fix casting by changing some A/B flags. Only works on v20.10.4 or lower

Experimental planned features
- **Hide AI Summaries:** Hides AI summaries that appear in the feed.


Added tweaks:
- [YTweaks](https://github.com/fosterbarnes/YTweaks)
- [YTABConfig](https://github.com/PoomSmart/YTABConfig)
- [YTIcons](https://github.com/PoomSmart/YTIcons)
- [YouGroupSettings](https://github.com/fosterbarnes/YouGroupSettings)
- [Gonerino](https://github.com/castdrian/Gonerino)

Original repo: https://github.com/dayanch96/YTLite

## How to build a YTPlusYTweaks app
If you just need to build the YouTube app without much fuss, use GitHub actions. Actions are easy to set up, but slow to run.

If you plan on testing, adding tweaks that aren't integrated with this repo, making changes, or building very frequently, build locally. Building locally on your computer takes a bit of setup initially, but is much quicker than actions after setup.

### GitHub Actions
> [!NOTE]
> If this your first time, complete following steps before starting:
>
> 1. Fork this repository using the fork button on the top right
> 2. On your forked repository, go to **Repository Settings** > **Actions**, enable **Read and Write** permissions.

<details>
  <summary>How to build YTPlusYTweaks app</summary>
  <ol>
    <li>Fork this repo if you haven't already. Sync if your branch is out of date.</li>
    <li>Go to the "Actions" tab of your new repo.</li>
    <li>Select "Build YTPlusYTweaks".</li>
    <li>Click "Run workflow".</li>
    <li>Select bundled tweaks.</li>
    <li>
        Prepare & upload base .ipa<br>
        
- Prepare a decrypted .ipa file (version 20.10.4 or earlier for Fix Casting to work). <br>
<em>We cannot provide this file due to legal reasons.</em><br>

- Upload the decrypted IPA to a file hosting service (e.g., litterbox.catbox.moe or Dropbox).<br>
<em>If you use Dropbox, change the end of the URL from <code>dl=0</code> to <code>dl=1</code>.</em><br>

- Paste the direct download link to the decrypted IPA into the provided field.<br>
<em><strong>NOTE:</strong> Make sure to provide a direct download link to the file, not a webpage. Otherwise, the process will fail.</em><br>
    </li>
        
<li>Click "Run workflow".</li>
    <td><img src="Resources/scr15.jpg" alt="Screenshot 15" /></td>
    <li>Wait for the build to finish. You can download the YouTube Plus app from the releases section of your forked repo. (If you can't find the releases section, go to your forked repo and add /releases to the URL, i.e., github.com/user/YTPlusYTweaks/releases.)</li><br>
    

<strong>Additional workflow options:</strong><br>
- The version of YTLite to use:<br>
  <em>Input a release tag from [dayanch96/YTLite/tags](https://github.com/dayanch96/YTLite/tags)</em><br>
  Example: `5.2b3` or `v5.2b4`<br>
- iOS SDK Version:<br>
  <em>16.5 should be used for older devices, 18.6 can be used for newer devices</em><br>
  Example: `16.5`<br>
- Inject pre-built DEB(s):<br>
  <em>User-provided DEBs can be downloaded and injected alongside other tweaks. Either provide comma-separated direct download links to .deb files OR a direct download link to zipped .deb files</em><br>
  .deb example: `https://litter.catbox.moe/1.deb, https://litter.catbox.moe/2.deb`<br>
  .zip example: `https://litter.catbox.moe/debs.zip`<br>
- App Name:<br>
  <em>Display name for the app on the homescreen</em><br>
  Example: `YTPlusYTweaks`<br>
- BundleID:<br>
  <em>Unique identifier assigned to every application. Change if you want to have multiple installs of YouTube</em><br>
  Example: `com.google.ios.youtube2`<br>


  </ol>
</details>

<details>
  <summary>How to build .debs</summary>
  <ol>
    <li>Fork this repo if you haven't already. Sync if your branch is out of date.</li>
    <li>Go to the "Actions" tab of your new repo.</li>
    <li>Select "Build .deb packages".</li>
    <li>Click "Run workflow".</li>
    <li>Select tweaks.</li>
    <li>Click "Run workflow".</li>
    <td><img src="Resources/scr10.jpg" alt="Screenshot 10" /></td>
    <li>Wait for the build to finish. You can download the YouTube Plus app from the releases section of your forked repo. (If you can't find the releases section, go to your forked repo and add /releases to the URL, i.e., github.com/user/YTPlusYTweaks/releases.)</li>
  </ol>
</details>

### Local (Tested on macOS 15 Sequoia)
<details>
  <summary>How to build locally on your machine</summary>

1. Install brew and git if not already present, then clone this repo to download the required build scripts:

```bash
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew already installed."
fi

brew install git
cd "$HOME/Desktop"
git clone --filter=blob:none --no-checkout https://github.com/fosterbarnes/YTPlusYTweaks
cd YTPlusYTweaks || exit
git sparse-checkout init --no-cone
git sparse-checkout set \
    'deb/*' \
    'ipa/*' \
    'build.sh' \
    'build_dependencies.sh' \
    'README.md'
git checkout main
```
2. Run the build dependencies script

```bash
./build_dependencies.sh
```
3. Run the build script to build your app

Build with a URL to a decrypted IPA
```bash
./build.sh --ipa URL_HERE
```

Build with the IPA in 'YTPlusYTweaks/ipa'
```bash
./build.sh --ipa
```

Build with any pre-built DEBs in 'YTPlusYTweaks/deb'
```bash
./build.sh --ipa --deb
```
To list all options:
```bash
./build.sh -h
```
```bash
YTPlusYTweaks Build Script

Usage: $0 --ipa [URL] [options]

IPAs Source:
    --ipa [URL]                  If URL provided: download IPA from URL (saves to ipa/)
                                  If no URL: use local IPA from ipa/ folder (looks for *.ipa files)

Optional Arguments:
    --deb                        Use pre-built .deb files from deb/ folder. Otherwise, build from source.
    --tweak-version <version>    Version of YTLite tweak (default: 5.2b4)
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

Other Options:
    -h, --help                   Show this help message

Examples:
    $0 --ipa https://example.com/youtube.ipa
    $0 --ipa --deb --disable-all
    $0 --ipa --disable-yticons --enable-ytweaks
```
</details>

## Table of Contents
- [Project description](#youtube-plus-ytweaks-fork)
- [Building with GitHub Actions](#github-actions)
- [Building locally](#local-tested-on-macos-15-sequoia)
- [Issues](#issues-bugs--feature-requests)
- [Screenshots](#screenshots)
- [YouTube Plus](#youtube-plus-features)
- [FAQ](#faq)
- [Supported YouTube Version](#supported-youtube-version)
- [Tweak Integration Details](#tweak-integration-details)
- [Credits](#credits)

## Screenshots
<table>
   <tr>
      <td><img src="Resources/scr11.jpg" alt="Screenshot 1" /></td>
      <td><img src="Resources/scr13.jpg" alt="Screenshot 2" /></td>
      <td><img src="Resources/scr14.jpg" alt="Screenshot 3" /></td>
   </tr>
</table>

<details>
  <summary>More screenshots</summary>
  <table>
    <tr>
      <td><img src="Resources/scr4.jpg" alt="Screenshot 4" /></td>
      <td><img src="Resources/scr5.jpg" alt="Screenshot 5" /></td>
      <td><img src="Resources/scr6.jpg" alt="Screenshot 6" /></td>
    </tr>
    <tr>
      <td><img src="Resources/scr7.jpg" alt="Screenshot 7" /></td>
      <td><img src="Resources/scr8.jpg" alt="Screenshot 8" /></td>
      <td><img src="Resources/scr9.jpg" alt="Screenshot 9" /></td>
    </tr>
  </table>
</details>

## YouTube Plus Features
<li>Download videos, audio (including audio track selection), thumbnails, posts, and profile pictures</li>
<li>Copy video, comment, and post information</li>
<li>Interface customization: Remove feed elements, reorder tabs, enable OLED mode, and as use Shorts-only mode</li>
<li>Player settings: Gestures, default quality, preferred audio track</li>
<li>Save, Load and Restore settings. Clear cache once or automatically on app startup</li>
<li>Built-in SponsorBlock</li>
<li>And much, much more</li>
<br>


**YouTube Plus preferences can be found in the YouTube Settings**

**All contributors are listed in the Contributors section**
**Used open-source libraries are listed in the Open Source Libraries section**

## Issues, Bugs & Feature Requests
Fill out an [issue form](https://github.com/fosterbarnes/YTPlusYTweaks/issues) with the applicable option selected and fill out all required info.

## FAQ
- [🇺🇸 English FAQ](https://github.com/dayanch96/YTLite/blob/main/FAQs/FAQ_EN.md)
- [🇷🇺 ЧаВо на Русском](https://github.com/dayanch96/YTLite/blob/main/FAQs/FAQ_RU.md)
- [🇮🇹 FAQ in Italiano](https://github.com/dayanch96/YTLite/blob/main/FAQs/FAQ_IT.md)
- [🇵🇱 FAQ po polsku](https://github.com/dayanch96/YTLite/blob/main/FAQs/FAQ_PL.md)

## Supported YouTube Version
<ul>
    <li><strong>Recommended:</strong> <em>20.10.4</em></li>
   <li><strong>Latest confirmed:</strong> <em>21.13.6</em></li>
   <li><strong>Date tested:</strong> <em>April 4, 2026</em></li>
   <li><strong>YouTube Plus:</strong> <em>5.2 beta 4</em></li>
</ul>

## Tweak Integration Details
<details>
  <summary>YouPiP</summary>
  <p>YouPiP is a tweak developed by <a href="https://github.com/PoomSmart">PoomSmart</a> that enables the native Picture-in-Picture feature for videos in the iOS YouTube app.</p>
  <p><strong>YouPiP preferences</strong> are available in the <strong>YouTube settings</strong>.</p>
  <p>Source code and additional information are available <a href="https://github.com/PoomSmart/YouPiP">in PoomSmart's GitHub repository</a>.</p>
</details>

<details>
  <summary>YTUHD</summary>
  <p>YTUHD is a tweak developed by <a href="https://github.com/PoomSmart">PoomSmart</a> that unlocks 1440p (2K) and 2160p (4K) resolutions in the iOS YouTube app. Forked by <a href="https://github.com/Tonwalter888">Tonwalter888</a> to fix some issues when using the tweak while sideloading</p>
  <p><strong>YTUHD preferences</strong> are available in the <strong>Video quality preferences</strong> section under <strong>YouTube settings</strong>.</p>
  <p>Source code and additional information are available <a href="https://github.com/Tonwalter888/YTUHD">in PoomSmart's GitHub repository</a>.</p>
</details>

<details>
  <summary>Return YouTube Dislikes</summary>
  <p>Return YouTube Dislikes is a tweak developed by <a href="https://github.com/PoomSmart">PoomSmart</a> that brings back dislikes on the YouTube app.</p>
  <p><strong>Return YouTube Dislikes preferences</strong> are available in the <strong>YouTube settings</strong>.</p>
  <p>Source code and additional information are available <a href="https://github.com/PoomSmart/Return-YouTube-Dislikes">in PoomSmart's GitHub repository</a>.</p>
</details>

<details>
  <summary>YouQuality</summary>
  <p>YouQuality is a tweak developed by <a href="https://github.com/PoomSmart">PoomSmart</a> that allows to view and change video quality directly from the video overlay.</p>
  <p><strong>YouQuality can be enabled</strong> in the <strong>Video overlay</strong> section under <strong>YouTube settings</strong>.</p>
  <p>Source code and additional information are available <a href="https://github.com/PoomSmart/YouQuality">in PoomSmart's GitHub repository</a>.</p>
</details>

<details>
  <summary>DontEatMyContent</summary>
  <p>DontEatMyContent is a tweak developed by <a href="https://github.com/therealFoxster">therealFoxster</a> that prevents the Notch/Dynamic Island from munching on 2:1 video content in the iOS YouTube app.</p>
  <p><strong>DontEatMyContent preferences</strong> are available in the <strong>YouTube settings</strong>.</p>
  <p>Source code and additional information are available <a href="https://github.com/therealFoxster/DontEatMyContent">in therealFoxster's GitHub repository</a>.</p>
</details>

<details>
  <summary>YTABConfig</summary>
  <p>YTABConfig is a tweak developed by <a href="https://github.com/PoomSmart">PoomSmart</a> that configures A/B settings in the iOS YouTube app.</p>
  <p><strong>YTABConfig preferences</strong> are available in the <strong>YouTube settings</strong>.</p>
  <p>Source code and additional information are available <a href="https://github.com/PoomSmart/YTABConfig">in PoomSmart's GitHub repository</a>.</p>
</details>

<details>
  <summary>YTIcons</summary>
  <p>YTIcons is a tweak developed by <a href="https://github.com/PoomSmart">PoomSmart</a> that displays all usable icons in the iOS YouTube app.</p>
  <p><strong>YTIcons</strong> are available in the <strong>YouTube settings</strong>.</p>
  <p>Source code and additional information are available <a href="https://github.com/PoomSmart/YTIcons">in PoomSmart's GitHub repository</a>.</p>
</details>

<details>
  <summary>YTweaks</summary>
  <p>YTweaks is a tweak developed by <a href="https://github.com/fosterbarnes">fosterbarnes</a> that adds a few extra settings like "Fullscreen to Right" and "Fullscreen to Left"</p>
  <p><strong>YTweaks</strong> preferences are available in the <strong>YouTube settings</strong>.</p>
  <p>Source code and additional information are available <a href="https://github.com/fosterbarnes/YTweaks">in fosterbarnes's GitHub repository</a>.</p>
</details>

<details>
  <summary>YouGroupSettings</summary>
  <p>YouGroupSettings is a tweak developed by <a href="https://github.com/PoomSmart">PoomSmart</a> that allows custom settings (made by tweaks) to be displayed when the grouped settings experiment is active. Forked by <a href="https://github.com/FosterBarnes">FosterBarnes</a> to support YTweaks</p>
  <p>Source code and additional information are available <a href="https://github.com/fosterbarnes/YouGroupSettings">in fosterbarnes's GitHub repository</a>.</p>
</details>

<details>
  <summary>Gonerino</summary>
  <p>Gonerino is a tweak developed by <a href="https://github.com/castdrian">castdrian</a> that lets you block certain content from your home feed.</p>
  <p>Source code and additional information are available <a href="https://github.com/castdrian/Gonerino">in castdrian's GitHub repository</a>.</p>
</details>

## Credits
Thank you to everyone that made this project possible! This project would not exist without the existing tools made by these developers. I really appreciate your work :)

[dayanch96](https://github.com/dayanch96) - YTLite

[PoomSmart](https://github.com/PoomSmart) - YouPiP, YTUHD, Return YouTube Dislikes, YouQuality, YTABConfig, YTIcons, YouGroupSettings

[therealFoxster](https://github.com/therealFoxster) - DontEatMyContent

[castdrian](https://github.com/castdrian/Gonerino) - Gonerino

[theos](https://github.com/theos) - theos, SDKs

[Tonwalter888](https://github.com/Tonwalter888/) - YTUHD, SDKs
