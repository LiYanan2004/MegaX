//
//  ShutterButtonStyle.swift
//  Separate
//
//  Created by LiYanan2004 on 2024/2/5.
//

import SwiftUI

struct ShutterButtonStyle: PrimitiveButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @GestureState(resetTransaction: .init(animation: .smooth(duration: 0.2)))
    private var scale = CGFloat(1)
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(scale)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($scale) { _, scale, transaction in
                        guard isEnabled else { return }
                        transaction.animation = .snappy(duration: 0.3)
                        scale = 0.9
                    }
                    .onEnded { _ in
                        guard isEnabled else { return }
                        configuration.trigger()
                    }
            )
    }
}

extension PrimitiveButtonStyle where Self == ShutterButtonStyle {
    static var shutter: ShutterButtonStyle {
        ShutterButtonStyle()
    }
}

#Preview {
    Button {
        print("Shut")
    } label: {
        Circle()
            .frame(width: 60, height: 60)
    }
    .buttonStyle(.shutter)
    .background {
        Circle()
            .stroke(lineWidth: 4)
            .frame(width: 68, height: 68)
    }
}
