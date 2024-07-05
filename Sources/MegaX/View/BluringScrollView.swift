import SwiftUI

/// A ScrollView with variable bluring effect applied to the top and bottom safe areas.
@available(iOS 18.0, macOS 15.0, tvOS 18.0, visionOS 2.0, *)
struct BluringScrollView<Content>: View where Content : View {
    var axes: Axis.Set
    var maxRadius: CGFloat
    var content: Content
    
    @State private var scrollGeometry = ScrollGeometry(contentOffset: .zero, contentSize: .zero, contentInsets: .init(), containerSize: .zero)
    private var visibleRegion: CGRect { scrollGeometry.visibleRect }
    private var safeArea: EdgeInsets { scrollGeometry.contentInsets }
    private var contentSize: CGSize { scrollGeometry.contentSize }
    
    /// Create a ScrollView with variable bluring effect applied to the top and bottom safe areas.
    ///
    /// - parameters:
    ///    - axes: The scroll view's scrollable axis. The default axis is the
    ///     vertical axis.
    ///    - maxRadius: The maximum blur radius of the variable blur effect.
    ///    - content: The view builder that creates the scrollable view.
    init(
        _ axes: Axis.Set = .vertical,
        maxRadius: CGFloat = 10,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.axes = axes
        self.maxRadius = maxRadius
        self.content = content()
    }
    
    var body: some View {
        ScrollView(axes) {
            content
        }
        .onScrollGeometryChange(for: ScrollGeometry.self) { geometry in
            geometry
        } action: { _, geometry in
            self.scrollGeometry = geometry
        }
        .overlay(alignment: .top) {
            content
                .offset(
                    x: -visibleRegion.origin.x,
                    y: -visibleRegion.origin.y
                )
                .frame(height: safeArea.top, alignment: .top)
                .variableBlur(maxRadius: maxRadius, mask: Image(size: CGSize(width: 100, height: 100)) { context in
                    let rect = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
                    let gradient = Gradient(colors: [.black, .clear])
                    context.fill(
                        Rectangle().path(in: rect),
                        with: .linearGradient(gradient, startPoint: CGPoint(x: 50, y: 0), endPoint: CGPoint(x: 50, y: 100))
                    )
                })
                .background()
                .ignoresSafeArea(.container, edges: .top)
                .allowsHitTesting(false)
                .animation(nil) { content in
                    content.opacity(visibleRegion.minY + safeArea.top > 0 ? 1 : 0)
                }
        }
        .overlay(alignment: .bottom) {
            content
                .offset(
                    x: -visibleRegion.origin.x,
                    y: -visibleRegion.origin.y
                )
                .offset(y: -visibleRegion.height + safeArea.bottom)
                .frame(height: safeArea.bottom, alignment: .top)
                .clipped()
                .variableBlur(maxRadius: maxRadius, id: visibleRegion, mask: Image(size: CGSize(width: 100, height: 100)) { context in
                    let rect = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
                    let gradient = Gradient(colors: [.black, .clear])
                    context.fill(
                        Rectangle().path(in: rect),
                        with: .linearGradient(gradient, startPoint: CGPoint(x: 50, y: 100), endPoint: CGPoint(x: 50, y: 0))
                    )
                })
                .background()
                .ignoresSafeArea(.container, edges: .bottom)
                .allowsHitTesting(false)
                .offset(y: safeArea.bottom) // Move to safe area
                .animation(nil) { content in
                    content.opacity(contentSize.height - visibleRegion.maxY + safeArea.bottom > 0 ? 1 : 0)
                }
        }
    }
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, visionOS 2.0, *)
#Preview {
    BluringScrollView(maxRadius: 20) {
        LazyVStack {
            ForEach(0..<1000, id: \.self) { _ in
                Text("Hello World.")
            }
        }
    }
    .safeAreaPadding(.top, 30)
}
