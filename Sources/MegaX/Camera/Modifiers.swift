import SwiftUI
import AVFoundation

@available(watchOS, unavailable)
@available(visionOS, unavailable)
extension View {
    /// Enable auto deferred photo delivery if the device supports.
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(iOS 17.0, *)
    public func autoDeferredPhotoDeliveryEnabled(_ enabled: Bool = true) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.preferAutoDeferredPhotoDelivery = enabled
        }
    }
    
    /// Enable zero shutter lag if the device supports.
    @available(iOS 17.0, tvOS 17.0, macOS 14.0, *)
    public func zeroShutterLagEnabled(_ enabled: Bool = true) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.preferZeroShutterLag = enabled
        }
    }
    
    /// Enable responsive capture if the device supports.
    @available(iOS 17.0, tvOS 17.0, macOS 14.0, *)
    public func responsiveCaptureEnabled(_ enabled: Bool = true) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.preferResponsiveCapture = enabled
        }
    }
    
    /// Enable fast capture prioritization if the device supports.
    @available(iOS 17.0, tvOS 17.0, macOS 14.0, *)
    public func fastCapturePrioritizationEnabled(_ enabled: Bool = true) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            if enabled {
                configuration.preferResponsiveCapture = true
            }
            configuration.preferFastCapturePrioritization = enabled
        }
    }

    /// Enable auto lens switching behavior when capture device consists of multiple lens.
    @available(iOS 17.0, tvOS 17.0, macOS 14.0, *)
    func autoSwitchingLensEnabled(_ enabled: Bool = true) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.autoSwitchingLens = enabled
        }
    }
    
    /// Enable multitasking camera access if the device supports.
    @available(iOS 17.0, tvOS 17.0, macOS 14.0, *)
    public func captureWhenMultiTaskingEnabled(_ enabled: Bool = true) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.captureWhenMultiTasking = enabled
        }
    }
    
    /// Sets prefered camera stabilization mode.
    @available(macOS, unavailable)
    @available(iOS 17.0, tvOS 17.0, *)
    public func cameraStabilizationMode(_ mode: AVCaptureVideoStabilizationMode) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            #if os(iOS) || os(tvOS)
            configuration.stabilizationMode = mode
            #endif
        }
    }
    
    /// Prefer capture content in constant color if the device is capable.
    @available(iOS 18.0, tvOS 18.0, macOS 15.0, *)
    public func cameraConstantColorEnabled(_ enabled: Bool = true, fallbackDeliveryEnabled: Bool = true) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.preferConstantColor = enabled
            configuration.enableConstantColorFallbackDelivery = enabled
        }
    }
}
