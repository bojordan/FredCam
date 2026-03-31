# FredCam

iOS/iPad camera viewer for Bambu Lab P2S 3D printers. Connects to the printer's RTSPS camera stream over your local network.

## Prerequisites

- Xcode 16+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- A Bambu Lab P2S printer on the same network
- The printer's **IP address** and **Access Code** (found on the printer touchscreen under Settings > Network)

## Build

```sh
cd FredCam

# Generate the Xcode project (run after any project.yml changes)
xcodegen generate

# Build from command line
xcodebuild -scheme FredCam \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build

# Or open in Xcode
open FredCam.xcodeproj
```

On first build, Xcode will fetch the VLCKit SPM dependency automatically. This may take a minute.

## Usage

1. Launch the app
2. Tap the gear icon to open Settings
3. Enter your printer's IP address and Access Code
4. Tap "Start Stream" to view the camera feed

The app connects via RTSPS on port 322 using the URL format:
```
rtsps://bblp:<ACCESS_CODE>@<PRINTER_IP>:322/streaming/live/1
```

The printer does **not** need to be in LAN-only mode — cloud mode works as long as the printer is reachable on your local network.

## Project Structure

```
FredCam/
├── project.yml              # xcodegen project definition
├── FredCam/
│   ├── FredCamApp.swift     # App entry point
│   ├── ContentView.swift    # Main view with stream controls
│   ├── CameraView.swift     # VLCKit UIViewRepresentable wrapper
│   ├── SettingsView.swift   # Printer IP/access code configuration
│   ├── PrinterSettings.swift # UserDefaults-backed settings model
│   ├── Info.plist           # App config (TLS exceptions, local network)
│   └── Assets.xcassets/     # App icons and colors
└── README.md
```

## Dependencies

- [vlckit-spm](https://github.com/tylerjonesio/vlckit-spm) (3.6.0) — Swift Package Manager wrapper for VLCKit, provides RTSPS streaming support

## Regenerating the Xcode Project

The `.xcodeproj` is generated from `project.yml` — do not edit it manually. After changing `project.yml`:

```sh
xcodegen generate
```

## Troubleshooting

- **Camera won't connect**: Verify the printer IP is reachable (`ping <IP>`) and port 322 is open (`nc -zv <IP> 322`)
- **Black screen**: The printer camera may take a few seconds to start streaming. Check the Xcode console for VLC state messages.
- **Access Code wrong**: Regenerate the access code on the printer touchscreen and update the app settings
