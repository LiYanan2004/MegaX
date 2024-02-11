//
//  CameraModel+ReadinessCoordinator.swift
//  Separate
//
//  Created by LiYanan2004 on 2024/2/5.
//

import AVFoundation

extension CameraModel: AVCapturePhotoOutputReadinessCoordinatorDelegate {
    func readinessCoordinator(_ coordinator: AVCapturePhotoOutputReadinessCoordinator, captureReadinessDidChange captureReadiness: AVCapturePhotoOutput.CaptureReadiness) {
        self.shutterDisabled = captureReadiness != .ready
        self.isBusyProcessing = captureReadiness == .notReadyWaitingForProcessing
    }
}
