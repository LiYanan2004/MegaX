import SwiftUI

/// A button that supports Sendable, async action.
public struct AsyncButton<L: View, P: View>: View {
    var role: ButtonRole?
    var action: @Sendable () async -> Void
    @ViewBuilder var label: L
    @ViewBuilder var progress: P
    
    @State private var isProcessing = false
    
    /// Creates an Async Button.
    /// - Parameters:
    ///   - role: An optional semantic role that describes the button. A value of nil means that the button doesn’t have an assigned role.
    ///   - action: The sendable action to perform in an async environment when the user interacts with the button.
    ///   - label: A view that describes the purpose of the button’s action.
    ///   - progress: A progress view indicating the task is executing after user interacts with the button.
    init(
        role: ButtonRole? = nil,
        action: @escaping @Sendable () async -> Void,
        @ViewBuilder label: () -> L,
        @ViewBuilder progress: () -> P
    ) {
        self.role = role
        self.action = action
        self.label = label()
        self.progress = progress()
    }
    
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
    /// Creates an Async Button
    /// - Parameters:
    ///   - role: An optional semantic role that describes the button. A value of nil means that the button doesn’t have an assigned role.
    ///   - action: The sendable action to perform in an async environment when the user interacts with the button.
    ///   - label: A view that describes the purpose of the button’s action.
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
    /// Creates an Async Button.
    /// - Parameters:
    ///   - titleKey: The key for the button’s localized title, that describes the purpose of the button’s action.
    ///   - systemImage: The name of the image resource to lookup.
    ///   - role: An optional semantic role that describes the button. A value of nil means that the button doesn’t have an assigned role.
    ///   - action: The sendable action to perform in an async environment when the user interacts with the button.
    public init(
        _ titleKey: LocalizedStringKey,
        systemImage: String,
        role: ButtonRole? = nil,
        action: @escaping @Sendable () async -> Void
    ) {
        self.init(role: role, action: action) {
            Label(titleKey, systemImage: systemImage)
        } progress: {
            ProgressView()
        }
    }
    
    /// Creates an Async Button.
    /// - Parameters:
    ///   - title: A string that describes the purpose of the button’s action.
    ///   - systemImage: The name of the image resource to lookup.
    ///   - role: An optional semantic role that describes the button. A value of nil means that the button doesn’t have an assigned role.
    ///   - action: The sendable action to perform in an async environment when the user interacts with the button.
    public init<S: StringProtocol>(
        _ title: S,
        systemImage: String,
        role: ButtonRole? = nil,
        action: @escaping @Sendable () async -> Void
    ) {
        self.init(role: role, action: action) {
            Label(title, systemImage: systemImage)
        } progress: {
            ProgressView()
        }
    }
    
    /// Creates an Async Button.
    /// - Parameters:
    ///   - titleKey: The key for the button’s localized title, that describes the purpose of the button’s action.
    ///   - image: The image resource to lookup.
    ///   - role: An optional semantic role that describes the button. A value of nil means that the button doesn’t have an assigned role.
    ///   - action: The sendable action to perform in an async environment when the user interacts with the button.
    public init(
        _ titleKey: LocalizedStringKey,
        image: ImageResource,
        role: ButtonRole? = nil,
        action: @escaping @Sendable () async -> Void
    ) {
        self.init(role: role, action: action) {
            Label(titleKey, image: image)
        } progress: {
            ProgressView()
        }
    }
    
    /// Creates an Async Button.
    /// - Parameters:
    ///   - title: A string that describes the purpose of the button’s action.
    ///   - image: The image resource to lookup.
    ///   - role: An optional semantic role that describes the button. A value of nil means that the button doesn’t have an assigned role.
    ///   - action: The sendable action to perform in an async environment when the user interacts with the button.
    public init<S: StringProtocol>(
        _ title: S,
        image: ImageResource,
        role: ButtonRole? = nil,
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
