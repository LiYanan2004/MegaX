# MegaX

MegaX, representing **M**odifiers, **E**lements, **G**raphical and **A**bstractions, is a powerful SwiftUI framework which offers a set of modifiers and components for SwiftUI.

MegaX comes with a set of Views and Modifiers I often use in my project. The goal of the package is to accelerate developement process.

MegaX is currently compatible with iOS 17 or later.

## AsyncButton

**AsyncButton** is a simple Button but with progress indicator and async action environment.

### Usage

```swift
AsyncButton("Download", systemName: "arrow.down.circle") {
    await download()
}
```

## CameraView

When you need capture photos, **CameraView** comes in.

**CameraView** is a system-like camera view with support for manual focus and exposure, zooming with gesture or with lens switcher.

It automatically handles element orientation, but need developers to add `AppOrientationDelegate` to the App declaration.

```swift
import SwiftUI
import MegaX

@main
struct MyCameraApp: App {
    // This is needed, or the orientation behavior may be wired.
    @UIApplicationDelegateAdaptor(AppOrientationDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            CameraView { photoCaptured in
                print("photoData: \(photoCaptured)")
            ｝
        }
    }
}
```

You can also add a custom status bar and a photo album button.

```swift
CameraView { photoData in
    print("Photo Captured")
} photoAlbum: {
    // A custom album button to display the lastest captured photo
    RoundedRectangle(cornerRadius: 8)
        .foregroundStyle(.fill.secondary)
        .aspectRatio(contentMode: .fit)
        .frame(height: 56)
}
```

If you want to customize the Camera, the available modifiers are

- `autoDeferredPhotoDeliveryEnabled`
- `zeroShutterLagEnabled`
- `responsiveCaptureEnabled`
- `fastCapturePrioritizationEnabled`
- `captureWhenMultiTaskingEnabled`
- `cameraStabilizationMode`

## Backdrop Blur

High performance backdrop blur layer with just one line of code.

```swift
YourView()
    .backdropBlur(smoothEdges: .bottom)
```

## Extensions for SwiftUI

### `if-else` modifier

Creating conditional modifier just like writing normal code.

But be careful when using this extension modifier because it might lead to poor performance and unexpected behavior.

Use this modifier **only when the condition value will not change through the view's lifecycle**, like using `DeviceType` to add platform specific adjustments.
