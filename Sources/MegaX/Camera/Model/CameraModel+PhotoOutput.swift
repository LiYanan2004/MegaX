//
//  CameraModel+PhotoOutput.swift
//  Separate
//
//  Created by LiYanan2004 on 2024/2/5.
//

import SwiftUI
import AVFoundation

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        // Fully dim the preview and show it back.
        dimCameraPreview = 1
        withAnimation(.smooth(duration: 0.25)) {
            dimCameraPreview = 0
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            print("There is an error when finishing processing photo: ", error)
            return
        }
        
        Task { @MainActor in
            self.photoData = photo.fileDataRepresentation()
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCapturingDeferredPhotoProxy deferredPhotoProxy: AVCaptureDeferredPhotoProxy?, error: Error?) {
        if let error = error {
            print("There is an error when finishing capturing deferred photo: ", error)
            return
        }
        
        Task { @MainActor in
            self.photoData = deferredPhotoProxy?.fileDataRepresentation()
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        Task { @MainActor in
            guard let photoData else { return }
            didFinishCapture?(photoData)
        }
    }
}
