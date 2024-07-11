import SwiftUI
import Observation
import AVFoundation
import OSLog

@Observable
@available(macOS, unavailable)
public final class Camera: NSObject {
    @ObservationIgnored internal let logger = Logger(subsystem: "MEGAX", category: "Camera")
    
    // MARK: Custom delegates & configurations
    @ObservationIgnored internal var errorHandler: ((CameraError) -> Void)?
    @ObservationIgnored internal var configuration = CameraCaptureConfiguration()
    @ObservationIgnored internal var captureContinuation: CheckedContinuation<Data, Never>?
    
    // MARK: UI states
    @MainActor internal var photoData: Data?
    internal(set) public var shutterDisabled = false
    internal(set) public var isBusyProcessing = false
    internal var dimCameraPreview = 0.0
    internal(set) public var interfaceRotationAngle = Double.zero
    
    // MARK: - Capture Session
    public enum SessionState: Sendable {
        case running, notRunning, committing
    }
    internal(set) public var sessionState: SessionState = .notRunning
    
    @ObservationIgnored let session = AVCaptureSession()
    @ObservationIgnored private var sessionQueue = DispatchQueue(label: "com.liyanan2004.megax.sessionQueue")
    @ObservationIgnored var videoDevice: AVCaptureDevice? { videoDeviceInput?.device }
    @ObservationIgnored var videoDeviceInput: AVCaptureDeviceInput!
    @ObservationIgnored var photoOutput = AVCapturePhotoOutput()
    
    // MARK: - Camera Experience
    @MainActor @ObservationIgnored lazy var cameraPreview: CameraPreview = {
        CameraPreview(session: session)
    }()
    @ObservationIgnored private var videoDeviceRotationCoordinator: AVCaptureDevice.RotationCoordinator!
    @ObservationIgnored private var videoRotationAngleForHorizonLevelPreviewObservation: NSKeyValueObservation?
    @ObservationIgnored private var videoRotationAngleForHorizonLevelCaptureObservation: NSKeyValueObservation?
    @ObservationIgnored private var sceneMonitoring: NSKeyValueObservation?
    @ObservationIgnored private var readinessCoordinator: AVCapturePhotoOutputReadinessCoordinator!
    
    // MARK: - Flash Light
    #if targetEnvironment(simulator)
    public var currentDeviceHasFlash: Bool { true } // Enable flash indicator for preview
    #else
    public var currentDeviceHasFlash: Bool { videoDevice?.hasFlash ?? false }
    #endif
    public var flashMode: AVCaptureDevice.FlashMode = .auto
    
    // TODO: Macro Control
    @ObservationIgnored private var activePrimaryConstituentDeviceObservation: NSKeyValueObservation?
    var activePrimaryConstituentDevice: AVCaptureDevice?
    @ObservationIgnored private var lensPositionObservation: NSKeyValueObservation?
    var macroControlVisible = false
    var autoSwitchToMacroLens = true {
        willSet {
            configureAutoLensSwitching()
        }
    }
    
    var grantedPermission: Bool {
        get async { await AVCaptureDevice.requestAccess(for: .video) }
    }
    
    public func startSession() {
        guard session.isRunning == false else { return }
        sessionQueue.async { [self] in
            configureSession()
            session.startRunning()
            Task { @MainActor in
                self.sessionState = .running
            }
        }
    }
    
    public func stopSession() {
        guard session.isRunning else { return }
        sessionQueue.async { [self] in
            session.stopRunning()
            Task { @MainActor in
                self.sessionState = .notRunning
            }
        }
    }
    
    func updateSession(with configuration: CameraCaptureConfiguration) {
        self.configuration = configuration
        sessionQueue.async { [self] in
            session.beginConfiguration()
            defer { session.commitConfiguration() }
            
            configureAutoLensSwitching()
            configurePhotoOutput()
            configureMultitaskAccess()
            configurePreferedStabilizationMode()
        }
    }

    // MARK: - Toggle Camera
    public enum CameraSide: Sendable {
        case front, back
        var position: AVCaptureDevice.Position {
            switch self {
            case .front: .front
            case .back: .back
            }
        }
        mutating func toggle() {
            self = self == .front ? .back : .front
        }
    }
    internal(set) public var cameraSide: CameraSide = .back
    internal var isFrontCamera: Bool { cameraSide == .front }
    internal var isBackCamera: Bool { cameraSide == .back }
    private var toggleCameraTask: Task<Void, Error>?
    
