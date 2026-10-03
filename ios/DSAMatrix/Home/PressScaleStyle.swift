import SwiftUI

/// Fast compression on press, overshooting spring on release.
struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(
                configuration.isPressed ? .easeOut(duration: 0.1) : .spring(response: 0.42, dampingFraction: 0.55),
                value: configuration.isPressed
            )
    }
}
