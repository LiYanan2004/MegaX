import SwiftUI

#if os(macOS)
typealias PlatformView = NSView
typealias _PlatformViewRepresentable = NSViewRepresentable
#elseif os(iOS) || os(tvOS)
typealias PlatformView = UIView
typealias _PlatformViewRepresentable = UIViewRepresentable
#elseif os(watchOS)
typealias PlatformView = WKInterfaceObject
typealias _PlatformViewRepresentable = WKInterfaceObjectRepresentable
#endif

protocol PlatformViewRepresentable: _PlatformViewRepresentable {
    associatedtype PlatformViewType: PlatformView
    func makePlatformView(context: Context) -> PlatformViewType
    func updatePlatformView(_ view: PlatformViewType, context: Context)
}

extension PlatformViewRepresentable {
    #if os(iOS) || os(tvOS)
    func makeUIView(context: Context) -> PlatformViewType {
        makePlatformView(context: context)
    }

    func updateUIView(_ uiView: PlatformViewType, context: Context) {
        updatePlatformView(uiView, context: context)
    }
    #elseif os(macOS)
    func makeNSView(context: Context) -> PlatformViewType {
        makePlatformView(context: context)
    }

    func updateNSView(_ nsView: PlatformViewType, context: Context) {
        updatePlatformView(nsView, context: context)
    }
    #elseif os(watchOS)
    func makeWKInterfaceObject(context: Context) -> PlatformViewType {
        makePlatformView(context: context)
    }
    func updateWKInterfaceObject(_ wkInterfaceObject: PlatformViewType, context: Context) {
        updatePlatformView(wkInterfaceObject, context: context)
    }
    #endif
}

