import SwiftUI

/// Container that hosts the active exercise, manages the BehaviorTracker,
/// and shows the result card when the session ends.
struct ExerciseSessionView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) private var dismiss

    let exerciseType: ExerciseType
    let child: Child

    @StateObject private var tracker = BehaviorTracker()
    @State private var completedSession: ExerciseSession?
    @State private var phase: Phase = .intro

    enum Phase { case intro, running, result }

    var body: some View {
        Group {
            switch phase {
            case .intro:
                IntroCard(type: exerciseType, child: child) {
                    tracker.startSession(childId: child.id,
                                        exerciseType: exerciseType,
                                        totalTasks: exerciseType.taskCount)
                    phase = .running
                } onDismiss: {
                    dismiss()
                }

            case .running:
                exerciseBody
                    .onDisappear { }   // exercise views call onFinish

            case .result:
                if let session = completedSession, let metrics = session.metrics {
                    SessionResultView(session: session, metrics: metrics, child: child) {
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled(phase == .running)
    }

    @ViewBuilder
    private var exerciseBody: some View {
        switch exerciseType {
        case .math:
            MathExerciseView(tracker: tracker, onFinish: handleFinish)
        case .reading:
            ReadingExerciseView(tracker: tracker, onFinish: handleFinish)
        case .memory:
            MemoryGameView(tracker: tracker, onFinish: handleFinish)
        case .pattern:
            PatternGameView(tracker: tracker, onFinish: handleFinish)
        }
    }

    private func handleFinish() {
        var session = tracker.endSession()
        let metrics = AttentionAnalyzer.analyze(session: session)
        session.metrics = metrics
        dataStore.saveSession(session)
        completedSession = session
        phase = .result
    }
}

// MARK: - Intro Card

private struct IntroCard: View {
    let type: ExerciseType
    let child: Child
    let onStart: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color(type.colorName).opacity(0.15))
                    .frame(width: 110, height: 110)
                Image(systemName: type.icon)
                    .font(.system(size: 44))
                    .foregroundColor(Color(type.colorName))
            }

            VStack(spacing: 10) {
                Text(type.rawValue)
                    .font(.largeTitle.bold())
                Text(type.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 6) {
                Label("\(type.taskCount) activities", systemImage: "list.bullet.rectangle")
                Label("About \(type.estimatedMinutes) minutes",  systemImage: "clock")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Spacer()

            VStack(spacing: 12) {
                Text("Hand the device to \(child.name)")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Button(action: onStart) {
                    Label("Start Activity", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(type.colorName))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 32)

                Button("Cancel", action: onDismiss)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 40)
        }
        .padding()
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - Session Result View

struct SessionResultView: View {
    let session: ExerciseSession
    let metrics: SessionMetrics
    let child: Child
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: metrics.concernLevel.icon)
                        .font(.system(size: 56))
                        .foregroundColor(Color(metrics.concernLevel.color))
                        .padding(.top, 32)
                    Text("Session Complete")
                        .font(.title2.bold())
                    Text(metrics.concernLevel.summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Score ring row
                HStack(spacing: 20) {
                    ScoreRing(label: "Focus",      score: metrics.focusScore,      color: .blue)
                    ScoreRing(label: "Attention",  score: metrics.attentionScore,  color: .green)
                    ScoreRing(label: "Impulsivity",score: metrics.impulsivityScore,color: .orange, invertColor: true)
                }
                .padding(.horizontal, 24)

                // Detail stats
                StatsGrid(metrics: metrics)
                    .padding(.horizontal)

                // Insights
                VStack(alignment: .leading, spacing: 10) {
                    Text("Observations")
                        .font(.headline)
                        .padding(.horizontal)
                    ForEach(metrics.insights, id: \.self) { insight in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text(insight)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }

                // Disclaimer
                Text("FocusTrack observations are educational only and not a clinical diagnosis. If you have concerns, speak with your child's paediatrician.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button("Done", action: onDone)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - Score Ring

private struct ScoreRing: View {
    let label: String
    let score: Double
    let color: Color
    var invertColor: Bool = false

    private var displayColor: Color {
        guard invertColor else { return color }
        if score < 30 { return .green }
        if score < 60 { return .orange }
        return .red
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(displayColor.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(score / 100))
                    .stroke(displayColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(String(format: "%.0f", score))
                    .font(.headline.bold())
            }
            .frame(width: 68, height: 68)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stats Grid

private struct StatsGrid: View {
    let metrics: SessionMetrics

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCell(icon: "checkmark.circle.fill", color: .green,
                     label: "Completion",
                     value: String(format: "%.0f%%", metrics.completionRate * 100))
            StatCell(icon: "target", color: .blue,
                     label: "Accuracy",
                     value: String(format: "%.0f%%", metrics.accuracyRate * 100))
            StatCell(icon: "timer", color: .purple,
                     label: "Avg Response",
                     value: String(format: "%.1fs", metrics.avgResponseTimeMs / 1_000))
            StatCell(icon: "exclamationmark.circle", color: .orange,
                     label: "Long Pauses",
                     value: "\(metrics.longPauseCount)")
        }
    }
}

private struct StatCell: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.headline.bold())
                Text(label).font(.caption).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
