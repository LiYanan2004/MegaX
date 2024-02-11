//
//  CameraCaptureConfiguration+SwiftUI.swift
//  Separate
//
//  Created by LiYanan2004 on 2024/2/11.
//

import SwiftUI

struct CameraCaptureConfigurationKey: EnvironmentKey {
    static var defaultValue = CameraCaptureConfiguration()
}

extension EnvironmentValues {
    var _captureConfiguration: CameraCaptureConfiguration {
        get { self[CameraCaptureConfigurationKey.self] }
        set { self[CameraCaptureConfigurationKey.self] = newValue }
    }
}
