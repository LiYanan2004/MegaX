import SwiftUI
import AVFoundation

struct FlashLightIndicator: View {
    @Environment(CameraModel.self) private var model
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
    
    var body: some View {
        if model.flashLightCapable {
            Button {
                userPreferedFlashMode = switch userPreferedFlashMode {
                case .off: .auto
                default: .off
                }
            } label: {
                Circle()
                    .stroke(.secondary, lineWidth: 1.25)
                    .padding(1.25)
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
                        HStack(spacing: -0.3) {
                            Rectangle()
                            Rectangle()
                                .frame(width: 4)
                                .scaleEffect(userPreferedFlashMode == .off ? 0 : 1, anchor: .bottom)
                            Rectangle()
                        }
                        .rotationEffect(.degrees(-45))
                    }
                    .overlay {
                        Rectangle()
                            .frame(width: 1.25)
                            .scaleEffect(userPreferedFlashMode == .off ? 1 : 0, anchor: .top)
                            .rotationEffect(.degrees(-45))
                    }
                    .padding(deviceType == .pad ? 8 : 0)
            }
            .frame(width: 28)
            .buttonStyle(.shutter)
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
                model.flashMode = userPreferedFlashMode
                sceneMonitoringSetting.flashMode = userPreferedFlashMode
                model.photoOutput.photoSettingsForSceneMonitoring = sceneMonitoringSetting
                flashSceneObserver = model.photoOutput.observe(\.isFlashScene, options: .new) { _, change in
                    guard let isFlashScene = change.newValue else { return }
                    withAnimation(.smooth(duration: 0.2)) {
                        self.isFlashScene = isFlashScene
                    }
                }
            }
            .onChange(of: model.flashMode) {
                userPreferedFlashMode = model.flashMode
            }
        }
    }
}

#Preview {
    FlashLightIndicator()
        .environment(CameraModel())
}
