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
} statusBar: { captureDevice in
    // Represent current camera state like torch mode etc
    HStack {
        Image(systemName: "bolt.circle")
        Spacer()
    }
    .imageScale(.large)
    .foregroundStyle(.white, .gray.opacity(0.5))
    .frame(maxWidth: .infinity)
} photoAlbum: {
    // A custom album button to display the lastest captured photo
    RoundedRectangle(cornerRadius: 8)
        .foregroundStyle(.fill.tertiary)
        .aspectRatio(contentMode: .fit)
        .frame(height: 56)
}
```

If you want to customize the Camera, the available modifiers are

- `autoDeferredPhotoDeliveryEnabled`

- `zeroShutterLagEnabled`

- `responsiveCaptureEnabled`
- `fastCapturePrioritizationEnabled`

- `autoSwitchingLensEnabled`
- `captureWhenMultiTaskingEnabled`
- `cameraStabilizationMode`