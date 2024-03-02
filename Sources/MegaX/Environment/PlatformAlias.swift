//
//  PlatformAlias.swift
//
//
//  Created by tdt on 2024/3/2.
//

import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformViewRepresentable = UIViewRepresentable
typealias PlatformVisualEffectView = UIVisualEffectView
#elseif canImport(AppKit)
import AppKit
typealias PlatformViewRepresentable = NSViewRepresentable
typealias PlatformVisualEffectView = NSVisualEffectView
#endif
