import AVFoundation

extension CameraModel: AVCapturePhotoOutputReadinessCoordinatorDelegate {
    func readinessCoordinator(_ coordinator: AVCapturePhotoOutputReadinessCoordinator, captureReadinessDidChange captureReadiness: AVCapturePhotoOutput.CaptureReadiness) {
        self.shutterDisabled = captureReadiness != .ready
        self.isBusyProcessing = captureReadiness == .notReadyWaitingForProcessing
    }
}
