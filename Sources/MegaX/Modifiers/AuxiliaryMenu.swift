import SwiftUI

extension View {
    /// Presents a separate menu below or above the control in a independent window.
    ///
    /// Before adding this modifier, you need to add a ``AuxiliaryWindow`` to your app to response the request.
    ///
    /// - parameters:
    ///     - isPresented: A binding to a boolean that indicates whether the auxiliary window is opened.
    ///     - windowID: The ID of the ``AuxiliaryWindow`` you want to present the menu, used to coordinate the position of the menu.
    ///     - content: A closure that returns the content of the menu.
    ///
    /// > The menu presents only when `isPresented` is true and the control gets focused.
    /// >
    /// > The ``AuxiliaryWindow`` will be closed when host window moves, resizes or loses focus. In this situation, `isPresented` will be reset to false.
    ///
    /// This is useful when you want to build auto-completion by using a single state variable to control the visibility of the menu. **The menu shows below or above the currently focused control.**
    ///
    /// ```swift
    /// import SwiftUI
    /// import MegaX
    ///
    /// struct BookQueryView: View {
    ///     @State private var bookName = ""
    ///     @State private var author = ""
    ///
    ///     enum Field {
    ///         case book, author
    ///     }
    ///     @FocusState private var focusedField: Field?
    ///     @State private var showAutocompletion = false
    ///
    ///     var body: some View {
    ///         VStack(alignment: .leading) {
    ///             Text("Search Books")
    ///                 .font(.largeTitle)
    ///             TextField(
    ///                 "Search by Name",
    ///                 text: $bookName
    ///             )
    ///             .focused($focusedField, equals: .book)
    ///             .auxiliaryMenu(isPresented: $showAutocompletion, windowID: "suggestion") {
    ///                 AutoCompletionMenuForBookNameQuery()
    ///                     .safeAreaPadding(8)
    ///             }
    ///
    ///             TextField(
    ///                 "Search by Author",
    ///                 text: $author
    ///             )
    ///             .focused($focusedField, equals: .author)
    ///             .auxiliaryMenu(isPresented: $showAutocompletion, windowID: "suggestion") {
    ///                 AutoCompletionMenuForAuthorQuery()
    ///                     .safeAreaPadding(8)
    ///             }
    ///         }
    ///         .onChange(of: bookName + author) { _, newQueries in
    ///             show = !newQueries.isEmpty // Present the auxiliary window when query changes.
    ///         }
    ///         .onExitCommand { showAutocompletion = false } // Dismiss auxiliary window when user pressing the escape key.
    ///         .onSubmit { showAutocompletion = false } // Dismiss auxiliary window when user pressing the return key.
    ///     }
    /// }
    /// ```
    @available(macOS 15.0, *)
    @available(visionOS, unavailable)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func auxiliaryMenu(isPresented: Binding<Bool>, windowID: String, @ViewBuilder content: @escaping () -> some View) -> some View {
        modifier(AuxiliaryMenuModifier(isPresented: isPresented, windowID: windowID, content: content))
    }
}

@available(macOS 15.0, *)
@available(visionOS, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct AuxiliaryMenuModifier<AuxiliaryView: View>: ViewModifier {
    var isPresented: Binding<Bool>
    var windowID: String
    @ViewBuilder var content: AuxiliaryView
    
    @FocusState private var isFocused: Bool
    @State private var frame = CGRect.zero
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var targetContext: AuxiliaryWindow.TargetContext?
    @State private var updateTask: Task<Void, Error>?
    
    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { newFrame in
                self.frame = newFrame
            }
            .onChange(of: isFocused, updateMenu)
            .onChange(of: isPresented.wrappedValue, updateMenu)
            .onAppear {
                self.targetContext = AuxiliaryWindow.TargetContext
                    .findTarget(id: windowID)
            }
            .onChange(of: targetContext?.frame) { old, _ in
                // Ignore first change
                guard old != nil else { return }
                updatePresentedState()
            }
    }

    private func updateMenu() {
        updateTask?.cancel()
        updateTask = Task { @MainActor in
            try await Task.sleep(for: .milliseconds(10))
            let presentMenu = isFocused && isPresented.wrappedValue
            try Task.checkCancellation()
            if presentMenu {
                targetContext?.updateMenu(frame: self.frame, contentView: content)
                openWindow(id: windowID)
            } else if targetContext?.frame == frame {
                dismissWindow(id: windowID)
            }
        }
    }
    
    private func updatePresentedState() {
        if targetContext?.frame == .zero {
            isPresented.wrappedValue = false
        }
    }
}
