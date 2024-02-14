import SwiftUI

extension CameraView where P == EmptyView {
    /// Creates a simple CameraView.
    /// - Parameters:
    ///     - onFinishCapture: Completion callback when captured a photo.
    ///     - errorHandler: Callback when error occurred.
    ///
    /// When using CameraView, ``AppOrientationDelegate`` should be added to your `App` declaration via `@UIApplicationDelegateAdaptor` to get correct behavior.
    public init(
        onFinishCapture: @escaping (Data) -> Void,
        errorHandler: ((CameraError) -> Void)? = nil
    ) {
        self.onFinishCapture = onFinishCapture
        self.errorHandler = errorHandler
        self.photoAlbum = EmptyView()
    }
}
