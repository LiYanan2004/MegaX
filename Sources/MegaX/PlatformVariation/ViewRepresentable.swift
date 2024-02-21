import SwiftUI

#if os(macOS)
typealias PlatformView = NSView
typealias _PlatformViewRepresentable = NSViewRepresentable
#elseif os(iOS) || os(tvOS)
typealias PlatformView = UIView
typealias _PlatformViewRepresentable = UIViewRepresentable
#endif

protocol PlatformViewRepresentable: _PlatformViewRepresentable {
    associatedtype PlatformViewType: PlatformView
    func makePlatformView(context: Context) -> PlatformViewType
    func updatePlatformView(_ view: PlatformViewType, context: Context)
}

extension PlatformViewRepresentable {
    #if canImport(UIKit)
    func makeUIView(context: Context) -> PlatformViewType {
        makePlatformView(context: context)
    }

    func updateUIView(_ uiView: PlatformViewType, context: Context) {
        updatePlatformView(uiView, context: context)
    }

    #elseif canImport(AppKit)
    func makeNSView(context: Context) -> PlatformViewType {
        makePlatformView(context: context)
    }

    func updateNSView(_ nsView: PlatformViewType, context: Context) {
        updatePlatformView(nsView, context: context)
    }
    #endif
}

