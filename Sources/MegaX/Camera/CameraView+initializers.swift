//
//  CameraView+initializers.swift
//  Separate
//
//  Created by LiYanan2004 on 2024/2/11.
//

import SwiftUI

extension CameraView where S == EmptyView {
    init(
        onFinishCapture: @escaping (Data) -> Void,
        onPermissionDenied: (() -> Void)? = nil,
        @ViewBuilder photoAlbum: () -> P
    ) {
        self.onFinishCapture = onFinishCapture
        self.onPermissionDenied = onPermissionDenied
        self.statusBar = EmptyView()
        self.photoAlbum = photoAlbum()
    }
}

extension CameraView where P == EmptyView {
    init(
        onFinishCapture: @escaping (Data) -> Void,
        onPermissionDenied: (() -> Void)? = nil,
        @ViewBuilder statusBar: () -> S
    ) {
        self.onFinishCapture = onFinishCapture
        self.onPermissionDenied = onPermissionDenied
        self.statusBar = statusBar()
        self.photoAlbum = EmptyView()
    }
}
