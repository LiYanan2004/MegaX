import SwiftUI

extension View {
    func variableBlur(maxRadius: CGFloat, mask: Image) -> some View {
        modifier(VariableBlurEffect(maxRadius: maxRadius, mask: mask))
    }
    
    func variableBlur(maxRadius: CGFloat, maskRenderer: @escaping (inout GraphicsContext, CGSize) -> Void) -> some View {
        modifier(VariableBlurEffectWithCustomRenderer(maxRadius: maxRadius, maskRenderer: maskRenderer))
    }
    
    internal func variableBlur(maxRadius: CGFloat, id: some Equatable, maskRenderer: @escaping (inout GraphicsContext, CGSize) -> Void) -> some View {
        modifier(VariableBlurEffectWithCustomRenderer(maxRadius: maxRadius, id: id, maskRenderer: maskRenderer))
    }
    
    internal func variableBlur(maxRadius: CGFloat, id: some Equatable, mask: Image) -> some View {
        modifier(VariableBlurEffect(maxRadius: maxRadius, mask: mask, identity: id))
    }
}

fileprivate struct VariableBlurEffectWithCustomRenderer<ID: Equatable>: ViewModifier {
    var maxRadius: CGFloat
    var id: ID
    let maskRenderer: (inout GraphicsContext, CGSize) -> Void
    
    @State private var size = CGSize(width: 100, height: 100)
    
    internal init(maxRadius: CGFloat, id: ID, maskRenderer: @escaping (inout GraphicsContext, CGSize) -> Void) {
        self.maxRadius = maxRadius
        self.id = id
        self.maskRenderer = maskRenderer
    }
    
    init(maxRadius: CGFloat, maskRenderer: @escaping (inout GraphicsContext, CGSize) -> Void) where ID == String {
        self.maxRadius = maxRadius
        self.id = "content"
        self.maskRenderer = maskRenderer
    }
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    Color.clear.task(id: proxy.size) {
                        self.size = proxy.size
                    }
                }
                .ignoresSafeArea()
            }
            .modifier(VariableBlurEffect(maxRadius: maxRadius, size: size, identity: id, renderer: maskRenderer))
    }
}

fileprivate struct VariableBlurEffect<ID: Equatable>: ViewModifier {
    var maxRadius: CGFloat
    var mask: Image
    var maskSize: CGSize?
    var maskRenderer: ((inout GraphicsContext) -> Void)?
    var identity: ID
    @State private var renderFlag = true
    @Environment(\.scenePhase) private var scenePhase
    var enabled: Bool { scenePhase != .background }
    
    fileprivate init(
        maxRadius: CGFloat,
        mask: Image,
        maskSize: CGSize? = nil,
        maskRenderer: ((inout GraphicsContext) -> Void)? = nil
    ) where ID == String {
        self.maxRadius = maxRadius
        self.mask = mask
        self.maskSize = maskSize
        self.maskRenderer = maskRenderer
        self.identity = "content"
    }
    
    fileprivate init(
        maxRadius: CGFloat,
        mask: Image,
        maskSize: CGSize? = nil,
        identity: ID,
        maskRenderer: ((inout GraphicsContext) -> Void)? = nil
    ) {
        self.maxRadius = maxRadius
        self.mask = mask
        self.maskSize = maskSize
        self.maskRenderer = maskRenderer
        self.identity = identity
    }
    
    fileprivate init(
        maxRadius: CGFloat,
        size: CGSize,
        identity: ID,
        renderer: @escaping (inout GraphicsContext, CGSize) -> Void
    ) {
        let image = Image(size: size) { context in
            renderer(&context, size)
        }
        self.init(maxRadius: maxRadius, mask: image, maskSize: size, identity: identity) { context in
            renderer(&context, size)
        }
    }
    
    func body(content: Content) -> some View {
        let mask = if let maskRenderer, let maskSize, enabled {
            Image(size: CGSize(width: 100, height: 100)) { context in
                let pixelCorrectImage = Image(size: maskSize) { innerContext in
                    maskRenderer(&innerContext)
                }
                context.draw(pixelCorrectImage.resizable(), in: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
            }
        } else {
            self.mask
        }
        let verticalBlurShader = ShaderLibrary.default.variableBlur(
            .boundingRect,
            .float(maxRadius),
            .float(10),
            .image(mask),
            .float(1) // Blur in vertical axis
        )
        let horizontalBlurShader = ShaderLibrary.default.variableBlur(
            .boundingRect,
            .float(maxRadius),
            .float(5),
            .image(mask),
            .float(0) // blur in horizontal axis
        )
        content
            .task(id: identity) {
                guard enabled else { return }
                guard maskRenderer != nil else { return }
                renderFlag.toggle()
            }
            .layerEffect(
                verticalBlurShader,
                maxSampleOffset: CGSize(width: renderFlag ? 0.01 : 0, height: 10)
            )
            .layerEffect(
                horizontalBlurShader,
                maxSampleOffset: CGSize(width: 5, height: renderFlag ? 0.01 : 0)
            )
    }
}
