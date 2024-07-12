import SwiftUI
import AVFoundation

class PhotoProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    private var continuation: CheckedContinuation<Data, Never>!
    private weak var camera: Camera?
    private var capturedPhoto: Data? {
        willSet {
            guard let newValue else { return }
            continuation.resume(returning: newValue)
        }
    }
    
    func setup(continuation: CheckedContinuation<Data, Never>, camera: Camera) {
        self.continuation = continuation
        self.camera = camera
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        // Fully dim the preview and show it back.
        camera?.dimCameraPreview = 1
        withAnimation(.smooth(duration: 0.25)) {
            camera?.dimCameraPreview = 0
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            camera?.logger.error("There is an error when finishing processing photo: \(error.localizedDescription)")
            camera?.errorHandler?(.captureError(error))
            return
        }
        
        capturedPhoto = photo.fileDataRepresentation()
    }
    
    #if os(iOS) && !targetEnvironment(macCatalyst)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCapturingDeferredPhotoProxy deferredPhotoProxy: AVCaptureDeferredPhotoProxy?, error: Error?) {
        if let error = error {
            camera?.logger.error("There is an error when finishing capturing deferred photo: \(error.localizedDescription)")
            camera?.errorHandler?(.captureError(error))
            return
        }
        
        capturedPhoto = deferredPhotoProxy?.fileDataRepresentation()
    }
    #endif
}
