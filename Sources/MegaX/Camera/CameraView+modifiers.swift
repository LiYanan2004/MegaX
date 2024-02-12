import SwiftUI
import AVFoundation

extension View {
    /// Enable auto deferred photo delivery if the device supports.
    /// - Returns: A view with the CameraView's auto deferred photo delivery enabled or disabled.
    public func autoDeferredPhotoDeliveryEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.autoDeferredPhotoDeliveryEnabledIfPossible = enabled
        }
    }
    
    /// Enable zero shutter lag if the device supports.
    /// - Returns: A view with the CameraView's zero shutter lag enabled or disabled.
    public func zeroShutterLagEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.zeroShutterLagEnabledIfPossible = enabled
        }
    }
    
    /// Enable responsive capture if the device supports.
    /// - Returns: A view with the CameraView's responsive capture mode enabled or disabled.
    public func responsiveCaptureEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.responsiveCaptureEnabledIfPossible = enabled
        }
    }
    
    /// Enable fast capture prioritization if the device supports.
    /// - Returns: A view with the CameraView's fast capture prioritization enabled or disabled.
    public func fastCapturePrioritizationEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.fastCapturePrioritizationEnabledIfPossible = enabled
        }
    }

    /// Enable auto lens switching behavior when capture device consists of multiple lens.
    /// - Returns: A view with the CameraView's auto lens switching mode enabled or disabled.
    func autoSwitchingLensEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.autoSwitchingLens = enabled
        }
    }
    
    /// Enable multitasking camera access if the device supports.
    /// - Returns: A view with the CameraView's multitasking access enabled or disabled.
    public func captureWhenMultiTaskingEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.captureWhenMultiTasking = enabled
        }
    }
    
    /// Sets prefered camera stabilization mode.
    /// - Returns: A view with the CameraView's prefered stabilization mode set.
    public func cameraStabilizationMode(_ mode: AVCaptureVideoStabilizationMode) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.stabilizationMode = mode
        }
    }
}
