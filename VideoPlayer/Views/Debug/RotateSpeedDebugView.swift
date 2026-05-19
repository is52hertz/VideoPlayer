#if os(macOS)
import SwiftUI

/// 调试窗口：实测 `.symbolEffect(.rotate, options:...speed(x))` 在当前 OS
/// 是否真的响应 .speed —— 用来反复核查 issues-01.md 的核心结论。
///
/// 怎么用：菜单 File → Rotate Speed Debug (⌘⇧D) 打开。拖 slider 调速度。
///
/// 判读：
///   - 顶部 R1–R4 全部是 .symbolEffect(.rotate, ...) 的不同写法（Apple 文档
///     和 Gemini 都声称 .speed 在这里生效）。
///   - R5 是手动 `.rotationEffect + .animation(.linear).speed` 的 baseline，
///     这条 100% 会响应 speed（不走 SF Symbol effect engine）。
///   - C1–C3 是已知会响应 .speed 的对照组（.bounce / .pulse / .variableColor）。
///
///   ✅ 如果拖 slider 时 R5 + C1–C3 都在变化但 R1–R4 纹丝不动
///   → 直接证明 `.rotate` 的 .speed 在公开 API 上 inert，issues-01.md 结论成立。
///
///   ❌ 如果 R1–R4 也在响应 → Apple 已经修了，应该重开 issues-01.md。
struct RotateSpeedDebugView: View {
    @State private var speed: Double = 1.0
    @State private var isActive: Bool = true
    @State private var triggerCount: Int = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                Divider()
                rotateSection
                Divider()
                controlSection
            }
            .padding(24)
        }
        .frame(minWidth: 620, minHeight: 760)
    }

    // MARK: - Header / Controls

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SF Symbol .rotate Speed Debug")
                .font(.title2.bold())

            Text(
                "Apple 文档和 Gemini 都声称 `.symbolEffect(.rotate, options: .repeating.speed(x))` 上的 .speed 会改变旋转速度。我们在 iOS 26 上 14 次实测都判这条无效（见 issues-01.md）。本窗口让你在 macOS 上**用眼睛复测**。\n\n操作：拖 slider 或点预设按钮，看下面两组的反应差异。"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Text("Speed:").bold().frame(width: 50, alignment: .leading)
                Slider(value: $speed, in: 0.1...20.0)
                Text(String(format: "%.2f×", speed))
                    .monospacedDigit()
                    .frame(width: 70, alignment: .trailing)
            }

            HStack(spacing: 8) {
                ForEach([0.2, 0.5, 1.0, 3.0, 10.0, 20.0], id: \.self) { value in
                    Button(String(format: value < 1 ? "%.1f×" : "%.0f×", value)) {
                        speed = value
                    }
                }
                Spacer()
            }

            HStack {
                Toggle("Active (indefinite)", isOn: $isActive)
                Spacer()
                Button("Fire discrete trigger") { triggerCount &+= 1 }
                Text("\(triggerCount)")
                    .monospacedDigit()
                    .frame(width: 40, alignment: .trailing)
            }
        }
    }

    // MARK: - Rotate variants (the patterns under test)

    private var rotateSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Top — .rotate variants (claim: respond to speed)")
                .font(.headline)

            row("R1  .rotate.clockwise  + .repeating.speed(x)  + isActive:") {
                Image(systemName: "fanblades.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.primary)
                    .symbolEffect(
                        .rotate.clockwise,
                        options: .repeating.speed(speed),
                        isActive: isActive
                    )
            }

            row("R2  .rotate.clockwise.byLayer  + .repeating.speed(x)  + isActive:") {
                Image(systemName: "fanblades.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.primary)
                    .symbolEffect(
                        .rotate.clockwise.byLayer,
                        options: .repeating.speed(speed),
                        isActive: isActive
                    )
            }

            row("R3  .rotate.clockwise.wholeSymbol  + .repeating.speed(x)  + isActive:") {
                Image(systemName: "fanblades.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.primary)
                    .symbolEffect(
                        .rotate.clockwise.wholeSymbol,
                        options: .repeating.speed(speed),
                        isActive: isActive
                    )
            }

            row("R4  .rotate.clockwise.byLayer  + .nonRepeating.speed(x)  + value: (discrete, fire button)") {
                Image(systemName: "fanblades.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.primary)
                    .symbolEffect(
                        .rotate.clockwise.byLayer,
                        options: .nonRepeating.speed(speed),
                        value: triggerCount
                    )
            }

            row("R5  BASELINE — manual .rotationEffect + .animation(.linear).speed(x)  (NOT SF Symbol effect engine)") {
                ManualRotationBaseline(speed: speed, isActive: isActive)
            }
        }
    }

    // MARK: - Known-working effects (control group)

    private var controlSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Bottom — known-working effects (control: confirm speed slider IS wired)")
                .font(.headline)

            row("C1  .bounce + .nonRepeating.speed(x) + value: (fire button)") {
                Image(systemName: "heart.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.red)
                    .symbolEffect(
                        .bounce,
                        options: .nonRepeating.speed(speed),
                        value: triggerCount
                    )
            }

            row("C2  .pulse + .repeating.speed(x) + isActive:") {
                Image(systemName: "heart.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.red)
                    .symbolEffect(
                        .pulse,
                        options: .repeating.speed(speed),
                        isActive: isActive
                    )
            }

            row("C3  .variableColor.iterative.reversing + .repeating.speed(x) + isActive:") {
                Image(systemName: "wifi")
                    .font(.system(size: 36))
                    .foregroundStyle(.blue)
                    .symbolEffect(
                        .variableColor.iterative.reversing,
                        options: .repeating.speed(speed),
                        isActive: isActive
                    )
            }
        }
    }

    // MARK: - Row helper

    private func row<V: View>(_ name: String, @ViewBuilder view: () -> V) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text(name)
                .font(.system(size: 11, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
            view()
                .frame(width: 70, height: 70)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.08))
                )
        }
    }
}

/// 手动旋转 baseline。不走 SF Symbol effect engine —— 用 SwiftUI
/// 自己的 `.animation(.linear).speed(x)` 驱动 `.rotationEffect`。
/// 这条 100% 响应 speed，所以拖 slider 它必须明显变化。
private struct ManualRotationBaseline: View {
    let speed: Double
    let isActive: Bool

    @State private var angle: Double = 0

    var body: some View {
        Image(systemName: "fanblades.fill")
            .font(.system(size: 36))
            .foregroundStyle(.primary)
            .rotationEffect(.degrees(angle))
            .onAppear { startSpinIfNeeded() }
            .onChange(of: isActive) { _, _ in startSpinIfNeeded() }
            .onChange(of: speed) { _, _ in startSpinIfNeeded() }
    }

    /// 每次状态变化都重启动画 —— 这样 speed 改动能即时生效。
    private func startSpinIfNeeded() {
        // 重置到 0 不带动画，避免回卷视觉。
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) { angle = 0 }

        guard isActive else { return }
        withAnimation(
            .linear(duration: 1.0)
                .repeatForever(autoreverses: false)
                .speed(speed)
        ) {
            angle = 360
        }
    }
}
#endif
