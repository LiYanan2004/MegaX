//
//  CameraCaptureConfiguration.swift
//  Separate
//
//  Created by LiYanan2004 on 2024/2/5.
//

import AVFoundation

struct CameraCaptureConfiguration: Sendable, Equatable {
    var captureWhenMultiTasking = false
    var autoSwitchingLens = true
    var zeroShutterLagEnabledIfPossible = true
    var responsiveCaptureEnabledIfPossible = true
    var fastCapturePrioritizationEnabledIfPossible = true
    var autoDeferredPhotoDeliveryEnabledIfPossible = false
    var stabilizationMode = AVCaptureVideoStabilizationMode.auto
}
