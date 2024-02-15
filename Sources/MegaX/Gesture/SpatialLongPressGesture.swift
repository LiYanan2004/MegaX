import SwiftUI

extension View {
    /// Adds an action to perform when this view recognizes a long press gesture.
    /// - parameters:
    ///     - minimumDuration: The minimum duration of the long press that must elapse before the gesture succeeds.
    ///     - maximumDistance: The maximum distance that the fingers or cursor performing the long press can move before the gesture fails.
    ///     - coordinateSpace: The coordinate space in which to receive location values. Defaults to `SwiftUI/CoordinateSpace/local`.
    ///     - action: The action to perform when a long press is recognized.
    ///
    /// Use this modifier to perform specific action when user long pressed on a specfic area. The action closure receives the location of the interaction.
    public func onLongPressGesture(
        minimumDuration: Double = 0.5,
        maximumDistance: CGFloat = 10,
        coordinateSpace: some CoordinateSpaceProtocol = .local,
        perform action: @escaping (CGPoint) -> Void
    ) -> some View {
        gesture(
            SpatialLongPressGesture(
                minimumDuration: minimumDuration,
                maximumDistance: maximumDistance,
                coordinateSpace: coordinateSpace
            )
            .onChanged { point in
                guard let point else { return }
                action(point)
            }
        )
    }
}

public struct SpatialLongPressGesture<C: CoordinateSpaceProtocol>: Gesture {
    var minimumDuration: TimeInterval
    var maximumDistance: CGFloat
    var coordinateSpace: C
    
    @GestureState private var translation: CGSize?
    @State private var startLocation: CGPoint?
    @State private var toggleTriggerStateTask: Task<Void, Error>?
    @State private var shouldTrigger = false
    
    init(
        minimumDuration: TimeInterval = 0.5,
        maximumDistance: CGFloat = 10,
        coordinateSpace: C = .local
    ) {
        self.maximumDistance = maximumDistance
        self.minimumDuration = minimumDuration
        self.coordinateSpace = coordinateSpace
    }
    
    public typealias Value = CGPoint?
    public var body: AnyGesture<Value> {
        AnyGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: coordinateSpace)
                .updating($translation) { drag, translation, _ in
                    if translation == nil {
                        toggleTriggerStateTask?.cancel()
                        toggleTriggerStateTask = nil
                    }
                    
                    translation = drag.translation
                    
                    if toggleTriggerStateTask == nil {
                        toggleTriggerStateTask = Task {
                            try await Task.sleep(for: .seconds(minimumDuration))
                            
                            try Task.checkCancellation()
                            guard let translation = self.translation else { return }
                            let totalDistance = sqrt(pow(translation.width, 2) + pow(translation.height, 2))
                            guard totalDistance <= maximumDistance else { return }
                            
                            shouldTrigger = true
                        }
                    }
                }
                .map { shouldTrigger ? $0.location : nil }
        )
    }
}
