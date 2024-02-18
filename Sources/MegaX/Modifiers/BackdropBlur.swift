import SwiftUI

extension View {
    /// Adds a backdrop blur effect to any SwiftUI View natively.
    ///
    /// - parameters:
    ///     - transparency:  The transparency mode for the backing layer.
    ///     - smoothEdges: A set of edges to apply opaque to transparent mask to better fits the content.
    ///
    /// You can have more blur by using `.ultra`.
    public func backdropBlur(_ transparency: LayerTransparency = .normal, smoothEdges: Edge.Set = []) -> some View {
        modifier(BackdropBlurLayerModifier(transparency: transparency, smoothEdges: smoothEdges))
    }
}

/// Transparency level for the blur layer.
public enum LayerTransparency {
    /// Ultra transparent mode for more blur effect.
    case ultra
    /// Normal transparent mode.
    case normal
    
    fileprivate var blurRadius: Double {
        switch self {
        case .ultra: 5
        case .normal: 20
        }
    }
}

struct BackdropBlurLayerModifier: ViewModifier {
    var transparency: LayerTransparency
    var smoothEdges: Edge.Set
    
    func body(content: Content) -> some View {
        content.background {
            BackdropBlurLayer(transparency: transparency, smoothEdges: smoothEdges)
        }
    }
}

struct BackdropBlurLayer: View {
    var transparency: LayerTransparency
    var smoothEdges: Edge.Set
    
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .environment(\.colorScheme, .light)
            // Remove extra effects from system Material
            .grayscale(0.2)
            .contrast(1.62)
            .brightness(-0.254)
            .saturation(1.4)
            // Adds additional blur
            .blur(radius: transparency.blurRadius, opaque: true)
            .compositingGroup()
            // Smooth edges
            // This part of code is a little bit ugly.
            // But it just work. Fine.
            .mask {
                Canvas { context, size in
                    context.fill(Rectangle().path(in: CGRect(origin: .zero, size: size)), with: .color(.black))
                    context.blendMode = .sourceIn
                    
                    if smoothEdges.contains(.top) {
                        context.fill(Rectangle().path(in: CGRect(origin: .zero, size: CGSize(width: size.width, height: size.height / 5))), with: .linearGradient(Gradient(colors: [.clear, .black]), startPoint: CGPoint(x: size.width / 2, y: 0), endPoint: CGPoint(x: size.width / 2, y: size.height / 5)))
                    }
                    
                    if smoothEdges.contains(.bottom) {
                        context.fill(Rectangle().path(in: CGRect(origin: CGPoint(x: 0, y: size.height - size.height / 5), size: CGSize(width: size.width, height: size.height / 5))), with: .linearGradient(Gradient(colors: [.clear, .black]), startPoint: CGPoint(x: size.width / 2, y: size.height), endPoint: CGPoint(x: size.width / 2, y: size.height - size.height / 5)))
                    }
                    
                    if smoothEdges.contains(.leading) {
                        context.fill(Rectangle().path(in: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: size.width / 5, height: size.height))), with: .linearGradient(Gradient(colors: [.clear, .black]), startPoint: CGPoint(x: 0, y: size.height / 2), endPoint: CGPoint(x: size.width / 5, y: size.height / 2)))
                    }
                    
                    if smoothEdges.contains(.trailing) {
                        context.fill(Rectangle().path(in: CGRect(origin: CGPoint(x: size.width * 4 / 5, y: 0), size: CGSize(width: size.width / 5, height: size.height))), with: .linearGradient(Gradient(colors: [.clear, .black]), startPoint: CGPoint(x: size.width, y: size.height / 2), endPoint: CGPoint(x: size.width * 4 / 5, y: size.height / 2)))
                    }
                }
            }
            .ignoresSafeArea()
    }
}

#Preview {
    ZStack(alignment: .top) {
        ScrollView {
            Color.yellow
                .frame(width: 300, height: 300)
                .padding(.top, 30)
        }
        Text("14 Wed")
            .font(.headline)
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom)
            .backdropBlur(smoothEdges: .bottom)
    }
}
