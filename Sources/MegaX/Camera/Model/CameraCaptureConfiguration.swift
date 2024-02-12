import AVFoundation

/// The configuration for customized camera behavior.
struct CameraCaptureConfiguration: Sendable, Equatable {
    /// Enable multitask camera access if available.
    var captureWhenMultiTasking = false
    /// Enable automatic lens switching if the device has multiple constituent devices.
    var autoSwitchingLens = true
    /// Enable zero shutter lag if the device supported.
    var zeroShutterLagEnabledIfPossible = true
    /// Enable responsive capture if the device supported.
    var responsiveCaptureEnabledIfPossible = true
    /// Enable fast capture prioritization if the device supported.
    ///
    /// You should enable `responsiveCaptureEnabledIfPossible` first.
    var fastCapturePrioritizationEnabledIfPossible = true
    /// Enable auto deferred photo delivery if the device supported.
    var autoDeferredPhotoDeliveryEnabledIfPossible = false
    /// Prefered stabilization mode for current capture device.
    var stabilizationMode = AVCaptureVideoStabilizationMode.auto
}
