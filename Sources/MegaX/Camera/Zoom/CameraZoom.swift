import SwiftUI

extension View {
    @available(macOS, unavailable)
    func cameraZoomFactor(_ zoomFactor: Binding<CGFloat>) -> some View {
        modifier(CameraZoom(zoomFactor: zoomFactor))
    }
}

@available(macOS, unavailable)
struct CameraZoom: ViewModifier {
    @Binding var zoomFactor: CGFloat
    @State var initialFactor: CGFloat?
    @Environment(CameraModel.self) private var model
    
    private var minZoomFactor: CGFloat {
        model.videoDevice?.minAvailableVideoZoomFactor ?? 1
    }
    private var maxZoomFactor: CGFloat {
        5.0 * CGFloat(truncating: model.videoDevice?.virtualDeviceSwitchOverVideoZoomFactors.last ?? 1)
    }
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(zoomGesture)
    }
    
    @MainActor
    var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if initialFactor == nil {
                    do {
                        try model.videoDevice?.lockForConfiguration()
                        self.initialFactor = model.videoDevice?.videoZoomFactor ?? 1
                    } catch {
                        print("Zoom gesture failed: \(error.localizedDescription)")
                    }
                }
                guard let initialFactor else { return }
                
                // Toggle between 12MP and 8MP for front camera
                if !model.isBackCamera {
                    model.setZoomFactor(
                        value.magnification > 1 ? 1.3 : 1,
                        withRate: 5000
                    )
                    return
                }
                
                let zoomFactor = min(max(minZoomFactor, initialFactor * (value.magnification)), maxZoomFactor)
                model.setZoomFactor(zoomFactor, animation: nil)
            }
            .onEnded { _ in
                model.videoDevice?.unlockForConfiguration()
                initialFactor = nil
            }
    }
}
