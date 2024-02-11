//
//  AsyncButton.swift
//  Separate
//
//  Created by LiYanan2004 on 2024/2/5.
//

import SwiftUI

public struct AsyncButton<L: View, P: View>: View {
    var role: ButtonRole?
    var action: @Sendable () async -> Void
    @ViewBuilder var label: L
    @ViewBuilder var progress: P
    
    @State private var isProcessing = false
    
    public var body: some View {
        Button(role: role) {
            Task {
                withAnimation(nil) {
                    isProcessing = true
                }
                await action()
                withAnimation(nil) {
                    isProcessing = false
                }
            }
        } label: {
            label
                .opacity(isProcessing ? 0 : 1)
                .overlay {
                    if isProcessing {
                        progress
                    }
                }
        }
        .disabled(isProcessing)
    }
}

extension AsyncButton where P == ProgressView<EmptyView, EmptyView> {
    public init(
        role: ButtonRole? = nil,
        action: @escaping @Sendable () async -> Void,
        @ViewBuilder label: () -> L
    ) {
        self.init(role: role, action: action) {
            label()
        } progress: {
            ProgressView()
        }
    }
}

extension AsyncButton where L == Label<Text, Image>, P == ProgressView<EmptyView, EmptyView> {
    public init(
        role: ButtonRole? = nil,
        _ titleKey: LocalizedStringKey,
        systemImage: String,
        action: @escaping @Sendable () async -> Void
    ) {
        self.init(role: role, action: action) {
            Label(titleKey, systemImage: systemImage)
        } progress: {
            ProgressView()
        }
    }
    
    public init(
        role: ButtonRole? = nil,
        _ title: String,
        systemImage: String,
        action: @escaping @Sendable () async -> Void
    ) {
        self.init(role: role, action: action) {
            Label(title, systemImage: systemImage)
        } progress: {
            ProgressView()
        }
    }
    
    public init(
        role: ButtonRole? = nil,
        _ titleKey: LocalizedStringKey,
        image: String,
        action: @escaping @Sendable () async -> Void
    ) {
        self.init(role: role, action: action) {
            Label(titleKey, image: image)
        } progress: {
            ProgressView()
        }
    }
    
    public init(
        role: ButtonRole? = nil,
        _ title: String,
        image: String,
        action: @escaping @Sendable () async -> Void
    ) {
        self.init(role: role, action: action) {
            Label(title, image: image)
        } progress: {
            ProgressView()
        }
    }
}

#Preview {
    AsyncButton("Take Photo", systemImage: "camera") {
        try? await Task.sleep(for: .seconds(2))
    }
}
