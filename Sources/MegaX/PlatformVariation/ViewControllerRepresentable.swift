import SwiftUI

#if os(macOS)
typealias PlatformViewController = NSViewController
typealias _PlatformViewControllerRepresentable = NSViewControllerRepresentable
#elseif os(iOS) || os(tvOS)
typealias PlatformViewController = UIViewController
typealias _PlatformViewControllerRepresentable = UIViewControllerRepresentable
#endif

#if !os(watchOS) && !os(visionOS)
protocol PlatformViewControllerRepresentable: _PlatformViewControllerRepresentable {
    associatedtype PlatformViewControllerType: PlatformViewController
    func makePlatformViewController(context: Context) -> PlatformViewControllerType
    func updatePlatformViewController(_ viewController: PlatformViewControllerType, context: Context)
}

extension PlatformViewControllerRepresentable {
    #if canImport(UIKit)
    func makeUIViewController(context: Context) -> PlatformViewControllerType {
        makePlatformViewController(context: context)
    }

    func updateUIViewController(_ uiViewController: PlatformViewControllerType, context: Context) {
        updatePlatformViewController(uiViewController, context: context)
    }

    #elseif canImport(AppKit)
    func makeNSViewController(context: Context) -> PlatformViewControllerType {
        makePlatformViewController(context: context)
    }

    func updateNSViewController(_ nsViewController: PlatformViewControllerType, context: Context) {
        updatePlatformViewController(nsViewController, context: context)
    }
    #endif
}
#endif
