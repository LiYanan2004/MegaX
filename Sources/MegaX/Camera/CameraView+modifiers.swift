//
//  CameraView+modifiers.swift
//  Separate
//
//  Created by LiYanan2004 on 2024/2/5.
//

import SwiftUI
import AVFoundation

extension View {    
    func responsiveCaptureEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.responsiveCaptureEnabledIfPossible = enabled
        }
    }
    
    func zeroShutterLagEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.zeroShutterLagEnabledIfPossible = enabled
        }
    }
    
    func captureWhenMultiTaskingEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.captureWhenMultiTasking = enabled
        }
    }
    
    func autoSwitchingLensEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.autoSwitchingLens = enabled
        }
    }
    
    func fastCapturePrioritizationEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.fastCapturePrioritizationEnabledIfPossible = enabled
        }
    }
    
    func autoDeferredPhotoDeliveryEnabled(_ enabled: Bool) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.autoDeferredPhotoDeliveryEnabledIfPossible = enabled
        }
    }
    
    func cameraStabilizationMode(_ mode: AVCaptureVideoStabilizationMode) -> some View {
        transformEnvironment(\._captureConfiguration) { configuration in
            configuration.stabilizationMode = mode
        }
    }
}
