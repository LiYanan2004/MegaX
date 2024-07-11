import AVFoundation

/// The configuration for customized camera behavior.
struct CameraCaptureConfiguration: Sendable, Equatable {
    /// Enable multitask camera access if available.
    var captureWhenMultiTasking = false
    /// Enable automatic lens switching if the device has multiple constituent devices.
    var autoSwitchingLens = true
    /// Enable zero shutter lag if the device supported.
    var preferZeroShutterLag = true
    /// Enable responsive capture if the device supported.
    var preferResponsiveCapture = true
    /// Enable fast capture prioritization if the device supported.
    var preferFastCapturePrioritization = true
    #if os(iOS)
    /// Enable auto deferred photo delivery if the device supported.
    var preferAutoDeferredPhotoDelivery = false
    /// Prefered stabilization mode for current capture device.
    var stabilizationMode = AVCaptureVideoStabilizationMode.auto
    #endif
    /// A Boolean value that indicates whether to capture the photo with constant color.
    var preferConstantColor = false
    /// A Boolean value that indicates whether to deliver a fallback photo when taking a constant color capture without enough confidence.
    var enableConstantColorFallbackDelivery = false
}
