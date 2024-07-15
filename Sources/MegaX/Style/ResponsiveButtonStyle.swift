import SwiftUI

extension View {
    /// Sets the style for buttons within this view to a button style with a responsive button style.
    /// - parameters:
    ///     - minimumScale: The minimum scaling factor to reflect pressing state when user press the button.
    ///     - onPressingChanged: The action to perform when pressing state changes.
    public func responsiveButton(
        minimumScale: CGFloat = 0.9,
        onPressingChanged: ((Bool) -> Void)? = nil
    ) -> some View {
        buttonStyle(
            .responsive(
                minimumScale: minimumScale,
                onPressingChanged: onPressingChanged
            )
        )
    }
}

/// A button style that feels responsive by scaling its content when user press it.
public struct ResponsiveButtonStyle: PrimitiveButtonStyle {
    /// The minimum scaling factor to reflect pressing state when user press the button.
    var minimumScale: CGFloat
    /// The action to perform when pressing state changes.
    var onPressingChanged: ((Bool) -> Void)?
    
    @Environment(\.isEnabled) private var isEnabled
    @GestureState(resetTransaction: .init(animation: .smooth(duration: 0.2)))
    private var scale = CGFloat(1)
    @State private var isPressing = false
    
    /// Creates a reponsive button style.
    /// - parameters:
    ///     - minimumScale: The minimum scaling factor to reflect pressing state when user press the button.
    ///     - onPressingChanged: The action to perform when pressing state changes.
    public init(minimumScale: CGFloat = 0.9, onPressingChanged: ((Bool) -> Void)? = nil) {
        self.minimumScale = minimumScale
        self.onPressingChanged = onPressingChanged
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(scale)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($scale) { _, scale, transaction in
                        guard isEnabled else { return }
                        transaction.animation = .snappy(duration: 0.3)
                        scale = minimumScale
                        Task {
                            if isPressing == false {
                                isPressing = true
                                onPressingChanged?(true)
                            }
                        }
                    }
                    .onEnded { _ in
                        guard isEnabled else { return }
                        if isPressing {
                            isPressing = false
                            onPressingChanged?(false)
                        }
                        configuration.trigger()
                    }
            )
    }
}

extension PrimitiveButtonStyle where Self == ResponsiveButtonStyle {
    /// A button style that feels responsive by scaling its content when user press it.
    public static var responsive: ResponsiveButtonStyle { .init() }
    
    /// A button style that feels responsive by scaling its content when user press it.
    /// - parameters:
    ///     - minimumScale: The minimum scaling factor to reflect pressing state when user press the button.
    ///     - onPressingChanged: The action to perform when pressing state changes.
    public static func responsive(minimumScale: CGFloat = 0.9, onPressingChanged: ((Bool) -> Void)? = nil) -> ResponsiveButtonStyle {
        .init(minimumScale: minimumScale, onPressingChanged: onPressingChanged)
    }
}

#Preview {
    Button {
        print("Action Triggered")
    } label: {
        Circle()
            .frame(width: 60, height: 60)
    }
    .responsiveButton { pressing in
        print("isPressing:", pressing)
    }
    .background {
        Circle()
            .stroke(lineWidth: 4)
            .frame(width: 68, height: 68)
    }
}
