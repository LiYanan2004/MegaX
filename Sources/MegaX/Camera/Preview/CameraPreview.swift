//
//  CameraPreview.swift
//  Separate
//
//  Created by LiYanan2004 on 2024/2/6.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    var session: AVCaptureSession
    let preview = CameraPreviewView()
    
    func makeUIView(context: Context) -> CameraPreviewView {
        preview
    }
    
    func updateUIView(_ preview: CameraPreviewView, context: Context) {
        DispatchQueue.main.async {
            preview.session = session
        }
    }
}

#if os(iOS)
extension CameraPreview {
    class CameraPreviewView: UIView {
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            guard let layer = layer as? AVCaptureVideoPreviewLayer else {
                fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
            }
            return layer
        }
        
        var session: AVCaptureSession? {
            get { videoPreviewLayer.session }
            set { videoPreviewLayer.session = newValue }
        }
        
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
    }
}
#endif
