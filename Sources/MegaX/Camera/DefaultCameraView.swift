import SwiftUI

@available(macOS, unavailable)
extension CameraView where Content == SystemCameraExperience {
    /// Creates a simple CameraView.
    ///
    /// - Parameters:
    ///     - onFinishCapture: Completion callback when captured a photo.
    ///     - errorHandler: Callback when error occurred.
    ///
    /// When using CameraView, ``AppOrientationDelegate`` should be added to your `App` declaration via `@UIApplicationDelegateAdaptor` to get correct behavior.
    public init(
        onFinishCapture: @escaping (Data) -> Void,
        errorHandler: ((CameraError) -> Void)? = nil
    ) {
        self.errorHandler = errorHandler
        self.content = { _ in
            SystemCameraExperience { photo in
                onFinishCapture(photo)
            }
        }
    }
}
