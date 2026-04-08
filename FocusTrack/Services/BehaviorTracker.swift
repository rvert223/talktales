import Foundation

/// Records real-time behavioral events during an exercise session.
/// Exercise views call this object to log every meaningful interaction.
final class BehaviorTracker: ObservableObject {

    // MARK: - Thresholds

    /// Response time above this (ms) is flagged as a long pause
    static let longPauseThresholdMs: Double = 8_000
    /// Response time below this (ms) on a wrong answer is flagged as impulsive
    static let impulsiveThresholdMs: Double = 600
    /// More taps than this on a single task is flagged as excessive
    static let excessiveTouchThreshold: Int = 4

    // MARK: - State

    @Published var currentTaskIndex: Int = 0
    @Published var isTracking: Bool = false

    private(set) var sessionId: UUID = UUID()
    private var childId: UUID = UUID()
    private var exerciseType: ExerciseType = .math
    private var totalTasks: Int = 0
    private var sessionStartTime: Date = Date()

    private var taskStartTime: Date?
    private var touchCount: Int = 0
    private var events: [BehaviorEvent] = []

    // MARK: - Session Lifecycle

    func startSession(childId: UUID, exerciseType: ExerciseType, totalTasks: Int) {
        self.childId = childId
        self.exerciseType = exerciseType
        self.totalTasks = totalTasks
        self.sessionId = UUID()
        self.sessionStartTime = Date()
        self.events = []
        self.currentTaskIndex = 0
        self.isTracking = true
        record(type: .taskStarted, taskIndex: 0)
    }

    // MARK: - Task Events

    func beginTask(index: Int) {
        currentTaskIndex = index
        taskStartTime = Date()
        touchCount = 0
        record(type: .taskStarted, taskIndex: index)
    }

    func recordTouch() {
        touchCount += 1
    }

    /// Call when the child submits an answer.
    /// - Returns: measured response time in milliseconds
    @discardableResult
    func submitAnswer(isCorrect: Bool) -> Double {
        let now = Date()
        let responseMs = taskStartTime.map { now.timeIntervalSince($0) * 1_000 } ?? 0

        // Secondary flags
        if responseMs > Self.longPauseThresholdMs {
            record(type: .longPause, taskIndex: currentTaskIndex, responseMs: responseMs)
        }
        if responseMs < Self.impulsiveThresholdMs && !isCorrect {
            record(type: .impulsiveResponse, taskIndex: currentTaskIndex, responseMs: responseMs, isCorrect: false)
        }
        if touchCount > Self.excessiveTouchThreshold {
            record(type: .excessiveTouches, taskIndex: currentTaskIndex, touchCount: touchCount)
        }

        // Primary submission event
        let primaryType: BehaviorEventType = isCorrect ? .answerSubmitted : .incorrectAnswer
        record(type: primaryType, taskIndex: currentTaskIndex,
               responseMs: responseMs, isCorrect: isCorrect, touchCount: touchCount)

        if isCorrect {
            record(type: .taskCompleted, taskIndex: currentTaskIndex, responseMs: responseMs)
        }

        return responseMs
    }

    func abandonTask() {
        record(type: .taskAbandoned, taskIndex: currentTaskIndex)
    }

    // MARK: - Finalise

    /// Closes the session and returns the populated ExerciseSession for analysis.
    func endSession() -> ExerciseSession {
        isTracking = false
        var session = ExerciseSession(
            id: sessionId,
            childId: childId,
            exerciseType: exerciseType,
            startTime: sessionStartTime,
            totalTasks: totalTasks
        )
        session.endTime = Date()
        session.events = events
        return session
    }

    // MARK: - Private

    private func record(
        type: BehaviorEventType,
        taskIndex: Int,
        responseMs: Double? = nil,
        isCorrect: Bool? = nil,
        touchCount: Int? = nil
    ) {
        events.append(BehaviorEvent(
            type: type,
            taskIndex: taskIndex,
            responseTimeMs: responseMs,
            isCorrect: isCorrect,
            touchCount: touchCount
        ))
    }
}
