import SwiftUI

struct GlassButton: View {
    let systemName: String
    var fontSize: CGFloat = 18
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: fontSize, weight: .medium))
                .frame(width: 40, height: 40)
        }
        // Official Apple Liquid Glass button style
        .buttonStyle(.glass)
    }
}
