# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

FredCam is an iOS/iPadOS app that streams the RTSPS camera feed from a Bambu Lab P2S 3D printer. It connects to the printer over the local network using a URL of the form:

```
rtsps://bblp:<ACCESS_CODE>@<PRINTER_IP>:322/streaming/live/1
```

## Build Commands

The Xcode project is generated from `project.yml` using XcodeGen:

```bash
# Regenerate Xcode project after editing project.yml
xcodegen generate

# Build for simulator
xcodebuild -scheme FredCam -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Open in Xcode
open FredCam.xcodeproj
```

There are no tests and no linter configured.

## Architecture

The app uses SwiftUI with an explicit enum state machine as its core organizing principle:

```swift
enum StreamState { case idle, connecting, live, error(String) }
```

**State transitions:**
- `idle → connecting`: user taps "Start Stream"
- `connecting → live`: KSPlayer `bufferFinished` callback fires
- `connecting/live → error`: KSPlayer error callback fires
- `any → idle`: user taps Stop
- `error → connecting`: user taps "Try Again"

**Key files:**

| File | Role |
|------|------|
| `ContentView.swift` | Main orchestrator; owns `StreamState`; handles portrait/landscape layout switching |
| `CameraView.swift` | `UIViewRepresentable` wrapping KSPlayer's `KSPlayerLayer`; bridges player events back to `ContentView` via callbacks |
| `PrinterSettings.swift` | `@ObservableObject`; stores printer IP + access code in `UserDefaults`; builds the RTSPS URL |
| `SettingsView.swift` | Sheet for entering printer IP (decimal pad) and access code (SecureField) |
| `TLSProxy.swift` | **Unused.** A local TCP proxy approach for TLS; kept for reference only. |

## Important Design Decisions

- **KSPlayer over VLCKit**: KSPlayer supports `tls_verify: 0` to accept self-signed certs on the printer. VLCKit's GnuTLS backend does not support this.
- **Stable `CameraView` identity**: `CameraView` must stay at a fixed structural position in the view hierarchy to preserve KSPlayer's playback state across layout changes (portrait ↔ landscape). Moving it conditionally causes the player to tear down and reinitialize.
- **Portrait vs. landscape layout**: Portrait puts controls below the video; landscape puts them to the right. The layout switch is driven by `GeometryReader` + `horizontalSizeClass`.

## KSPlayer Configuration

Low-latency settings applied in `CameraView.swift`:

```swift
options.avOptions["rtsp_transport"] = "tcp"
options.avOptions["tls_verify"] = "0"
options.nobuffer = true
options.codecLowDelay = true
options.maxAnalyzeDuration = 1_000_000
options.probesize = 500_000
options.canStartPictureInPictureAutomaticallyFromInline = true
```

## Info.plist / Entitlements

- `NSAllowsArbitraryLoads: true` — needed for local network HTTP access
- `UIBackgroundModes: audio` — keeps the stream alive when the app is backgrounded
- `NSBonjourServices: _rtsp._tcp` — required for local network permission prompt on iOS 14+
- Deployment target: **iOS 26.0**
