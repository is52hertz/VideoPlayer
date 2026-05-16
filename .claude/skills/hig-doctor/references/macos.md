# macOS Design Guidelines for VideoPlayer

## Display & Windows
- **Large Displays**: Leverage screen real estate to present content with minimal nesting.
- **Window Management**: Support resizing, moving, and full-screen mode.
- **Immersive Mode**: In video apps, hide title bars and traffic lights when controls are hidden to focus on content.

## Inputs
- **Precision**: Optimize for high-precision pointer interaction.
- **Keyboard**: Extensive use of keyboard shortcuts (e.g., Space for play/pause, Arrows for seeking).
- **Hover**: Use hover states to reveal controls organically.

## Best Practices
- Use the menu bar for all commands.
- Support personalization (e.g., customizable toolbars if applicable).
- Handle window activation gracefully; controls should respond even if the window is not in front.
