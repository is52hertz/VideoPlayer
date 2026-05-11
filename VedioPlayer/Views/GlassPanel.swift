import SwiftUI

struct GlassPanel<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            // Official Apple Liquid Glass modifier
            // This applies the system's dynamic, high-refraction material
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            // Layered depth shadow to anchor the floating panel
            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
            .shadow(color: .black.opacity(0.1), radius: 30, x: 0, y: 20)
    }
}
