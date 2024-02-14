import SwiftUI

extension View {
    @ViewBuilder
    /// Adds conditional modifiers to your view.
    /// - parameters:
    ///     - condition: Determines whether to apply the modifications.
    ///     - modified: Modified version of the view if appropriate.
    ///     - elseModified: Modified version of the view when the condition returns false.
    /// - returns: A modified view based on the condition.
    ///
    /// Avoid using too complex condition rules that will be changed too often,
    /// because this will lead to unexpected behavior and poor performance.
    /// Use this modifier when there are platform specific adjustments, for example,
    /// adding paddings just for iPad environent.
    public func `if`(
        _ condition: @autoclosure () -> Bool,
        modified: (Self) -> some View,
        else elseModified: (Self) -> some View
    ) -> some View {
        if condition() {
            modified(self)
        } else {
            elseModified(self)
        }
    }
    
    @ViewBuilder
    /// Adds conditional modifiers to your view.
    /// - parameters:
    ///     - condition: Determines whether to apply the modifications.
    ///     - modified: Modified version of the view if appropriate.
    /// - returns: A modified or unmodified view based on the condition.
    ///
    /// Avoid using too complex condition rules that will be changed too often,
    /// because this will lead to unexpected behavior and poor performance.
    /// Use this modifier when there are platform specific adjustments, for example,
    /// adding paddings just for iPad environent.
    public func `if`(
        _ condition: @autoclosure () -> Bool,
        modified: (Self) -> some View
    ) -> some View {
        if condition() {
            modified(self)
        } else {
            self
        }
    }
}
