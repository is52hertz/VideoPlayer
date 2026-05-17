import SwiftUI

struct GlassPanel<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
            .shadow(color: .black.opacity(0.1), radius: 30, x: 0, y: 20)
            // Glass is always rendered in dark context — sampling is consistent
            // regardless of system appearance, and all usage sites are over dark video.
            .environment(\.colorScheme, .dark)
    }
}
