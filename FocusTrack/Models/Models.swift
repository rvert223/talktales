import Foundation

// MARK: - Child Profile

struct Child: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var age: Int
    let dateAdded: Date

    init(id: UUID = UUID(), name: String, age: Int, dateAdded: Date = Date()) {
        self.id = id
        self.name = name
        self.age = age
        self.dateAdded = dateAdded
    }

    var initials: String {
        let parts = name.split(separator: " ")
        return parts.prefix(2).compactMap { $0.first }.map(String.init).joined().uppercased()
    }
}

// MARK: - Exercise Type

enum ExerciseType: String, Codable, CaseIterable, Identifiable {
    case math    = "Number Challenge"
    case reading = "Story Time"
    case memory  = "Memory Match"
    case pattern = "Pattern Follow"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .math:    return "function"
        case .reading: return "book.fill"
        case .memory:  return "square.grid.2x2.fill"
        case .pattern: return "sparkles"
        }
    }

    var colorName: String {
        switch self {
        case .math:    return "blue"
        case .reading: return "green"
        case .memory:  return "purple"
        case .pattern: return "orange"
        }
    }

    var description: String {
        switch self {
        case .math:    return "Solve simple addition problems"
        case .reading: return "Read a short story and answer questions"
        case .memory:  return "Flip cards to find matching pairs"
        case .pattern: return "Watch and repeat the color sequence"
        }
    }

    /// Number of trackable tasks (answer submissions) per session
    var taskCount: Int {
        switch self {
        case .math:    return 10
        case .reading: return 5
        case .memory:  return 8   // 8 pairs to match
        case .pattern: return 6   // 6 rounds of increasing length
        }
    }

    var estimatedMinutes: Int {
        switch self {
        case .math:    return 5
        case .reading: return 7
        case .memory:  return 5
        case .pattern: return 4
        }
    }
}

// MARK: - Behavior Events

enum BehaviorEventType: String, Codable {
    case taskStarted
    case taskCompleted
    case taskAbandoned
    case answerSubmitted
    case incorrectAnswer
    case excessiveTouches   // more taps than expected on a single task
    case longPause          // response time well above average
    case impulsiveResponse  // very fast but wrong answer
}

struct BehaviorEvent: Identifiable, Codable {
    let id: UUID
    let type: BehaviorEventType
    let timestamp: Date
    let taskIndex: Int
    let responseTimeMs: Double?
    let isCorrect: Bool?
    let touchCount: Int?

    init(
        id: UUID = UUID(),
        type: BehaviorEventType,
        timestamp: Date = Date(),
        taskIndex: Int = 0,
        responseTimeMs: Double? = nil,
        isCorrect: Bool? = nil,
        touchCount: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.taskIndex = taskIndex
        self.responseTimeMs = responseTimeMs
        self.isCorrect = isCorrect
        self.touchCount = touchCount
    }
}

// MARK: - Session Metrics

struct SessionMetrics: Codable {
    let avgResponseTimeMs: Double
    let responseTimeStdDev: Double
    let completionRate: Double        // 0–1
    let accuracyRate: Double          // 0–1
    let excessiveTouchRate: Double    // 0–1
    let longPauseCount: Int
    let abandonedTasks: Int
    let impulsiveResponseCount: Int

    // Composite scores 0–100
    let attentionScore: Double
    let impulsivityScore: Double
    let completionScore: Double
    let focusScore: Double            // weighted composite

    let concernLevel: ConcernLevel
    let insights: [String]

    enum ConcernLevel: String, Codable, CaseIterable {
        case low      = "Typical"
        case moderate = "Monitor"
        case elevated = "Follow Up"

        var color: String {
            switch self {
            case .low:      return "green"
            case .moderate: return "orange"
            case .elevated: return "red"
            }
        }

        var icon: String {
            switch self {
            case .low:      return "checkmark.circle.fill"
            case .moderate: return "exclamationmark.circle.fill"
            case .elevated: return "exclamationmark.triangle.fill"
            }
        }

        var summary: String {
            switch self {
            case .low:
                return "Attention patterns look typical for this age."
            case .moderate:
                return "A few patterns are worth monitoring over time."
            case .elevated:
                return "Several patterns may benefit from a conversation with your child's pediatrician."
            }
        }
    }
}

// MARK: - Exercise Session

struct ExerciseSession: Identifiable, Codable {
    let id: UUID
    let childId: UUID
    let exerciseType: ExerciseType
    let startTime: Date
    var endTime: Date?
    var events: [BehaviorEvent]
    var metrics: SessionMetrics?
    let totalTasks: Int

    init(
        id: UUID = UUID(),
        childId: UUID,
        exerciseType: ExerciseType,
        startTime: Date = Date(),
        totalTasks: Int
    ) {
        self.id = id
        self.childId = childId
        self.exerciseType = exerciseType
        self.startTime = startTime
        self.totalTasks = totalTasks
        self.events = []
    }

    var durationSeconds: Double? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }

    var isComplete: Bool { endTime != nil && metrics != nil }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: startTime)
    }
}

// MARK: - Trend Report

struct TrendReport {
    let sessions: [ExerciseSession]
    let avgFocusScore: Double
    let avgAttentionScore: Double
    let avgImpulsivityScore: Double
    let trend: Trend

    enum Trend: String {
        case improving    = "Improving"
        case stable       = "Stable"
        case declining    = "Needs Attention"
        case insufficient = "More Sessions Needed"

        var systemImage: String {
            switch self {
            case .improving:    return "arrow.up.circle.fill"
            case .stable:       return "equal.circle.fill"
            case .declining:    return "arrow.down.circle.fill"
            case .insufficient: return "ellipsis.circle.fill"
            }
        }

        var color: String {
            switch self {
            case .improving:    return "green"
            case .stable:       return "blue"
            case .declining:    return "orange"
            case .insufficient: return "gray"
            }
        }
    }

    static var empty: TrendReport {
        TrendReport(sessions: [], avgFocusScore: 0, avgAttentionScore: 0,
                    avgImpulsivityScore: 0, trend: .insufficient)
    }
}
