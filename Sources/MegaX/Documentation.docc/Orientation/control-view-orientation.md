# Control View Orientation

Learn how to coordinates with current device orientation.

## Overview

It enables developers to design and implement views tailored to specific device orientations, rather than relying on SwiftUI’s default dynamic orientation rendering. 

By providing precise control over how content is displayed in different orientations, it ensures a consistent and optimized user experience, regardless of how the device is held. 

This approach enhances the flexibility and customization capabilities for developers, allowing them to deliver more polished and orientation-specific user interfaces.

## Fixed Orientation View

Using ``FixedOrientationView`` to get automatic counter rotation that transits along side with the device to match the specific orientation.

For example, when using camera view, you'll notice that when you rotate your device, the preview gets rotated as well. To fix that, wrapping the preview layer inside ``FixedOrientationView``.

```swift
struct ExampleView: View {
    var body: some View {
        FixedOrientationView(matching: .portrait) {
            GradientBackgroundView()
                .overlay {
                    VStack(spacing: 20) {
                        Image(systemName: "iphone.gen3")
                            .font(.system(size: 64, weight: .thin))
                    }
                }
        }
        .ignoresSafeArea()
    }
}
```

![](fixed-orientation-view.jpeg)

> SwiftUI renders the view in target orientation regardless of current device orientation.

> important:
>
> ``FixedOrientationView`` should match the size of current window, ignoring or considering safe area, otherwise, the transition behavior may be odd and you'll receive a misuse warning log in the console.
> 
> Ignoring safe area by using `ignoresSafeArea(_:)` modifier on `FixedOrientationView`.

## Coordinate with Orientation

Obtain counter rotation angle that can be used to rotate the view to match target orientation via ``SwiftUICore/View/counterRotationAngle(_:matching:)``.

The target rotation angle calculation is `.zero - angle`.

There is a convenience modifier ``SwiftUICore/View/counterRotationEffect(matching:)`` that rotates the view with counter rotation angle. 

> tip: You can combine this modifier with ``FixedOrientationView``, where the whole view is orientation-fixed, but the individual view is auto-rotated.

```swift
struct ExampleView: View {
    @State private var angle = Angle.zero

    var body: some View {
        GradientBackgroundView()
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 20) {
                    Image(systemName: "iphone.gen3")
                        .font(.system(size: 64, weight: .thin))
                    Text("Rotation Angle: \(angle.degrees.formatted())")
                }
                .counterRotationAngle($angle, matching: .portrait)
                .rotationEffect(angle)
            }
    }
}
```
![](counter-rotation-angle.jpeg)

> SwiftUI renders the view in current orientation rather than matching specified orientation.
