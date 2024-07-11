import SwiftUI
import AVFoundation

@available(macOS, unavailable)
public struct FlashLightIndicator: View {
    @Environment(Camera.self) private var camera
    @Environment(\.deviceType) private var deviceType
    @AppStorage("MEGAX_CAM_FLASH_MODE") private var userPreferedFlashMode: AVCaptureDevice.FlashMode = .auto
    
    private var accessibilityText: String {
        switch userPreferedFlashMode {
        case .off: "Flash Light off"
        case .on: "Flash Light on"
        case .auto: "Flash Light auto"
        @unknown default: "Flash light unknown"
        }
    }
    
    @State private var sceneMonitoringSetting = AVCapturePhotoSettings()
    @State private var flashSceneObserver: NSKeyValueObservation?
    @State private var isFlashScene = false
    @Namespace private var flashIndicator
    
    /// Create a flash indicator when the current capture device has flash.
    ///
    /// This view can automatically determine whether to show itself based on the current capture device capability.
    ///
    /// - note: This view must be installed inside a ``CameraView``.
    public init() { }
    
    public var body: some View {
        if camera.currentDeviceHasFlash {
            Button {
                userPreferedFlashMode = switch userPreferedFlashMode {
                case .off: .auto
                default: .off
                }
            } label: {
                Circle()
                    .strokeBorder(.secondary, lineWidth: 1.25)
                    .opacity(isFlashScene ? 0 : 1)
                    .background {
                        Circle()
                            .foregroundStyle(.yellow)
                            .opacity(isFlashScene ? 1 : 0)
                    }
                    .opacity(deviceType == .phone ? 1 : 0)
                    .overlay {
                        Label(accessibilityText, systemImage: "bolt.fill")
                            .foregroundStyle(isFlashScene ? .black : .white)
                            .font(.system(size: deviceType == .phone ? 16 : 20))
                    }
                    .mask {
                        ZStack {
                            Rectangle()
                            Capsule()
                                .frame(width: 4)
                                .padding(.vertical, -2)
                                .scaleEffect(y: userPreferedFlashMode == .off ? 1 : 0, anchor: .top)
                                .rotationEffect(.degrees(-45))
                                .blendMode(.destinationOut)
                        }
                    }
                    .overlay {
                        Rectangle()
                            .frame(width: 1.25)
                            .scaleEffect(y: userPreferedFlashMode == .off ? 1 : 0, anchor: .top)
                            .padding(.vertical, -2)
                            .rotationEffect(.degrees(-45))
                    }
                    .padding(deviceType == .pad ? 8 : 0)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(width: 28)
            .clipped()
            .buttonStyle(.responsive)
            .labelStyle(.iconOnly)
            .if(deviceType == .pad) { content in
                content
                    .background(
                        isFlashScene ? AnyShapeStyle(.yellow) : AnyShapeStyle(.black.tertiary),
                        in: .circle
                    )
            }
            .animation(.smooth, value: userPreferedFlashMode)
            .task(id: userPreferedFlashMode) {
                camera.flashMode = userPreferedFlashMode
                sceneMonitoringSetting.flashMode = userPreferedFlashMode
                camera.photoOutput.photoSettingsForSceneMonitoring = sceneMonitoringSetting
                flashSceneObserver = camera.photoOutput.observe(\.isFlashScene, options: .new) { _, change in
                    guard let isFlashScene = change.newValue else { return }
                    withAnimation(.smooth(duration: 0.2)) {
                        self.isFlashScene = isFlashScene
                    }
                }
            }
            .onChange(of: camera.flashMode) {
                userPreferedFlashMode = camera.flashMode
            }
        }
    }
}

#if os(iOS)
#Preview {
    CameraView { _ in
        
    } content: { _ in
        FlashLightIndicator()
    }
}
#endif
