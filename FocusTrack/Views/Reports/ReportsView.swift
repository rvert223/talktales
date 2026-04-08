import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedType: ExerciseType? = nil

    var child: Child? { dataStore.selectedChild }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ChildSelectorBar()
                        .padding(.horizontal)

                    if let child {
                        let all     = dataStore.completedSessions(for: child.id)
                        let trend   = AttentionAnalyzer.trend(for: all)

                        if all.isEmpty {
                            emptyState
                        } else {
                            // Trend summary
                            TrendSummaryCard(trend: trend)
                                .padding(.horizontal)

                            // Exercise type filter
                            typeFilter
                                .padding(.horizontal)

                            // Session list
                            let filtered = selectedType == nil
                                ? all
                                : all.filter { $0.exerciseType == selectedType }

                            if filtered.isEmpty {
                                Text("No sessions for this exercise type yet.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                // Score history chart
                                ScoreHistoryChart(sessions: Array(filtered.prefix(20)))
                                    .padding(.horizontal)

                                // Session rows
                                VStack(spacing: 10) {
                                    ForEach(filtered) { session in
                                        if let metrics = session.metrics {
                                            SessionHistoryRow(session: session, metrics: metrics)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    } else {
                        EmptyStateView(message: "Add a child profile in Settings.")
                            .padding(.top, 60)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.top, 8)
            }
            .navigationTitle("Reports")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 52))
                .foregroundColor(.secondary)
            Text("No sessions yet")
                .font(.title3.bold())
            Text("Complete at least one exercise\nto see reports here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    private var typeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", isSelected: selectedType == nil) {
                    selectedType = nil
                }
                ForEach(ExerciseType.allCases) { type in
                    FilterChip(label: type.rawValue, isSelected: selectedType == type) {
                        selectedType = (selectedType == type) ? nil : type
                    }
                }
            }
        }
    }
}

// MARK: - Trend Summary Card

private struct TrendSummaryCard: View {
    let trend: TrendReport

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Attention Trend")
                    .font(.headline)
                Spacer()
                TrendBadge(trend: trend.trend)
            }

            HStack(spacing: 20) {
                TrendStat(label: "Avg Focus",     value: String(format: "%.0f", trend.avgFocusScore),     color: .blue)
                TrendStat(label: "Attention",     value: String(format: "%.0f", trend.avgAttentionScore), color: .green)
                TrendStat(label: "Impulsivity",   value: String(format: "%.0f", trend.avgImpulsivityScore), color: .orange)
                TrendStat(label: "Sessions",      value: "\(trend.sessions.count)",                        color: .purple)
            }

            if trend.sessions.count < 3 {
                Label("Complete \(max(0, 3 - trend.sessions.count)) more sessions to see your trend.",
                      systemImage: "info.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

private struct TrendStat: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Score History Chart

private struct ScoreHistoryChart: View {
    let sessions: [ExerciseSession]

    private var scores: [Double] {
        sessions.reversed().compactMap(\.metrics?.focusScore)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Focus Score History")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            if scores.count > 1 {
                GeometryReader { geo in
                    ScoreLineCanvas(scores: scores, size: geo.size)
                }
                .frame(height: 120)
                .padding(.vertical, 4)

                HStack {
                    Text("Oldest").font(.caption2).foregroundColor(.secondary)
                    Spacer()
                    Text("Newest").font(.caption2).foregroundColor(.secondary)
                }
            } else {
                Text("Complete more sessions to see the chart.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 40)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

/// Drawing is extracted into its own View so the GeometryReader closure
/// stays a simple single-expression @ViewBuilder body.
private struct ScoreLineCanvas: View {
    let scores: [Double]
    let size: CGSize

    var body: some View {
        let w       = size.width
        let h       = size.height
        let count   = scores.count
        let minVal  = (scores.min() ?? 0) - 5
        let maxVal  = max((scores.max() ?? 100) + 5, minVal + 1)
        let range   = maxVal - minVal
        let step    = w / CGFloat(count - 1)

        ZStack {
            // Horizontal reference lines at 25, 50, 75
            ForEach([25.0, 50.0, 75.0], id: \.self) { level in
                Path { path in
                    let y = h - CGFloat((level - minVal) / range) * h
                    path.move(to: CGPoint(x: 0,  y: y))
                    path.addLine(to: CGPoint(x: w, y: y))
                }
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            }

            // Gradient fill under the line
            Path { path in
                for (i, score) in scores.enumerated() {
                    let x = CGFloat(i) * step
                    let y = h - CGFloat((score - minVal) / range) * h
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else       { path.addLine(to: CGPoint(x: x, y: y)) }
                }
                path.addLine(to: CGPoint(x: CGFloat(count - 1) * step, y: h))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.closeSubpath()
            }
            .fill(LinearGradient(
                colors: [Color.blue.opacity(0.25), Color.blue.opacity(0)],
                startPoint: .top, endPoint: .bottom
            ))

            // Line
            Path { path in
                for (i, score) in scores.enumerated() {
                    let x = CGFloat(i) * step
                    let y = h - CGFloat((score - minVal) / range) * h
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else       { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(Color.blue, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

            // Dots
            ForEach(scores.indices, id: \.self) { i in
                Circle()
                    .fill(Color.blue)
                    .frame(width: 7, height: 7)
                    .position(
                        x: CGFloat(i) * step,
                        y: h - CGFloat((scores[i] - minVal) / range) * h
                    )
            }
        }
    }
}

// MARK: - Session History Row

private struct SessionHistoryRow: View {
    let session: ExerciseSession
    let metrics: SessionMetrics

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(session.exerciseType.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: session.exerciseType.icon)
                    .foregroundColor(session.exerciseType.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(session.exerciseType.rawValue)
                    .font(.subheadline.weight(.semibold))
                Text(session.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "%.0f", metrics.focusScore))
                    .font(.headline.bold())
                    .foregroundColor(focusColor(metrics.focusScore))
                Text(metrics.concernLevel.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(metrics.concernLevel.color.opacity(0.15))
                    .foregroundColor(metrics.concernLevel.color)
                    .cornerRadius(6)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    private func focusColor(_ score: Double) -> Color {
        if score >= 68 { return .green }
        if score >= 45 { return .orange }
        return .red
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}
