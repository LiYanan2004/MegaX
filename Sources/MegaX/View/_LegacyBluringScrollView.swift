import SwiftUI

/// A legacy version of BluringScrollView, back-deployed to iOS 17 aligned release.
/// But not sure whether it works well on those devices.
@available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, *)
struct _LegacyBluringScrollView<Content>: View where Content : View {
    var axes: Axis.Set
    var maxRadius: CGFloat
    var content: Content
    
    @State private var visibleRegion: CGRect = .zero
    @State private var safeArea: EdgeInsets  = .init()
    @State private var contentSize: CGSize = .zero
    
    init(_ axes: Axis.Set = .vertical, maxRadius: CGFloat = 10, @ViewBuilder content: @escaping () -> Content) {
        self.axes = axes
        self.maxRadius = maxRadius
        self.content = content()
    }
    
    var body: some View {
        ScrollView(axes) {
            content
                .onGeometryChange(for: CGRect.self) { proxy in
                    let horizontalSafeArea = safeArea.leading + safeArea.trailing
                    let verticalSafeArea = safeArea.top + safeArea.bottom
                    return CGRect(
                        x: -proxy.frame(in: .global).origin.x,
                        y: -proxy.frame(in: .global).origin.y,
                        width: (proxy.bounds(of: .scrollView)?.size.width ?? 100) + horizontalSafeArea,
                        height: (proxy.bounds(of: .scrollView)?.size.height ?? 100) + verticalSafeArea
                    )
                } action: { rect in
                    self.visibleRegion = rect
                }
                .onGeometryChange(for: CGSize.self) { proxy in
                    proxy.size
                } action: { size in
                    self.contentSize = size
                }
        }
        .background {
            GeometryReader { container in
                Color.clear
                    .task(id: container.safeAreaInsets) {
                        let contentInsets = container.safeAreaInsets
                        safeArea = .init(
                            top: contentInsets.top,
                            leading: contentInsets.leading,
                            bottom: contentInsets.bottom,
                            trailing: contentInsets.trailing
                        )
                    }
            }
            .hidden()
            .accessibilityHidden(true)
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
