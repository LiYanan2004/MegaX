import SwiftUI
import OSLog

/// A view that dynamically rotates its content to match the orientation.
@available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, watchOS 10.0, *)
public struct FixedOrientationView<Content: View>: View {
    private var orientation: InterfaceOrientation?
    @ViewBuilder private var content: () -> Content
    
    /// Creates a view that dynamically rotates its content to match the orientation.
    /// - parameters:
    ///     - orientation: The orientation that the view should be rendered in.
    ///     - content: A view rendered in target orientation.
    /// If you change the orientation after creating this view, the view re-rendered in new orientation without animations.
    public init(
        matching orientation: InterfaceOrientation? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.orientation = orientation
        self.content = content
    }
    
    public var body: some View {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        FOViewController(orientation: orientation) {
            content().ignoresSafeArea()
        }
        #else
        content()
        #endif
    }
}

#if os(iOS) && !targetEnvironment(macCatalyst)
fileprivate struct FOViewController<Content: View>: UIViewControllerRepresentable {
    var orientation: InterfaceOrientation?
    @ViewBuilder var content: () -> Content
    
    func makeUIViewController(context: Context) -> FOViewControllerBase {
        FOViewControllerBase(rootView: content())
    }
    
    func updateUIViewController(_ controller: FOViewControllerBase, context: Context) {
        controller.orientation = orientation
        controller.hostingController.rootView = content()
    }
    
    class FOViewControllerBase: UIViewController {
        let logger = Logger(subsystem: "MEGAX", category: "FixedOrientationView")
        var hostingController: UIHostingController<Content>
        var orientation: InterfaceOrientation? {
            willSet {
                guard let newValue else { return }
                
                self.hostingView.layer.setAffineTransform(.identity)
                let targetRotation =  CGAffineTransform(rotationAngle: newValue.targetTransitionAngle.radians)
                let reversedRotation = CGAffineTransformInvert(targetRotation)
                
                // Center rotated view with animation.
                let newSize = self.view.bounds.applying(reversedRotation).size
                self.hostingView.frame = CGRect(
                    x: self.view.bounds.midX - newSize.width / 2,
                    y: self.view.bounds.midY - newSize.height / 2,
                    width: newSize.width,
                    height: newSize.height
                )
                self.hostingView.layoutIfNeeded()
               
                // Call setAffineTransform first, otherwise, the anchor is not correct.
                self.hostingView.layer.setAffineTransform(reversedRotation)
                self.hostingView.layer.frame = self.view.frame
            }
        }
        
        init(rootView: Content) {
            self.hostingController = .init(rootView: rootView)
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        var hostingView: UIView! { hostingController.view }
        
        override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            
            let targetRotation = coordinator.targetTransform
            let reversedRotation = CGAffineTransformInvert(targetRotation)
            let deltaTransform = CGAffineTransformConcat(self.hostingView.transform, reversedRotation)
            // Give little hint to adjust rotation direction when rotating 180 degrees.
            let optimizedTransform = deltaTransform.rotated(by: 0.00001)
            
            coordinator.animate { coordinator in
                // Center rotated view with animation.
                let newSize = self.view.bounds.applying(reversedRotation).size
                self.hostingView.frame = CGRect(
                    x: self.view.bounds.midX - newSize.width / 2,
                    y: self.view.bounds.midY - newSize.height / 2,
                    width: newSize.width,
                    height: newSize.height
                )
                self.hostingView.layoutIfNeeded()
               
                // Call setAffineTransform first, otherwise, the anchor is not correct.
                self.hostingView.layer.setAffineTransform(optimizedTransform)
                self.hostingView.layer.frame = self.view.frame
            } completion: { _ in
                self.hostingView.layer.setAffineTransform(deltaTransform)
            }
        }
        
        override func viewIsAppearing(_ animated: Bool) {
            super.viewIsAppearing(animated)
            
            hostingView.frame = view.frame
            view.addSubview(hostingView)
            
            // Check the view bounds.
            // It should match the full size considering safe area or ignoring it.
            guard let window = view.window else {
                logger.error("Unable to find current view window.")
                return
            }
            let idealSizeWithoutSafeArea = window.safeAreaLayoutGuide.layoutFrame.size
            let idealSizeWithSafeArea = window.bounds.size
            let viewSize = view.bounds.size
            if idealSizeWithoutSafeArea != viewSize && idealSizeWithSafeArea != viewSize {
                logger.error("[MISUSE] FixedOrientationView should have the same size as the window.")
            }
        }
    }
}
#endif
