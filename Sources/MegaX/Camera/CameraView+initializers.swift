import SwiftUI
import AVFoundation

extension CameraView where S == EmptyView, P == EmptyView {
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
        self.statusBar = { _ in EmptyView() }
        self.photoAlbum = EmptyView()
    }
}

extension CameraView where S == EmptyView {
    /// Creates a CameraView containing a customized status bar above the camera preview.
    /// - Parameters:
    ///     - onFinishCapture: Completion callback when captured a photo.
    ///     - errorHandler: Callback when error occurred.
    ///     - photoAlbum: Customized photo album button below camera preview, aligned with shutter button.
    ///
    /// When using CameraView, ``AppOrientationDelegate`` should be added to your `App` declaration via `@UIApplicationDelegateAdaptor` to get correct behavior.
    public init(
        onFinishCapture: @escaping (Data) -> Void,
        errorHandler: ((CameraError) -> Void)? = nil,
        @ViewBuilder photoAlbum: () -> P
    ) {
        self.onFinishCapture = onFinishCapture
        self.errorHandler = errorHandler
        self.statusBar = { _ in EmptyView() }
        self.photoAlbum = photoAlbum()
    }
}

extension CameraView where P == EmptyView {
    /// Creates a CameraView containing a customized photo album button at the leading edge below the camera preview, aligned with the shutter button.
    /// - Parameters:
    ///     - onFinishCapture: Completion callback when captured a photo.
    ///     - errorHandler: Callback when error occurred.
    ///     - statusBar: Customized status bar above camera preview.
    ///
    /// When using CameraView, ``AppOrientationDelegate`` should be added to your `App` declaration via `@UIApplicationDelegateAdaptor` to get correct behavior.
    public init(
        onFinishCapture: @escaping (Data) -> Void,
        errorHandler: ((CameraError) -> Void)? = nil,
        @ViewBuilder statusBar: @escaping (AVCaptureDevice) -> S
    ) {
        self.onFinishCapture = onFinishCapture
        self.errorHandler = errorHandler
        self.statusBar = statusBar
        self.photoAlbum = EmptyView()
    }
}
