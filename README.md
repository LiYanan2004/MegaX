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

An easy, fully customizable camera experience with the latest technology.

### Usage

Create a simple, customized camera view.

```swift
import MegaX
import SwiftUI

CameraView { _ in
    VStack {
        ViewFinder()
        ShutterButton { photo in
            // handle captured photo here.
        }
    }
}
```

Use built-in view that optimized for iOS devices.

```swift
import MegaX
import SwiftUI

CameraView { _ in
    SystemCameraExperience { photo in
        // handle captured photo here.
    }
}
```

A deeper customized camera view.

```swift
import MegaX
import SwiftUI

CameraView { _ in
    VStack(spacing: 40) {
        Rectangle()
            .fill(.clear)
            .overlay { ViewFinder() }
            .aspectRatio(1 / 1.414, contentMode: .fit)
            .clipShape(.rect(cornerRadius: 30))
        
        ShutterButton { photo in
            // Handle captured photo.
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .trailing) {
            CameraSwitcher()
                .padding(12)
                .background(.fill.tertiary, in: .circle)
        }
    }
    .padding(40)
    .background(.regularMaterial)
    .clipShape(.rect(cornerRadius: 50))
}
.frame(maxHeight: .infinity, alignment: .bottom)
.ignoresSafeArea()
```

For more information, check out full documentation and articles about CameraView.

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
