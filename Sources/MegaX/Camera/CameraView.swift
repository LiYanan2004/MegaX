import SwiftUI
import AVFoundation

/// A system-like Camera view experience.
public struct CameraView<S: View, P: View>: View {
    @ViewBuilder var statusBar: (AVCaptureDevice) -> S
    @ViewBuilder var photoAlbum: P
    
    // MARK: Custom Delegate
    var onFinishCapture: (Data) -> Void
    var errorHandler: ((_ error: CameraError) -> Void)?

    // MARK: UI State
    @Environment(\._captureConfiguration) private var configuration
    @State var model = CameraModel()
    @State private var focusLocked = false
    @State private var toggleCameraTask: Task<Void, Error>?
    
    @Namespace private var CAM
    @Environment(\.deviceType) private var deviceType
    private var isPhone: Bool { deviceType == .phone }
    @MainActor private var portaitLocked: Bool {
        model.portaitLocked
    }
    
    /// Creates a CameraView with customized status bar and photo album button.
    /// - Parameters:
    ///     - onFinishCapture: Completion callback when captured a photo.
    ///     - errorHandler: Callback when error occurred.
    ///     - statusBar: Customized status bar above camera preview.
    ///     - photoAlbum: Customized photo album button below camera preview, aligned with shutter button.
    ///
    /// When using CameraView, ``AppOrientationDelegate`` should be added to your `App` declaration via `@UIApplicationDelegateAdaptor` to get correct behavior.
    public init(
        onFinishCapture: @escaping (Data) -> Void,
        errorHandler: ((CameraError) -> Void)? = nil,
        @ViewBuilder statusBar: @escaping (AVCaptureDevice) -> S,
        @ViewBuilder photoAlbum: () -> P
    ) {
        self.onFinishCapture = onFinishCapture
        self.errorHandler = errorHandler
        self.statusBar = statusBar
        self.photoAlbum = photoAlbum()
    }
    
    public var body: some View {
        Group {
            if isPhone {
                let topItems = VStack(spacing: 12) {
                    statusBarSection
                    AEAndAFLockedText
                }
                let captureItems = VStack(spacing: 12) {
                    preview
                        .aspectRatio(3 / 4, contentMode: .fit)
                    photoText
                        .padding(.vertical, 8)
                    shutter
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .trailing) {
                            cameraSwitchButton
                        }
                        .overlay(alignment: .leading) {
                            photoAlbum
                                .rotationEffect(.degrees(model.interfaceRotationAngle))
                        }
                        .padding(.horizontal, 20)
                }
                
                GeometryReader { proxy in
                    let fullHeight = proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
                    if fullHeight < 700 {
                        // For iPhone SE2
                        ZStack(alignment: .top) {
                            captureItems
                            topItems
                                .background(alignment: .top) {
                                    Color.black.opacity(0.5)
                                        .frame(height: 32)
                                }
                        }
                        .ignoresSafeArea()
                    } else {
                        VStack(spacing: 12) {
                            topItems
                            captureItems
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            } else {
                preview
                    .overlay(alignment: .top) {
                        AEAndAFLockedText.padding(32)
                    }
                    .overlay(alignment: .trailing) {
                        shutter
                            .padding(.vertical, 40)
                            .matchedGeometryEffect(id: "Shutter_top", in: CAM, properties: .position, anchor: .top)
                            .matchedGeometryEffect(id: "Shutter_bottom", in: CAM, properties: .position, anchor: .bottom)
                            .padding(.horizontal)
                    }
                    .overlay {
                        VStack(spacing: 0) {
                            statusBarSection
                                .buttonStyle(.shutter)
                            Color.clear.frame(height: 40)
                            cameraSwitchButton
                        }
                        .matchedGeometryEffect(id: "Shutter_top", in: CAM, properties: .position, anchor: .bottom, isSource: false)
                        
                        VStack(spacing: 40) {
                            photoAlbum
                            photoText
                        }
                        .matchedGeometryEffect(id: "Shutter_bottom", in: CAM, properties: .position, anchor: .top, isSource: false)
                    }
                    .ignoresSafeArea()
            }
        }
        .deviceOrientation(isPhone ? .portrait : .all)
        .environment(model)
        .sensoryFeedback(.selection, trigger: model.cameraSide)
        .sensoryFeedback(
            .selection,
            trigger: model.dimCameraPreview,
            condition: { $1 == 1 }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black, ignoresSafeAreaEdges: .all)
        .environment(\.colorScheme, .dark)
        .task {
            #if !targetEnvironment(simulator)
            guard await model.grantedPermission else {
                errorHandler?(.permissionDenied)
                return
            }
            model.errorHandler = errorHandler
            model.didFinishCapture = onFinishCapture
            model.configuration = configuration
            model.startSession()
            #endif
        }
        .onChange(of: configuration) {
            model.updateSession(with: configuration)
        }
        .onDisappear(perform: model.stopSession)
    }
    
    private var statusBarSection: some View {
        Color.clear
            .frame(height: 32)
            .overlay {
                if let videoDevice = model.videoDevice {
                    statusBar(videoDevice)            
                        .padding(.horizontal, 20)
                }
            }
    }
    
    private var AEAndAFLockedText: some View {
        Text("AF/AE Locked")
            .font(.subheadline)
            .padding(4)
            .padding(.horizontal, 8)
            .background(.yellow, in: .rect(cornerRadius: 5))
            .foregroundStyle(.black)
            .opacity(focusLocked ? 1 : 0)
            .animation(.smooth, value: focusLocked)
    }
    
    @MainActor
    private var preview: some View {
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
            .overlay(alignment: isPhone ? .bottom : .leading) {
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
                    .opacity(isPhone ? 1 : 0)
            }
    }
    
    private var shutter: some View {
        Rectangle()
            .fill(.clear)
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 72)
            .overlay {
                GeometryReader { proxy in
                    Button {
                        model.capturePhoto()
                    } label: {
                        Circle()
                            .fill(.white)
                            .opacity(model.isBusyProcessing ? 0 : 1)
                            .overlay {
                                ProgressView()
                                    .progressViewStyle(.spinning)
                                    .scaleEffect(proxy.size.width / 3.6)
                                    .foregroundStyle(.black)
                                    .opacity(model.isBusyProcessing ? 1 : 0)
                            }
                    }
                    .buttonStyle(.shutter)
                    .padding(6)
                    .background {
                        Circle()
                            .strokeBorder(.white, lineWidth: 4)
                    }
                    .disabled(model.shutterDisabled)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
    }
    
    @MainActor
    private var cameraSwitchButton: some View {
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
    
    private var photoText: some View {
        Text("Photo")
            .font(.subheadline)
            .foregroundStyle(.yellow)
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
        print("Captured photo data: \(photoData)")
    } errorHandler: { error in
        switch error {
        case .captureError(let error):
            print("Capture Error: \(error.localizedDescription)")
        case .permissionDenied:
            print("User denied camera permission")
        }
    } statusBar: { device in
        Button {
            
        } label: {
            Image(systemName: "bolt.circle")
                .symbolVariant(device.torchMode == .on ? .fill : .none)
                .foregroundStyle(.white, .gray.opacity(0.5))
        }
    } photoAlbum: {
        RoundedRectangle(cornerRadius: 8)
            .foregroundStyle(.fill.tertiary)
            .aspectRatio(contentMode: .fit)
            .frame(height: 56)
    }
}
