//
//  CameraModel+Errors.swift
//  Separate
//
//  Created by LiYanan2004 on 2024/2/5.
//

import Foundation

extension CameraModel {
    enum DeviceError: Error {
        case deviceError, accessDenied
    }
}
