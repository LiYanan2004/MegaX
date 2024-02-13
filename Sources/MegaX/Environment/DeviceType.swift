import SwiftUI

public enum DeviceType: Int, @unchecked Sendable {
    case phone
    case pad
    case tv
    case mac
    case vision
    case carPlay
    case unspecified
    
    init(userInterfaceIdom: UIUserInterfaceIdiom) {
        switch userInterfaceIdom {
        case .unspecified: self = .unspecified
        case .phone: self = .phone
        case .pad: self = .pad
        case .tv: self = .tv
        case .carPlay: self = .carPlay
        case .mac: self = .mac
        case .vision: self = .vision
        @unknown default: self = .unspecified
        }
    }
}

struct DeviceTypeEnvironmentKey: EnvironmentKey {
    #if os(macOS)
    static let defaultValue: DeviceType = .mac
    #elseif os(tvOS)
    static let defaultValue: DeviceType = .tv
    #elseif os(visionOS)
    static let defaultValue: DeviceType = .vision
    #else
    static let defaultValue: DeviceType = DeviceType(userInterfaceIdom: UIDevice.current.userInterfaceIdiom)
    #endif
}

extension EnvironmentValues {
    public var deviceType: DeviceType {
        get { self[DeviceTypeEnvironmentKey.self] }
    }
}
