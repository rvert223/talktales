import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showExercisePicker = false

    var child: Child? { dataStore.selectedChild }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Child selector
                    ChildSelectorBar()
                        .padding(.horizontal)

                    if let child {
                        let recent = dataStore.recentSessions(for: child.id, limit: 5)
                        let trend  = AttentionAnalyzer.trend(for: recent)

                        // Hero score card
                        FocusScoreCard(trend: trend, child: child)
                            .padding(.horizontal)

                        // Latest session summary
                        if let latest = recent.first, let metrics = latest.metrics {
                            LatestSessionCard(session: latest, metrics: metrics)
                                .padding(.horizontal)
                        }

                        // Quick stats row
                        if !recent.isEmpty {
                            QuickStatsRow(sessions: recent)
                                .padding(.horizontal)
                        }

                        // Quick start
                        NavigationLink(destination: ExerciseListView()) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                Text("Start an Exercise")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(14)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal)

                    } else {
                        EmptyStateView(message: "No child profile selected.\nAdd one in Settings.")
                    }

                    Spacer(minLength: 20)
                }
                .padding(.top, 8)
            }
            .navigationTitle("FocusTrack")
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Child Selector Bar

struct ChildSelectorBar: View {
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        if dataStore.children.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(dataStore.children) { child in
                        ChildChip(child: child,
                                  isSelected: child.id == dataStore.selectedChildId)
                            .onTapGesture { dataStore.selectedChildId = child.id }
                    }
                }
            }
        }
    }
}

private struct ChildChip: View {
    let child: Child
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            InitialsAvatar(initials: child.initials, size: 28)
            Text(child.name).font(.subheadline.weight(isSelected ? .semibold : .regular))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
        .foregroundColor(isSelected ? .white : .primary)
        .cornerRadius(20)
    }
}

// MARK: - Focus Score Card

private struct FocusScoreCard: View {
    let trend: TrendReport
    let child: Child

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Focus Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if trend.sessions.isEmpty {
                        Text("No sessions yet")
                            .font(.title2.bold())
                    } else {
                        Text(String(format: "%.0f", trend.avgFocusScore))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(scoreColor(trend.avgFocusScore))
                        + Text(" / 100")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                TrendBadge(trend: trend.trend)
            }

            if !trend.sessions.isEmpty {
                MiniSparkline(scores: trend.sessions.compactMap(\.metrics?.focusScore).reversed())
                    .frame(height: 36)
            } else {
                Text("Complete 2+ sessions to see your trend.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 68 { return .green }
        if score >= 45 { return .orange }
        return .red
    }
}

// MARK: - Latest Session Card

private struct LatestSessionCard: View {
    let session: ExerciseSession
    let metrics: SessionMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Last Session", systemImage: "clock")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text(session.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                MetricPill(label: "Exercise",
                           value: session.exerciseType.rawValue,
                           color: .blue)
                MetricPill(label: "Status",
                           value: metrics.concernLevel.rawValue,
                           color: Color(metrics.concernLevel.color))
                MetricPill(label: "Focus",
                           value: String(format: "%.0f", metrics.focusScore),
                           color: .purple)
            }

            if let insight = metrics.insights.first {
                Text(insight)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Quick Stats Row

private struct QuickStatsRow: View {
    let sessions: [ExerciseSession]

    private var avgCompletion: Double {
        let rates = sessions.compactMap { $0.metrics?.completionRate }
        guard !rates.isEmpty else { return 0 }
        return rates.reduce(0, +) / Double(rates.count)
    }

    private var avgAccuracy: Double {
        let rates = sessions.compactMap { $0.metrics?.accuracyRate }
        guard !rates.isEmpty else { return 0 }
        return rates.reduce(0, +) / Double(rates.count)
    }

    var body: some View {
        HStack(spacing: 12) {
            StatBox(title: "Sessions", value: "\(sessions.count)", icon: "checkmark.circle", color: .blue)
            StatBox(title: "Completion", value: String(format: "%.0f%%", avgCompletion * 100), icon: "flag.fill", color: .green)
            StatBox(title: "Accuracy", value: String(format: "%.0f%%", avgAccuracy * 100), icon: "target", color: .orange)
        }
    }
}

private struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.headline.bold())
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

// MARK: - Shared Helpers

struct TrendBadge: View {
    let trend: TrendReport.Trend

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend.systemImage)
            Text(trend.rawValue).font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(trend.color).opacity(0.15))
        .foregroundColor(Color(trend.color))
        .cornerRadius(20)
    }
}

struct MetricPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.caption.bold()).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct InitialsAvatar: View {
    let initials: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(Color.blue.opacity(0.2))
            Text(initials)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(.blue)
        }
        .frame(width: size, height: size)
    }
}

struct EmptyStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 52))
                .foregroundColor(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

/// Tiny sparkline drawn with Canvas
struct MiniSparkline: View {
    let scores: [Double]   // chronological order (oldest → newest)

    var body: some View {
        Canvas { ctx, size in
            guard scores.count > 1 else { return }
            let min = scores.min() ?? 0
            let max = max((scores.max() ?? 100), min + 1)
            let step = size.width / CGFloat(scores.count - 1)

            var path = Path()
            for (i, score) in scores.enumerated() {
                let x = CGFloat(i) * step
                let y = size.height - CGFloat((score - min) / (max - min)) * size.height
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else       { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            ctx.stroke(path, with: .color(.blue), lineWidth: 2)
        }
    }
}
