import SwiftUI

struct GlassPanel<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .background {
                ZStack {
                    // 1. Base Material: Provides the core refraction/blur
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // 2. Liquid Tint: Gives the glass a subtle body/reflection
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white.opacity(0.03))
                    
                    // 3. Refraction/Highlight Edge: 
                    // Simulates light catching the organic curve of the glass.
                    // Uses a gradient to create a non-uniform, "liquid" glint.
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.4), 
                                    .white.opacity(0.1), 
                                    .white.opacity(0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
            }
            // 4. Layered Depth Shadows: Creates a soft, organic lift
            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
            .shadow(color: .black.opacity(0.08), radius: 25, x: 0, y: 15)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
