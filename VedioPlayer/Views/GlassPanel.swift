import SwiftUI

struct GlassPanel<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content()
            .background {
                ZStack {
                    // 1. Specular Back-glow: Creates a halo of light refraction around the panel
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white.opacity(0.1))
                        .blur(radius: 20)
                        .blendMode(.plusLighter)

                    // 2. Base Material Layer: Core blur and translucency
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // 3. Liquid Body (Refraction simulation): 
                    // Adds a subtle gradient tint to simulate light bouncing inside the glass.
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(colorScheme == .dark ? 0.08 : 0.03),
                                    .clear,
                                    .white.opacity(colorScheme == .dark ? 0.02 : 0.01)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.plusLighter)

                    // 4. Primary High-Refraction Rim (Specular Edge):
                    // Sharp, high-contrast highlights that mimic light catching a curved edge.
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0.6), location: 0),
                                    .init(color: .white.opacity(0.1), location: 0.3),
                                    .init(color: .white.opacity(0.0), location: 0.5),
                                    .init(color: .white.opacity(0.2), location: 1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                        .blendMode(.plusLighter)
                    
                    // 5. Secondary "Glass Lip": A very faint inner shadow/stroke to add thickness
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.black.opacity(0.05), lineWidth: 1)
                }
            }
            // 6. Deep Multi-layered Organic Shadows: Makes the panel "float"
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            .shadow(color: .black.opacity(0.1), radius: 30, x: 0, y: 20)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
