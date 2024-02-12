import SwiftUI

extension CameraView where S == EmptyView, P == EmptyView {
    /// Creates a simple CameraView.
    /// - Parameters:
    ///     - onFinishCapture: Completion callback when captured a photo.
    ///     - onPermissionDenied: Completion callback when user denied camera permission.
    ///
    /// When using CameraView, ``AppOrientationDelegate`` should be added to your `App` declaration via `@UIApplicationDelegateAdaptor` to get correct behavior.
    public init(
        onFinishCapture: @escaping (Data) -> Void,
        onPermissionDenied: (() -> Void)? = nil
    ) {
        self.onFinishCapture = onFinishCapture
        self.onPermissionDenied = onPermissionDenied
        self.statusBar = EmptyView()
        self.photoAlbum = EmptyView()
    }
}

extension CameraView where S == EmptyView {
    /// Creates a CameraView containing a customized status bar above the camera preview.
    /// - Parameters:
    ///     - onFinishCapture: Completion callback when captured a photo.
    ///     - onPermissionDenied: Completion callback when user denied camera permission.
    ///     - photoAlbum: Customized photo album button below camera preview, aligned with shutter button.
    ///
    /// When using CameraView, ``AppOrientationDelegate`` should be added to your `App` declaration via `@UIApplicationDelegateAdaptor` to get correct behavior.
    public init(
        onFinishCapture: @escaping (Data) -> Void,
        onPermissionDenied: (() -> Void)? = nil,
        @ViewBuilder photoAlbum: () -> P
    ) {
        self.onFinishCapture = onFinishCapture
        self.onPermissionDenied = onPermissionDenied
        self.statusBar = EmptyView()
        self.photoAlbum = photoAlbum()
    }
}

extension CameraView where P == EmptyView {
    /// Creates a CameraView containing a customized photo album button at the leading edge below the camera preview, aligned with the shutter button.
    /// - Parameters:
    ///     - onFinishCapture: Completion callback when captured a photo.
    ///     - onPermissionDenied: Completion callback when user denied camera permission.
    ///     - statusBar: Customized status bar above camera preview.
    ///
    /// When using CameraView, ``AppOrientationDelegate`` should be added to your `App` declaration via `@UIApplicationDelegateAdaptor` to get correct behavior.
    public init(
        onFinishCapture: @escaping (Data) -> Void,
        onPermissionDenied: (() -> Void)? = nil,
        @ViewBuilder statusBar: () -> S
    ) {
        self.onFinishCapture = onFinishCapture
        self.onPermissionDenied = onPermissionDenied
        self.statusBar = statusBar()
        self.photoAlbum = EmptyView()
    }
}
