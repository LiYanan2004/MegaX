import SwiftUI
@preconcurrency import AVFoundation

public enum CapturedPhoto: Sendable {
    case photo(AVCapturePhoto)
    #if os(iOS) && !targetEnvironment(macCatalyst)
    case proxyPhoto(AVCaptureDeferredPhotoProxy)
    #endif
    
    public var underlyingPhotoObject: AVCapturePhoto {
        switch self {
        case .photo(let photo): photo
        #if os(iOS) && !targetEnvironment(macCatalyst)
        case .proxyPhoto(let photo): photo
        #endif
        }
    }
    
    public var dataRepresentation: Data? {
        switch self {
        case .photo(let photo): photo.fileDataRepresentation()
        #if os(iOS) && !targetEnvironment(macCatalyst)
        case .proxyPhoto(let photo): photo.fileDataRepresentation()
        #endif
        }
    }
    
    #if canImport(UIKit)
    public var uiimage: UIImage? {
        if let dataRepresentation {
            return UIImage(data: dataRepresentation)
        }
        return nil
    }
    #elseif canImport(AppKit)
    public var nsimage: NSImage? {
        if let dataRepresentation {
            return NSImage(data: dataRepresentation)
        }
        return nil
    }
    #endif
}

class PhotoProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    private var continuation: CheckedContinuation<CapturedPhoto, Never>!
    private weak var camera: Camera?
    private var capturedPhoto: CapturedPhoto? {
        willSet {
            guard let newValue else { return }
            continuation.resume(returning: newValue)
        }
    }
    
    func setup(continuation: CheckedContinuation<CapturedPhoto, Never>, camera: Camera) {
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
        
        capturedPhoto = .photo(photo)
    }
    
    #if os(iOS) && !targetEnvironment(macCatalyst)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCapturingDeferredPhotoProxy deferredPhotoProxy: AVCaptureDeferredPhotoProxy?, error: Error?) {
        if let error = error {
            camera?.logger.error("There is an error when finishing capturing deferred photo: \(error.localizedDescription)")
            camera?.errorHandler?(.captureError(error))
            return
        }
        
        if let deferredPhotoProxy {
            capturedPhoto = .photo(deferredPhotoProxy)
        }
    }
    #endif
}
