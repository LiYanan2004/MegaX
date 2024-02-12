import SwiftUI
import AVFoundation

public extension View { 
    /// Enable responsive capture if the device supports.
    /// - Returns: A view with the CameraView's responsive capture mode enabled or disabled.
    func responsiveCaptureEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.responsiveCaptureEnabledIfPossible = enabled
        }
    }
    
    /// Enable zero shutter lag if the device supports.
    /// - Returns: A view with the CameraView's zero shutter lag enabled or disabled.
    func zeroShutterLagEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.zeroShutterLagEnabledIfPossible = enabled
        }
    }
    
    /// Enable multitasking camera access if the device supports.
    /// - Returns: A view with the CameraView's multitasking access enabled or disabled.
    func captureWhenMultiTaskingEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.captureWhenMultiTasking = enabled
        }
    }
    
    /// Enable fast capture prioritization if the device supports.
    /// - Returns: A view with the CameraView's fast capture prioritization enabled or disabled.
    func fastCapturePrioritizationEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.fastCapturePrioritizationEnabledIfPossible = enabled
        }
    }
    
    /// Enable auto deferred photo delivery if the device supports.
    /// - Returns: A view with the CameraView's auto deferred photo delivery enabled or disabled.
    func autoDeferredPhotoDeliveryEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.autoDeferredPhotoDeliveryEnabledIfPossible = enabled
        }
    }
    
    
    /// Enable auto lens switching behavior when capture device consists of multiple lens.
    /// - Returns: A view with the CameraView's auto lens switching mode enabled or disabled.
    func autoSwitchingLensEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.autoSwitchingLens = enabled
        }
    }
    
    /// Sets prefered camera stabilization mode.
    /// - Returns: A view with the CameraView's prefered stabilization mode set.
    func cameraStabilizationMode(_ mode: AVCaptureVideoStabilizationMode) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.stabilizationMode = mode
        }
    }
}
