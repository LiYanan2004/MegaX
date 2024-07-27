import SwiftUI

extension View {
    /// Rotates a view in reverse based on device orientation changes.
    /// - parameter orientation: The orientation this view should be rendered in.
    /// - returns: A view that automatically rotates itself to match the specific orientation.
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, watchOS 10.0, *)
    nonisolated public func counterRotationEffect(matching orientation: InterfaceOrientation) -> some View {
        modifier(CounterRotationEffectModifier(orientation: orientation))
    }
    
    /// Associates a binding to a counter rotation angle that matches the given orientation with the view.
    ///
    /// - parameters:
    ///     - angle: A binding to counter rotation angle according to current device orientation.
    ///     - orientation: The orientation this view should be rendered in.
    ///
    /// You can use this modifier to obtain the counter rotation angle and use it to coordinates with other views.
    ///
    /// For example, if you want to use `Vision` framework to track camera scene, use `.counterRotationAngle($angle, matching: .landscapeLeft)` to get the video rotation angle.
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, watchOS 10.0, *)
    nonisolated public func counterRotationAngle(
        _ angle: Binding<Angle>,
        matching orientation: InterfaceOrientation
    ) -> some View {
        modifier(CounterRotationCoordinatorModifier(orientation: orientation, counterAngle: angle))
    }
}

/// A view modifier that obtains counter rotation angle and apply it to the view.
fileprivate struct CounterRotationEffectModifier: ViewModifier {
    var orientation: InterfaceOrientation
    @State private var angle = Angle.zero
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(angle)
            #if os(iOS) && !targetEnvironment(simulator)
            .modifier(CounterRotationCoordinatorModifier(orientation: orientation, counterAngle: $angle))
            #endif
    }
}

/// A view modifier that offers the counter rotation angle to the target orientation.
fileprivate struct CounterRotationCoordinatorModifier: ViewModifier {
    var orientation: InterfaceOrientation
    @Binding var counterAngle: Angle
    
    func body(content: Content) -> some View {
        content
            #if os(iOS) && !targetEnvironment(simulator)
            .background {
                CounterRotationCoordinator(rotationAngle: $counterAngle, orientation: orientation) {
                    let currentOrientation = $0.view.window?.windowScene?.interfaceOrientation
                    guard let currentOrientation else { return }
                    let transaction = Transaction(animation: nil)
                    withTransaction(transaction) {
                        counterAngle = orientation.reverseTransitionAngle - InterfaceOrientation(currentOrientation).reverseTransitionAngle
                    }
                }
                .accessibilityHidden(true)
                .allowsHitTesting(false)
                .onAppear {
                    let currentOrientation = UIApplication.shared.connectedScenes
                        .compactMap { $0 as? UIWindowScene }
                        .first?
                        .interfaceOrientation
                    guard let currentOrientation else { return }
                    let transaction = Transaction(animation: nil)
                    withTransaction(transaction) {
                        counterAngle = orientation.reverseTransitionAngle - InterfaceOrientation(currentOrientation).reverseTransitionAngle
                    }
                }
            }
            #endif
    }
}

#if os(iOS) && !targetEnvironment(macCatalyst)
/// A view that coordinates the orientation.
fileprivate struct CounterRotationCoordinator: UIViewControllerRepresentable {
    @Binding var rotationAngle: Angle
    var orientation: InterfaceOrientation
    var appearingAction: ((CounterRotationCoordinator.RotationCoordinatorViewController) -> Void)?
    
    func makeUIViewController(context: Context) -> RotationCoordinatorViewController {
        RotationCoordinatorViewController(rotationAngle: $rotationAngle, orientation: orientation, appearingAction: appearingAction)
    }
    
    func updateUIViewController(_ controller: RotationCoordinatorViewController, context: Context) {
        controller.orientation = orientation
    }
    
    class RotationCoordinatorViewController: UIViewController {
        @Binding var rotationAngle: Angle
        var orientation: InterfaceOrientation {
            willSet {
                let delta = newValue.reverseTransitionAngle - orientation.reverseTransitionAngle
                Task { @MainActor in
                    rotationAngle += delta
                }
            }
        }
        var appearingAction: ((CounterRotationCoordinator.RotationCoordinatorViewController) -> Void)?
        
        init(rotationAngle: Binding<Angle>, orientation: InterfaceOrientation, appearingAction: ((CounterRotationCoordinator.RotationCoordinatorViewController) -> Void)?) {
            _rotationAngle = rotationAngle
            self.orientation = orientation
            self.appearingAction = appearingAction
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewIsAppearing(_ animate: Bool) {
            super.viewIsAppearing(animate)
            self.appearingAction?(self)
        }
        
        override func viewWillTransition(
            to size: CGSize,
            with coordinator: any UIViewControllerTransitionCoordinator
        ) {
            super.viewWillTransition(to: size, with: coordinator)
            let targetTransform = coordinator.targetTransform
            let invertedRotation = CGAffineTransformInvert(targetTransform).decomposed().rotation
            coordinator.animate { _ in
                self.rotationAngle = .radians(self.rotationAngle.radians + invertedRotation)
            }
        }
    }
}
#endif
