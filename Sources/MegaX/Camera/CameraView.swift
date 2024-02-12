import SwiftUI
import AVFoundation

/// A system-like Camera view experience.
public struct CameraView<S: View, P: View>: View {
    @ViewBuilder var statusBar: (AVCaptureDevice) -> S
    @ViewBuilder var photoAlbum: P
    
    // MARK: Custom Delegate
    public var onFinishCapture: (Data) -> Void
    public var onPermissionDenied: (() -> Void)?

    // MARK: UI State
    @Environment(\._captureConfiguration) private var configuration
    @State var model = CameraModel()
    @State private var focusLocked = false
    @State private var toggleCameraTask: Task<Void, Error>?
    
    /// Creates a CameraView with customized status bar and photo album button.
    /// - Parameters:
    ///     - onFinishCapture: Completion callback when captured a photo.
    ///     - onPermissionDenied: Completion callback when user denied camera permission.
    ///     - statusBar: Customized status bar above camera preview.
    ///     - photoAlbum: Customized photo album button below camera preview, aligned with shutter button.
    ///
    /// When using CameraView, ``AppOrientationDelegate`` should be added to your `App` declaration via `@UIApplicationDelegateAdaptor` to get correct behavior.
    public init(
        onFinishCapture: @escaping (Data) -> Void,
        onPermissionDenied: (() -> Void)? = nil,
        @ViewBuilder statusBar: @escaping (AVCaptureDevice) -> S,
        @ViewBuilder photoAlbum: () -> P
    ) {
        self.onFinishCapture = onFinishCapture
        self.onPermissionDenied = onPermissionDenied
        self.statusBar = statusBar
        self.photoAlbum = photoAlbum()
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            Color.clear
                .frame(maxHeight: 32)
                .fixedSize()
                .overlay {
                    if let videoDevice = model.videoDevice {
                        statusBar(videoDevice)
                    }
                }
                .padding(.horizontal, 20)
            
            Text("AF/AE Locked")
                .font(.subheadline)
                .padding(4)
                .padding(.horizontal, 8)
                .background(.yellow, in: .rect(cornerRadius: 5))
                .foregroundStyle(.black)
                .opacity(focusLocked ? 1 : 0)
                .animation(.smooth, value: focusLocked)
            
            model.cameraPreview
                .blur(radius: model.sessionState == .running ? 0 : 15, opaque: true)
                #if targetEnvironment(simulator)
                .overlay {
                    Rectangle().fill(.fill)
                }
                #endif
                .cameraPreviewFlip(trigger: model.cameraSide)
                .rotation3DEffect(
                    .degrees(model.sessionState == .running && model.isFrontCamera ? 180 : 0),
                    axis: (x: 0.0, y: 1.0, z: 0.0),
                    perspective: 0
                )
                .cameraFocusable(focusLocked: $focusLocked)
                .cameraZoomFactor($model.zoomFactor)
                .opacity(1 - model.dimCameraPreview)
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .clipped()
                .layoutPriority(1)
                .overlay(alignment: .bottomLeading) {
                    if model.macroControlVisible {
                        Toggle(isOn: $model.autoSwitchToMacroLens) {
                            Image(systemName: "camera.macro")
                                .symbolVariant(.slash)
                        }
                        .toggleStyle(.button)
                        .buttonStyle(.shutter)
                        .padding(8)
                        .background(.black.opacity(0.5), in: .circle)
                        .padding(12)
                        .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                    }
                }
                .overlay(alignment: .bottom) {
                    CameraOpticalZoomOptionsBox().padding()
                }
                .overlay {
                    Rectangle()
                        .stroke(.secondary, lineWidth: 2)
                        .mask {
                            ZStack {
                                Rectangle()
                                    .frame(width: 28, height: 28)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                
                                Rectangle()
                                    .frame(width: 28, height: 28)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                
                                Rectangle()
                                    .frame(width: 28, height: 28)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                                
                                Rectangle()
                                    .frame(width: 28, height: 28)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            }
                        }
                }
            
            Text("Photo")
                .font(.subheadline)
                .foregroundStyle(.yellow)
               
            shutter
                .frame(maxWidth: .infinity)
                .overlay(alignment: .trailing) {
                    Button(
                        "Switch Camera",
                        systemImage: "arrow.triangle.2.circlepath",
                        action: toggleCameraButtonClicked
                    )
                    .labelStyle(.iconOnly)
                    .imageScale(.large)
                    .padding(12)
                    .background(.fill.tertiary, in: .circle)
                    .buttonStyle(.shutter)
                    .rotationEffect(.degrees(model.interfaceRotationAngle))
                }
                .overlay(alignment: .leading) {
                    photoAlbum
                        .rotationEffect(.degrees(model.interfaceRotationAngle))
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.bottom, 40)
        .deviceOrientation(.portrait)
        .environment(model)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black, ignoresSafeAreaEdges: .all)
        .environment(\.colorScheme, .dark)
        .task {
            guard await model.grantedPermission else {
                onPermissionDenied?()
                return
            }
            model.configuration = configuration
            model.didFinishCapture = onFinishCapture
            model.startSession()
        }
        .onChange(of: configuration) {
            model.updateSession(with: configuration)
        }
        .onDisappear(perform: model.stopSession)
    }
    
    private var shutter: some View {
        Button {
            model.capturePhoto()
        } label: {
            Circle()
                .fill(.white)
                .frame(width: 60, height: 60)
                .opacity(model.isBusyProcessing ? 0 : 1)
                .overlay {
                    ProgressView()
                        .progressViewStyle(.spinning)
                        .scaleEffect(3)
                        .foregroundStyle(.white)
                        .opacity(model.isBusyProcessing ? 1 : 0)
                }
        }
        .buttonStyle(.shutter)
        .background {
            Circle()
                .strokeBorder(.white, lineWidth: 4)
                .frame(width: 72, height: 72)
        }
        .disabled(model.shutterDisabled)
    }
    
    private func toggleCameraButtonClicked() {
        model.shutterDisabled = true
        model.sessionState = .committing
        model.dimCameraPreview = 0.2
        withAnimation(.easeInOut) {
            model.cameraSide.toggle()
        }
        toggleCameraTask?.cancel()
        toggleCameraTask = Task {
            try await Task.sleep(for: .seconds(0.3))
            try Task.checkCancellation()
            let videoDevice = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInTripleCamera, .builtInDualCamera, .builtInWideAngleCamera],
                mediaType: .video,
                position: model.cameraSide.position
            ).devices.first
            model.toggleCamera(to: videoDevice)
        }
    }
}

#Preview {
    CameraView { photoData in
        
    } statusBar: { _ in
        HStack {
            Image(systemName: "bolt.circle")
            Spacer()
            Image(systemName: "livephoto")
        }
        .imageScale(.large)
        .foregroundStyle(.white, .gray.opacity(0.5))
        .frame(maxWidth: .infinity)
    } photoAlbum: {
        RoundedRectangle(cornerRadius: 8)
            .foregroundStyle(.fill.tertiary)
            .aspectRatio(contentMode: .fit)
            .frame(height: 56)
    }
}
