# Media Control Guidelines for VideoPlayer

## Playback Controls
- **Icons**: Use familiar SF Symbols for Play (`play.fill`), Pause (`pause.fill`), and Seeking (`backward.fill`, `forward.fill`).
- **Sizing**: Ensure touch targets are at least 44x44 points on iOS/iPadOS.
- **Feedback**: Provide immediate visual feedback for all interactions.

## Sliders & Progress
- **Playback Progress**: Use horizontal sliders. Provide live feedback (scrubbing).
- **Volume (macOS)**: Sliders are standard for volume on macOS.
- **Volume (iOS/iPadOS)**: Apple generally recommends `MPVolumeView` or system overlays rather than custom sliders, but for custom "Liquid Glass" UIs, ensure they are intuitive and responsive.

## Interaction Patterns
- **Auto-Hide**: Controls should fade out after a period of inactivity during playback.
- **Tap/Click to Reveal**: Controls emerge from the background when the user interacts with the video area.
- **Drag-to-Move**: On macOS, allowing the control bar to be positioned freely can enhance the desktop workflow.
