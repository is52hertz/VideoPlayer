import SwiftUI

struct GlassSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        Slider(value: $value, in: range)
            .tint(.white)
    }
}
