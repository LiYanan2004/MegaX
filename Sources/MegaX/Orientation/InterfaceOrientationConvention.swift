import SwiftUI

extension InterfaceOrientation {
    /// Rotation angle of a view relative to portrait orientation during orientation change.
    var targetTransitionAngle: Angle {
        switch self {
        case .portraitUpsideDown: .degrees(180)
        case .landscapeLeft: .degrees(-90)
        case .landscapeRight: .degrees(90)
        default: .zero
        }
    }
    
    /// Reversed rotation angle of `targetTransitionAngle`, or called counter rotation angle.
    var reverseTransitionAngle: Angle {
        .zero - targetTransitionAngle
    }
    
    #if os(iOS) && !targetEnvironment(macCatalyst)
    /// Equivalent value in UIInterfaceOrientation.
    var uiInterfaceOrientation: UIInterfaceOrientation {
        switch self {
        case .landscapeLeft: .landscapeRight
        case .landscapeRight: .landscapeLeft
        case .portrait: .portrait
        case .portraitUpsideDown: .portraitUpsideDown
        default: fatalError("Unknown interface orientation.")
        }
    }

    /// Initialize `InterfaceOrientation`  enum from UIKit `UIInterfaceOrientation`.
    init(_ uiInterfaceOrientation: UIInterfaceOrientation) {
        self = switch uiInterfaceOrientation {
        case .landscapeLeft: .landscapeRight
        case .landscapeRight: .landscapeLeft
        case .portraitUpsideDown: .portraitUpsideDown
        default: .portrait
        }
    }
    #endif
}
