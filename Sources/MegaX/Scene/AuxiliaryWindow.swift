import SwiftUI
import Combine

/// A scene that presents its content below or above your controls.
///
/// The content of this scene is dynamically created inside your view using ``SwiftUICore/View/auxiliaryMenu(isPresented:windowID:content:)``.
@available(macOS 15.0, *)
@available(visionOS, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct AuxiliaryWindow: Scene {
    private var id: String
    @State private var targetContext: TargetContext
    
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.auxiliaryWindowBackgroundStyle) private var backgroundStyle
    @State private var dismissSubscription = Set<AnyCancellable>()
    @State private var windowProxy = WindowProxy(contentSize: .zero)
    @State private var menuSize = CGSize.zero
    @Namespace private var auxiliary
    
    /// Creates an auxiliary window with a unique window identifier.
    public init(id: String) {
        self.id = id
        _targetContext = State(wrappedValue: TargetContext.findTarget(id: id))
    }
    
    public var body: some Scene {
        Window("Auxiliary Window", id: id) {
            #if os(macOS)
            let showsAtBottom = windowProxy.windowOrigin.y + targetContext.frame.maxY + menuSize.height < (windowProxy.displayContext?.visibleRect.height ?? .infinity)
            #else
            let showsAtBottom = true
            #endif
            ZStack {
                Color.clear
                    .matchedGeometryEffect(
                        id: id,
                        in: auxiliary,
                        anchor: showsAtBottom ? .bottomLeading : .topLeading
                    )
                    .frame(
                        width: targetContext.frame.width,
                        height: targetContext.frame.height
                    )
                    #if os(macOS)
                    .position(
                        x: windowProxy.windowOrigin.x + targetContext.frame.midX,
                        y: windowProxy.windowOrigin.y + targetContext.frame.midY
                    )
                    #endif
                    
                targetContext.content
                    .background(backgroundStyle, in: .rect(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.secondary, lineWidth: 0.5)
                    }
                    .compositingGroup()
                    .shadow(color: .black.opacity(0.2), radius: 15, y: 10)
                    .padding(.vertical, 4)
                    .onGeometryChange(for: CGSize.self) { proxy in
                        proxy.size
                    } action: { newSize in
                        menuSize = newSize
                    }
                    .matchedGeometryEffect(
                        id: id,
                        in: auxiliary,
                        properties: .position,
                        anchor: showsAtBottom ? .topLeading : .bottomLeading,
                        isSource: false
                    )
                    .fixedSize()
            }
            #if os(macOS)
            .onAppear(perform: setupDismissNotification)
            .onChange(of: targetContext.keyWindow) {
                dismissSubscription = []
                setupDismissNotification()
            }
            #endif
        }
        .windowResizability(.contentSize)
        #if os(macOS)
        .windowStyle(.plain)
        .windowLevel(.floating)
        .defaultWindowPlacement { content, context in
            let visibleRect = context.defaultDisplay.visibleRect.size
            self.windowProxy = WindowProxy(
                contentSize: content.sizeThatFits(.unspecified),
                displayContext: context.defaultDisplay
            )
            return WindowPlacement(.zero, size: visibleRect)
        }
        .restorationBehavior(.disabled)
        .windowManagerRole(.associated)
        #endif
    }
    
    #if os(macOS)
    private func setupDismissNotification() {
        let notificationNames: [Notification.Name] = [
            NSWindow.didResignKeyNotification, // Losing focus
            NSWindow.willMoveNotification, // Moving
            NSWindow.willMiniaturizeNotification, // Minimizing
            NSWindow.willStartLiveResizeNotification, // Resizing, including full screen resizing.
            NSWindow.willCloseNotification // Closing
        ]
        notificationNames.forEach {
            NotificationCenter.default.publisher(for: $0, object: targetContext.keyWindow)
                .receive(on: DispatchQueue.main)
                .sink { _ in dismissSelf() }
                .store(in: &dismissSubscription)
        }
    }
    #endif
    
    private func dismissSelf() {
        dismissWindow(id: id)
        targetContext.dismiss()
    }
    
    private struct WindowProxy {
        var contentSize: CGSize
        var displayContext: DisplayProxy?
        var displaySize: CGSize? { displayContext?.bounds.size }
        
        var topMenuBarHeight: CGFloat { displayContext?.visibleRect.minY ?? .zero }

        #if os(macOS)
        var windowOrigin: CGPoint {
            let windowFrame = NSApplication.shared.keyWindow?.frame ?? .zero
            return CGPoint(
                x: windowFrame.minX,
                y: (displaySize?.height ?? .zero) - windowFrame.maxY - topMenuBarHeight
            )
        }
        #endif
    }
    
    @available(macOS 15.0, *)
    @available(visionOS, unavailable)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @Observable
    final class TargetContext {
        @MainActor static var targets = [TargetContext]()
        @MainActor static func findTarget(id: String) -> TargetContext {
            if let target = targets.first(where: { $0.id == id }) {
                return target
            }
            
            let newTarget = TargetContext(id: id)
            targets.append(newTarget)
            return newTarget
        }
        
        let id: String
        #if os(macOS)
        private(set) var keyWindow: NSWindow?
        #endif
        private(set) var frame: CGRect = .zero
        private(set) var content = AnyView(EmptyView())
        
        init(id: String) {
            #if os(macOS)
            self.keyWindow = NSApplication.shared.keyWindow
            #endif
            self.id = id
        }
        
        func updateMenu(frame: CGRect, contentView: some View) {
            #if os(macOS)
            self.keyWindow = NSApplication.shared.keyWindow
            #endif
            self.frame = frame
            self.content = AnyView(contentView)
        }
        
        func dismiss() {
            self.frame = .zero
            self.content = AnyView(EmptyView())
        }
    }
}

extension EnvironmentValues {
    @available(macOS 15.0, *)
    @available(visionOS, unavailable)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @Entry fileprivate var auxiliaryWindowBackgroundStyle: AnyShapeStyle = AnyShapeStyle(.windowBackground)
}

extension Scene {
    /// Sets the background style for auxiliary window.
    ///
    /// Default style is `.windowBackground`.
    @available(macOS 15.0, *)
    @available(visionOS, unavailable)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func auxiliaryWindowBackgroundStyle(_ style: some ShapeStyle) -> some Scene {
        environment(\.auxiliaryWindowBackgroundStyle, AnyShapeStyle(style))
    }
}
