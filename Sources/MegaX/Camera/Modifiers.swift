import SwiftUI
import AVFoundation

extension View {
    /// Enable auto deferred photo delivery if the device supports.
    public func autoDeferredPhotoDeliveryEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.preferAutoDeferredPhotoDelivery = enabled
        }
    }
    
    /// Enable zero shutter lag if the device supports.
    public func zeroShutterLagEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.preferZeroShutterLag = enabled
        }
    }
    
    /// Enable responsive capture if the device supports.
    public func responsiveCaptureEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.preferResponsiveCapture = enabled
        }
    }
    
    /// Enable fast capture prioritization if the device supports.
    public func fastCapturePrioritizationEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            if enabled {
                configuration.preferResponsiveCapture = true
            }
            configuration.preferFastCapturePrioritization = enabled
        }
    }

    /// Enable auto lens switching behavior when capture device consists of multiple lens.
    func autoSwitchingLensEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.autoSwitchingLens = enabled
        }
    }
    
    /// Enable multitasking camera access if the device supports.
    public func captureWhenMultiTaskingEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.captureWhenMultiTasking = enabled
        }
    }
    
    /// Sets prefered camera stabilization mode.
    @available(macOS, unavailable)
    public func cameraStabilizationMode(_ mode: AVCaptureVideoStabilizationMode) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            #if os(iOS)
            configuration.stabilizationMode = mode
            #endif
        }
    }
    
    /// Prefer capture content in constant color if the device is capable.
    public func cameraConstantColorEnabled(_ enabled: Bool = true, fallbackDeliveryEnabled: Bool = true) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            #if os(iOS)
            configuration.preferConstantColor = enabled
            configuration.enableConstantColorFallbackDelivery = enabled
            #endif
        }
    }
}
