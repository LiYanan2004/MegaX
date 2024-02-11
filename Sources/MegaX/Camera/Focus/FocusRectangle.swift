//
//  FocusRectangle.swift
//  Separate
//
//  Created by LiYanan2004 on 2024/2/7.
//

import SwiftUI
import AVFoundation

struct FocusRectangle: View {
    enum FocusMode: Sendable, Equatable {
        case autoFocus
        case manualFocus
        /// Represents the user has released the finger after locking
        case manualFocusLocked
        /// Represents the user still touching the screen or the camera will lock focus
        case manualFocusLocking
    }
    var focusMode: FocusMode
    
    @State private var currentPhase: FocusRectanglePhase?
    private var opacity: Double { (currentPhase ?? .invisibleLarge).opacity }
    private var scale: CGFloat { (currentPhase ?? .invisibleLarge).scale }
    
    @State private var focusTrackingTask: Task<Void, Error>?
    @Environment(CameraModel.self) private var model
    
    var body: some View {
        Rectangle()
            .stroke(.yellow, lineWidth: 1)
            .overlay {
                GeometryReader { proxy in
                    Rectangle()
                        .fill(.yellow)
                        .frame(width: 1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .mask {
                            VStack {
                                Color.black.frame(height: 5)
                                Spacer()
                                Color.black.frame(height: 5)
                            }
                        }
                }
            }
            .overlay {
                GeometryReader { proxy in
                    Rectangle()
                        .fill(.yellow)
                        .frame(height: 1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .mask {
                            HStack {
                                Color.black.frame(width: 5)
                                Spacer()
                                Color.black.frame(width: 5)
                            }
                        }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .environment(\.colorScheme, .dark)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                switch focusMode {
                case .autoFocus, .manualFocus:
                    withAnimation(.snappy(duration: 0.35)) {
                        currentPhase = .normal
                    } completion: {
                        withAnimation(.easeInOut(duration: 0.2).repeatForever()) {
                            currentPhase = .dimmed
                        }
                    }
                case .manualFocusLocking:
                    currentPhase = .invisibleLarge
                    withAnimation(.linear(duration: 0.2).repeatCount(2)) {
                        currentPhase = .visibleLarge
                    } completion: {
                        guard self.currentPhase != .normal else { return }
                        currentPhase = .visibleExtraLarge
                        withAnimation(.linear(duration: 0.2).repeatCount(2, autoreverses: false)) {
                            currentPhase = .visibleLarge
                        }
                    }
                case .manualFocusLocked: break
                }
                
                #if !targetEnvironment(simulator)
                focusTrackingTask = Task.detached(operation: trackFocusState)
                #endif
            }
            .onDisappear { focusTrackingTask?.cancel() }
            .onChange(of: focusMode) {
                focusTrackingTask?.cancel()
                withAnimation(.smooth(duration: 0.25)) {
                    currentPhase = .normal
                }
            }
    }
    
    @Sendable private func trackFocusState() async {
        defer { updateFocusRectangle() }
        
        #if targetEnvironment(simulator)
        try? await Task.sleep(for: .seconds(2))
        #else
        // Get current capure device
        var device: AVCaptureDevice?
        model.configureCaptureDevice { captureDevice in
            device = captureDevice
        }
        guard let device else { return }
        
        var lensPosition = device.lensPosition
        let timeout = 1000 // Timeout for stopping finding a focus if we cannot
        var waitingTime = 0 // Time(ms) elapse since now based on `Task.sleep`
       
        // Determine whether the camera is now focusing
        while device.lensPosition == lensPosition {
            guard !Task.isCancelled else { return }
            guard waitingTime <= timeout else { return }
            // If current lensPosition equals to the previous one,
            // it means camera is not start focusing.
            // Wait a short period of time.
            try? await Task.sleep(for: .milliseconds(10))
            waitingTime += 10
        }
        
        let threshold = 10 // The threshold to determine whether the focus has been adjusted
        var count = 0 // Count for same value.
        lensPosition = device.lensPosition
            
        // Determine whether the camera has finished focusing
        while count <= threshold {
            guard !Task.isCancelled else { return }
            if device.lensPosition == lensPosition {
                count += 1
            } else {
                lensPosition = device.lensPosition
                count = 0
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
        #endif
    }
    
    private func updateFocusRectangle() {
        guard !Task.isCancelled else { return }
        guard focusMode == .manualFocus else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            currentPhase = .normal
        } completion: {
            guard focusMode == .manualFocus else { return }
            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentPhase = .idle
                }
            }
        }
    }
}

struct FocusRectanglePhase: Equatable {
    var opacity: Double
    var scale: CGFloat

    static let visibleExtraLarge = FocusRectanglePhase(opacity: 1, scale: 2)
    static let visibleLarge = FocusRectanglePhase(opacity: 1, scale: 1.5)
    static let dimmedLarge = FocusRectanglePhase(opacity: 0.5, scale: 1.5)
    static let invisibleLarge = FocusRectanglePhase(opacity: 0, scale: 1.5)
    static let normal = FocusRectanglePhase(opacity: 1, scale: 1)
    static let dimmed = FocusRectanglePhase(opacity: 0.5, scale: 1)
    static let idle = FocusRectanglePhase(opacity: 0.3, scale: 1)
}

#Preview {
    FocusRectangle(focusMode: .manualFocusLocking)
        .frame(width: 100, height: 100)
        .preferredColorScheme(.dark)
        .environment(CameraModel())
}