    func toggleCamera() {
        shutterDisabled = true
        sessionState = .committing
        dimCameraPreview = 0.2
        withAnimation(.easeInOut) {
            cameraSide.toggle()
        }
        toggleCameraTask?.cancel()
        toggleCameraTask = Task {
            try await Task.sleep(for: .seconds(0.3))
            try Task.checkCancellation()
            let videoDevice = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInTripleCamera, .builtInDualCamera, .builtInWideAngleCamera],
                mediaType: .video,
                position: cameraSide.position
            ).devices.first
            _toggleCamera(to: videoDevice)
        }
    }
    
    private func _toggleCamera(to videoDevice: AVCaptureDevice?) {
        sessionQueue.async { [self] in
            session.beginConfiguration()

            guard let videoDevice else {
                logger.error("Cannot find an appropriate video device input.")
                return
            }
            guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                logger.error("Failed to create device input.")
                return
            }
            
            session.removeInput(self.videoDeviceInput)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                // Auto-switching between lens
                configureAutoLensSwitching()
                
                // Set zoom for new device
                // Use main camera for rear camera(s)
                // Use 8MP by default for front camera
                setZoomFactor(
                    isBackCamera ? backCameraDefaultZoomFactor : frontCameraDefaultZoomFactor
                )
            } else {
                session.addInput(self.videoDeviceInput)
            }
            
            // Explicitly reconfigure photo output after acquiring a different device
            configurePhotoOutput()
            
            Task { @MainActor in
                createDeviceRotationCoordinator()
                // Pause the camera preview flow to make sure transition can be animated well
                self.cameraPreview.preview.videoPreviewLayer.connection?.isEnabled = false
                sessionQueue.async { [self] in
                    // Wait session configuration being committed
                    session.commitConfiguration()
                    
                    // Switch back to main thread to perform animation
                    Task { @MainActor in
                        // Fade out the old preview
                        withAnimation(.bouncy(duration: 0.3)) {
                            self.dimCameraPreview = 0.9
                        }
                    }
                    
                    Task { @MainActor in
                        // Resume preview connection in the middle of the dimming effect
                        try await Task.sleep(for: .seconds(0.15))
                        self.cameraPreview.preview.videoPreviewLayer.connection?.isEnabled = true
                        self.sessionState = .running
                        // Fade in the new preview with a spring animation
                        // to keep the animation velocity if necessary
                        withAnimation(.smooth(duration: 0.3)) {
                            self.dimCameraPreview = 0
                        }
                        shutterDisabled = false
                    }
                }
            }
        }
    }
    
    // MARK: - Zoom
    internal(set) var zoomFactor: CGFloat = 1
    internal(set) var backCameraOpticalZoomFactors: [CGFloat] = []
    internal(set) var backCameraDefaultZoomFactor: CGFloat = 1
    internal(set) var frontCameraDefaultZoomFactor: CGFloat = 1
    
    func setZoomFactor(
        _ zoomFactor: CGFloat,
        withRate rate: Float? = nil,
        animation: Animation? = .smooth(duration: 0.25)
    ) {
        configureCaptureDevice { device in
            if device.isRampingVideoZoom {
                device.cancelVideoZoomRamp()
            }
            
            if let rate {
                device.ramp(toVideoZoomFactor: zoomFactor, withRate: rate)
            } else {
                device.videoZoomFactor = zoomFactor
            }
            withAnimation(animation) {
                self.zoomFactor = zoomFactor
            }
        }
    }
    
    // MARK: - Focus
    var focusLocked = false
    
    func setManualFocus(pointOfInterst: CGPoint, focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode) {
        configureCaptureDevice { device in
            guard device.isFocusPointOfInterestSupported,
                  device.isExposurePointOfInterestSupported else {
                self.logger.warning("Current device doesn't support focusing or exposing point of interst.")
                return
            }
            device.focusPointOfInterest = pointOfInterst
            if device.isFocusModeSupported(focusMode) {
                device.focusMode = focusMode
            }
            
            device.setExposureTargetBias(Float.zero)
            device.exposurePointOfInterest = pointOfInterst
            if device.isExposureModeSupported(exposureMode) {
                device.exposureMode = exposureMode
            }
            
            let locked = focusMode == .locked || exposureMode == .locked
            // Enable `SubjectAreaChangeMonitoring` to reset focus at appropriate time
            device.isSubjectAreaChangeMonitoringEnabled = !locked
        }
    }
    
    // MARK: - Capture
    public func capturePhoto(completionHandler: @escaping (Data) -> Void) {
        #if targetEnvironment(simulator)
        return 
        #endif
        let photoSettings = createPhotoSettings()
        readinessCoordinator.startTrackingCaptureRequest(using: photoSettings)
        
        let videoRotationAngle = self.videoDeviceRotationCoordinator.videoRotationAngleForHorizonLevelCapture
        
        Task {
            let capturedPhotoData = await withCheckedContinuation { (continuation: CheckedContinuation<Data, Never>) in
                self.captureContinuation = continuation
            }
            completionHandler(capturedPhotoData)
        }
        
        sessionQueue.async { [self] in
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoRotationAngle = videoRotationAngle
            }
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
            readinessCoordinator.stopTrackingCaptureRequest(using: photoSettings.uniqueID)
        }
    }
    
    // MARK: - Helper Methods
    internal func configureCaptureDevice(_ configure: @escaping (_ device: AVCaptureDevice) throws -> Void) {
        guard let videoDevice else { return }
        do {
            try videoDevice.lockForConfiguration()
            try configure(videoDevice)
            videoDevice.unlockForConfiguration()
        } catch {
            logger.error("Cannot lock device for configuration: \(error.localizedDescription)")
        }
    }
    
    private func configureSession() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        session.sessionPreset = .photo
        
        // Video device input
        let videoDevice = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTripleCamera, .builtInDualCamera, .builtInDualWideCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        ).devices.first
        guard let videoDevice else {
            logger.error("Cannot find an appropriate video device input.")
            return
        }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            logger.error("Failed to create device input.")
            return
        }
        
        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
            self.videoDeviceInput = videoDeviceInput
            
            activePrimaryConstituentDevice = videoDevice.activePrimaryConstituent
            activePrimaryConstituentDeviceObservation = videoDevice.observe(\.activePrimaryConstituent, options: .new) { device, change in
                guard let activePrimaryConstituent = change.newValue else { return }
                self.activePrimaryConstituentDevice = activePrimaryConstituent
            }
            
            // Auto-switching between lens
            configureAutoLensSwitching()
            
            Task { @MainActor in
                createDeviceRotationCoordinator()
            }
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            configurePhotoOutput()
        }
        
        configureAvailableOpticalZoomsAndDefaultZoomsForCameras()
        
        let readinessCoordinator = AVCapturePhotoOutputReadinessCoordinator(photoOutput: photoOutput)
        DispatchQueue.main.async {
            self.readinessCoordinator = readinessCoordinator
            readinessCoordinator.delegate = self
        }
        
        configureMultitaskAccess()
        configurePreferedStabilizationMode()
    }
    
    private func configureAutoLensSwitching(enabled: Bool? = nil) {
        configureCaptureDevice { device in
            if let wideCameraZF = device.virtualDeviceSwitchOverVideoZoomFactors.first {
                self.setZoomFactor(CGFloat(truncating: wideCameraZF), animation: nil)
            }
            
            guard !device.fallbackPrimaryConstituentDevices.isEmpty else { return }
            let enabled = enabled ?? self.configuration.autoSwitchingLens
            device.setPrimaryConstituentDeviceSwitchingBehavior(
                enabled ? .auto : .locked,
                restrictedSwitchingBehaviorConditions: []
            )
        }
    }
    
    private func configurePhotoOutput() {        
        photoOutput.maxPhotoQualityPrioritization = .quality
        
        let supportedMaxDimensions = self.videoDeviceInput.device.activeFormat.supportedMaxPhotoDimensions
        photoOutput.maxPhotoDimensions = supportedMaxDimensions.last!
        
        if photoOutput.isAutoDeferredPhotoDeliverySupported {
            photoOutput.isAutoDeferredPhotoDeliveryEnabled = configuration.preferAutoDeferredPhotoDelivery
        }
        if photoOutput.isZeroShutterLagSupported {
            photoOutput.isZeroShutterLagEnabled = configuration.preferZeroShutterLag
        }
        if photoOutput.isResponsiveCaptureSupported {
            photoOutput.isResponsiveCaptureEnabled = configuration.preferResponsiveCapture
            if photoOutput.isFastCapturePrioritizationSupported {
                photoOutput.isFastCapturePrioritizationEnabled = configuration.preferFastCapturePrioritization
            }
        }
    }
    
    private func createPhotoSettings() -> AVCapturePhotoSettings {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.maxPhotoDimensions = self.photoOutput.maxPhotoDimensions
        if photoOutput.supportedFlashModes.contains(flashMode) {
            photoSettings.flashMode = flashMode
        } else {
            self.flashMode = .off
        }
        if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
        }
        
        return photoSettings
    }
    
    @MainActor 
    private func createDeviceRotationCoordinator() {
        let videoPreviewLayer = cameraPreview.preview.videoPreviewLayer
        videoDeviceRotationCoordinator = AVCaptureDevice.RotationCoordinator(device: videoDeviceInput.device, previewLayer: videoPreviewLayer)
        videoPreviewLayer.connection?.videoRotationAngle = videoDeviceRotationCoordinator.videoRotationAngleForHorizonLevelPreview
        self.setInterfaceRotationAngle(videoDeviceRotationCoordinator.videoRotationAngleForHorizonLevelCapture)
        
        videoRotationAngleForHorizonLevelPreviewObservation = videoDeviceRotationCoordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: .new) { _, change in
            guard let videoRotationAngleForHorizonLevelPreview = change.newValue else { return }
            videoPreviewLayer.connection?.videoRotationAngle = videoRotationAngleForHorizonLevelPreview
        }
        
        videoRotationAngleForHorizonLevelCaptureObservation = videoDeviceRotationCoordinator.observe(\.videoRotationAngleForHorizonLevelCapture, options: .new) { _, change in
            guard let videoRotationAngleForHorizonLevelCapture = change.newValue else { return }
            Task { @MainActor in
                self.setInterfaceRotationAngle(videoRotationAngleForHorizonLevelCapture)
            }
        }
    }
    
    @MainActor
    private func setInterfaceRotationAngle(_ videoRotationAngleForHorizonLevelCapture: CGFloat) {
        // We need to rotate element based on `videoRotationAngleForHorizonLevelCapture`
        var targetRotationAngle = Double(videoRotationAngleForHorizonLevelCapture)
        if targetRotationAngle >= 180 {
            targetRotationAngle -= 360
        }
        // Fix the angle to make portait be 0 degree
        targetRotationAngle = 90 - targetRotationAngle

        // Only rotate minimum degrees
        var currentRotationAngle = self.interfaceRotationAngle
        while currentRotationAngle > 360 || currentRotationAngle < 0 {
            let `operator` = currentRotationAngle > 0 ? -1.0 : 1.0
            currentRotationAngle += (`operator` * 360)
        }
        withAnimation(nil) {
            self.interfaceRotationAngle = currentRotationAngle
        }
        let rotationAngle = targetRotationAngle - currentRotationAngle
        let clockwiseRotationAngle: Double
        let antiClockwiseRotationAngle: Double
        
        if rotationAngle > 0 {
            clockwiseRotationAngle = abs(rotationAngle)
            antiClockwiseRotationAngle = abs(rotationAngle - 360)
        } else {
            clockwiseRotationAngle = abs(rotationAngle + 360)
            antiClockwiseRotationAngle = abs(rotationAngle)
        }
        withAnimation(.easeInOut(duration: 0.35)) {
            self.interfaceRotationAngle = if antiClockwiseRotationAngle < clockwiseRotationAngle {
                currentRotationAngle - antiClockwiseRotationAngle
            } else {
                currentRotationAngle + clockwiseRotationAngle
            }
        }
    }
    
    private func configureAvailableOpticalZoomsAndDefaultZoomsForCameras() {
        if let backCamera = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTripleCamera, .builtInDualCamera, .builtInDualWideCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        ).devices.first {
            var backCameraOpticalZoomFactors = backCamera
                .virtualDeviceSwitchOverVideoZoomFactors
                .map(CGFloat.init(truncating:))
            
            self.backCameraDefaultZoomFactor = backCameraOpticalZoomFactors.first ?? 1
            
            // This device features a 48MP camera, so we can add 2x as an optical zoom option.
            let support48MP = backCamera
                .constituentDevices
                .first(where: { $0.deviceType == .builtInWideAngleCamera })?
                .formats
                .flatMap(\.supportedMaxPhotoDimensions)
                .reversed() // It should be the last one, so reverse the array make searching faster
                .contains(where: { $0.width * $0.height > 48_000_000 })
            if support48MP ?? false {
                backCameraOpticalZoomFactors.insert(
                    (backCameraOpticalZoomFactors.first ?? 1) * 2,
                    at: backCameraOpticalZoomFactors.isEmpty ? 0 : 1
                )
            }
            self.backCameraOpticalZoomFactors = backCameraOpticalZoomFactors
        }
        
        if let frontCamera = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTripleCamera, .builtInDualCamera, .builtInDualWideCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .front
        ).devices.first {
            let support12MP = frontCamera
                .formats
                .flatMap(\.supportedMaxPhotoDimensions)
                .reversed() // It should be the last one, so reverse the array make searching faster
                .contains(where: { $0.width * $0.height > 12_000_000 })
            if support12MP {
                self.frontCameraDefaultZoomFactor = 1.3
            }
        }
    }
    
    private func configureMultitaskAccess() {
        if session.isMultitaskingCameraAccessSupported {
            session.isMultitaskingCameraAccessEnabled = configuration.captureWhenMultiTasking
        }
    }
    
    private func configurePreferedStabilizationMode() {
        #if os(iOS)
        for connection in session.connections {
            guard connection.isVideoStabilizationSupported else { continue }
            connection.preferredVideoStabilizationMode = configuration.stabilizationMode
        }
        #endif
    }
}
