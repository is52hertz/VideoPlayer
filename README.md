# Video Player

A native video player for macOS, iOS, and iPadOS, built with a focus on fluid transparency, organic blur, and a "Liquid Glass" aesthetic.

## Features

- **Native Performance**: Built entirely with SwiftUI and AVFoundation/AVKit.
- **Liquid Glass Design**: Fluid materials, organic blurs, and HIG-first interface.
- **Local-First Privacy**: No accounts, no cloud sync, and no online scraping.
- **Multi-Platform**: Tailored experiences for macOS, iOS, and iPadOS.

## Tech Stack

- **Framework**: SwiftUI
- **Engine**: AVFoundation / AVKit
- **Persistence**: SwiftData (Planned)
- **Architecture**: View → ViewModel → PlayerEngine → AVPlayer

## Development Tools

This project is optimized for AI-assisted development using:
- **Kiro-CLI**: Project orchestration and specialized agent workflows.
- **Gemini-CLI**: Workflow automation and proactive development.

## Project Structure

- `VideoPlayer/`: Main application source.
  - `Engine/`: Playback logic and AVPlayer integration.
  - `Views/`: UI components and "Glass" primitives.
  - `ViewModel/`: State management and business logic.
- `VideoPlayer.xcodeproj`: Xcode project configuration.

## Getting Started

1. Clone the repository:
   ```bash
   git clone git@github.com:is52hertz/VideoPlayer.git
   ```
2. Open `VideoPlayer.xcodeproj` in Xcode.
3. Build and run on your preferred Apple platform.

## License

Personal project. All rights reserved.
