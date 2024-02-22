import SwiftUI
import AVFoundation

struct CameraPreview: PlatformViewRepresentable {
    var session: AVCaptureSession
    let preview = CameraPreviewView()
    
    func makePlatformView(context: Context) -> CameraPreviewView {
        preview
    }
    
    func updatePlatformView(_ preview: CameraPreviewView, context: Context) {
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
#elseif os(macOS)
extension CameraPreview {
    class CameraPreviewView: NSView {
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
        
        init() {
            super.init(frame: .zero)
            self.layer = AVCaptureVideoPreviewLayer()
            wantsLayer = true
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
#endif
