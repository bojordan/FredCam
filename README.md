# FredCam

iOS/iPad camera viewer for Bambu Lab P2S 3D printers. Connects to the printer's RTSPS camera stream over your local network.

## Prerequisites

- Xcode 16+ with iOS 26 SDK
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- A Bambu Lab P2S printer on the same network
- The printer's **IP address** and **Access Code** (found on the printer touchscreen under Settings > Network)

## Build

```sh
cd FredCam

# Generate the Xcode project (run after any project.yml changes)
xcodegen generate

# Build from command line (iOS 26 simulator)
xcodebuild -scheme FredCam \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  build

# Or open in Xcode
open FredCam.xcodeproj
```

On first build, Xcode will fetch the KSPlayer SPM dependency automatically. This may take a few minutes.

> **Note:** KSPlayer requires the Metal toolchain. If you see a build error about missing Metal components, run:
> ```sh
> xcodebuild -downloadComponent MetalToolchain
> ```

## Usage

1. Launch the app
2. Tap the gear icon to open Settings
3. Enter your printer's IP address (use the `.` key on the decimal pad keyboard) and Access Code
4. Tap Done, then tap **Start Stream**

The app shows a pulsing connecting animation while establishing the stream. If the connection fails, an error overlay appears with a **Try Again** button.

The stream URL format used internally:
```
rtsps://bblp:<ACCESS_CODE>@<PRINTER_IP>:322/streaming/live/1
```

The printer does **not** need to be in LAN-only mode — cloud mode works as long as the printer is reachable on your local network.

## Features

- **Picture-in-Picture** — tap the PiP button (appears once the stream is live) to keep the feed visible while using other apps
- **Portrait and landscape** — controls appear below the video (portrait) or in a sidebar (landscape) so they never overlap the feed
- **Animated transitions** — smooth fade when starting/stopping the stream
- **Error recovery** — connection failures are displayed with a retry button rather than silently dropping back to the idle screen

## Project Structure

```
FredCam/
├── project.yml               # xcodegen project definition
├── FredCam/
│   ├── FredCamApp.swift      # App entry point
│   ├── ContentView.swift     # Main view, StreamState machine, layout
│   ├── CameraView.swift      # KSPlayer UIViewRepresentable wrapper
│   ├── SettingsView.swift    # Printer IP/access code configuration
│   ├── PrinterSettings.swift # UserDefaults-backed settings model
│   ├── TLSProxy.swift        # Local TLS proxy (unused; kept for reference)
│   ├── Info.plist            # App config (TLS exceptions, local network)
│   └── Assets.xcassets/      # App icons and colors
└── README.md
```

## Dependencies

- [KSPlayer](https://github.com/kingslay/KSPlayer) (2.2.0+) — FFmpeg-based player with RTSPS support and `tls_verify: 0` for the printer's self-signed certificate

VLCKit was evaluated but rejected: VLCKit 3.x uses GnuTLS which cannot bypass self-signed certificate verification, so the printer's RTSPS stream cannot be opened.

## Regenerating the Xcode Project

The `.xcodeproj` is generated from `project.yml` — do not edit it manually. After changing `project.yml`:

```sh
xcodegen generate
```

## Troubleshooting

- **Camera won't connect**: Verify the printer IP is reachable (`ping <IP>`) and port 322 is open (`nc -zv <IP> 322`)
- **Stays on connecting screen**: Check the printer IP and Access Code in Settings. Use `ffplay 'rtsps://bblp:<code>@<ip>:322/streaming/live/1'` on a Mac to verify the stream works outside the app.
- **Black screen after connecting**: The status changes to live but no video appears — this is likely a KSPlayer layout issue. Try stopping and restarting the stream.
- **Build error: invalid bundle identifier**: KSPlayer's `libshaderc_combined` framework uses an underscore in its bundle ID, which Xcode 26 rejects. Fix by patching the embedded plist:
  ```sh
  chmod -R u+w ~/Library/Developer/Xcode/DerivedData
  plutil -replace CFBundleIdentifier \
    -string com.kintan.ksplayer.libshaderc-combined \
    "$(find ~/Library/Developer/Xcode/DerivedData -name libshaderc_combined.framework -print -quit)/Info.plist"
  ```
- **Access Code wrong**: Regenerate the access code on the printer touchscreen and update the app settings
