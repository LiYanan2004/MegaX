import SwiftUI

extension View {
    @ViewBuilder
    public func `if`(_ condition: @autoclosure () -> Bool, modified: (Self) -> some View) -> some View {
        if condition() {
            modified(self)
        } else {
            self
        }
    }
}
