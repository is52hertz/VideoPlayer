import SwiftUI

struct GlassSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    @State private var isDragging = false
    @State private var dragValue: Double? = nil

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background Track
                Capsule()
                    .fill(.white.opacity(0.2))
                    .frame(height: 4)
                
                // Filled Track
                Capsule()
                    .fill(.white)
                    .frame(width: max(0, min(geometry.size.width, CGFloat((currentValue - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width)), height: 4)
                
                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: 12, height: 12)
                    .offset(x: max(-6, min(geometry.size.width - 6, CGFloat((currentValue - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width - 6)))
                    .shadow(color: .black.opacity(0.2), radius: 2)
            }
            .contentShape(Rectangle()) // Expand hit target to the whole height
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let percentage = min(max(0, gesture.location.x / geometry.size.width), 1)
                        let newValue = range.lowerBound + (range.upperBound - range.lowerBound) * Double(percentage)
                        dragValue = newValue
                        value = newValue
                    }
                    .onEnded { _ in
                        isDragging = false
                        dragValue = nil
                    }
            )
        }
        .frame(height: 12)
    }
    
    private var currentValue: Double {
        dragValue ?? value
    }
}
