import SwiftUI
import AVFoundation

extension Camera: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        // Fully dim the preview and show it back.
        dimCameraPreview = 1
        withAnimation(.smooth(duration: 0.25)) {
            dimCameraPreview = 0
        }
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            logger.error("There is an error when finishing processing photo: \(error.localizedDescription)")
            errorHandler?(.captureError(error))
            return
        }
        
        Task { @MainActor in
            self.photoData = photo.fileDataRepresentation()
        }
    }
    
    #if os(iOS) && !targetEnvironment(macCatalyst)
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishCapturingDeferredPhotoProxy deferredPhotoProxy: AVCaptureDeferredPhotoProxy?, error: Error?) {
        if let error = error {
            logger.error("There is an error when finishing capturing deferred photo: \(error.localizedDescription)")
            errorHandler?(.captureError(error))
            return
        }
        
        Task { @MainActor in
            self.photoData = deferredPhotoProxy?.fileDataRepresentation()
        }
    }
    #endif
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            logger.error("There is an error when finishing capture for resolved settings photo: \(error.localizedDescription)")
            errorHandler?(.captureError(error))
            return
        }
        
        Task { @MainActor in
            guard let photoData else { return }
            self.captureContinuation?.resume(returning: photoData)
            self.photoData = nil
        }
    }
}
