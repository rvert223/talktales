import Foundation

/// Pure-function analysis engine.
/// Consumes a completed ExerciseSession and produces SessionMetrics
/// plus a TrendReport across multiple sessions.
enum AttentionAnalyzer {

    // MARK: - Single-Session Analysis

    static func analyze(session: ExerciseSession) -> SessionMetrics {
        let events = session.events

        // ── Response times ──────────────────────────────────────────────
        let submittedEvents = events.filter {
            $0.type == .answerSubmitted || $0.type == .incorrectAnswer
        }
        let responseTimes = submittedEvents.compactMap(\.responseTimeMs).filter { $0 > 0 }
        let avgResponse   = mean(responseTimes)
        let stdDev        = standardDeviation(responseTimes, mean: avgResponse)

        // ── Completion & accuracy ────────────────────────────────────────
        let completedCount  = events.filter { $0.type == .taskCompleted }.count
        let abandonedCount  = events.filter { $0.type == .taskAbandoned }.count
        let completionRate  = session.totalTasks > 0
            ? Double(completedCount) / Double(session.totalTasks) : 0
        let correctCount    = submittedEvents.filter { $0.isCorrect == true }.count
        let accuracyRate    = submittedEvents.isEmpty ? 0
            : Double(correctCount) / Double(submittedEvents.count)

        // ── Impulsivity signals ──────────────────────────────────────────
        let excessiveTouchCount   = events.filter { $0.type == .excessiveTouches }.count
        let excessiveTouchRate    = session.totalTasks > 0
            ? Double(excessiveTouchCount) / Double(session.totalTasks) : 0
        let longPauseCount        = events.filter { $0.type == .longPause }.count
        let impulsiveCount        = events.filter { $0.type == .impulsiveResponse }.count

        // ── Composite scores (0–100) ─────────────────────────────────────
        let attentionScore   = computeAttentionScore(
            avgMs: avgResponse, stdDev: stdDev,
            longPauses: longPauseCount, total: session.totalTasks
        )
        let impulsivityScore = computeImpulsivityScore(
            impulsive: impulsiveCount, excessiveTouches: excessiveTouchCount,
            stdDev: stdDev, total: session.totalTasks
        )
        let completionScore  = completionRate * 100

        // Focus score: attention and completion weighted higher than impulsivity
        let focusScore = (attentionScore * 0.40)
                       + (completionScore * 0.40)
                       + ((100 - impulsivityScore) * 0.20)

        let concernLevel = determineConcernLevel(
            focus: focusScore, attention: attentionScore,
            impulsivity: impulsivityScore, completion: completionScore
        )

        let insights = buildInsights(
            avgMs: avgResponse, stdDev: stdDev,
            completionRate: completionRate, accuracyRate: accuracyRate,
            longPauses: longPauseCount, impulsive: impulsiveCount,
            excessiveTouches: excessiveTouchCount
        )

        return SessionMetrics(
            avgResponseTimeMs:    avgResponse,
            responseTimeStdDev:   stdDev,
            completionRate:       completionRate,
            accuracyRate:         accuracyRate,
            excessiveTouchRate:   excessiveTouchRate,
            longPauseCount:       longPauseCount,
            abandonedTasks:       abandonedCount,
            impulsiveResponseCount: impulsiveCount,
            attentionScore:       attentionScore,
            impulsivityScore:     impulsivityScore,
            completionScore:      completionScore,
            focusScore:           focusScore,
            concernLevel:         concernLevel,
            insights:             insights
        )
    }

    // MARK: - Trend Analysis

    static func trend(for sessions: [ExerciseSession]) -> TrendReport {
        let completed = sessions.filter { $0.metrics != nil }
            .sorted { $0.startTime > $1.startTime }
        guard !completed.isEmpty else { return .empty }

        let metrics = completed.compactMap(\.metrics)
        let avgFocus      = mean(metrics.map(\.focusScore))
        let avgAttention  = mean(metrics.map(\.attentionScore))
        let avgImpulsivity = mean(metrics.map(\.impulsivityScore))

        return TrendReport(
            sessions:           completed,
            avgFocusScore:      avgFocus,
            avgAttentionScore:  avgAttention,
            avgImpulsivityScore: avgImpulsivity,
            trend:              computeTrend(sessions: completed)
        )
    }

    // MARK: - Score Helpers

    private static func computeAttentionScore(avgMs: Double, stdDev: Double,
                                              longPauses: Int, total: Int) -> Double {
        var score = 100.0

        // Penalise very slow average responses
        if avgMs > 10_000 { score -= 40 }
        else if avgMs > 6_000 { score -= min(30, (avgMs - 6_000) / 200) }
        else if avgMs > 3_500 { score -= min(15, (avgMs - 3_500) / 300) }

        // Penalise high coefficient of variation (inconsistency)
        let cv = avgMs > 0 ? (stdDev / avgMs) * 100 : 0
        if cv > 100 { score -= min(25, (cv - 100) / 6) }
        else if cv > 60 { score -= min(10, (cv - 60) / 8) }

        // Penalise long pauses
        let pauseRate = total > 0 ? Double(longPauses) / Double(total) : 0
        score -= pauseRate * 25

        return max(0, min(100, score))
    }

    private static func computeImpulsivityScore(impulsive: Int, excessiveTouches: Int,
                                                stdDev: Double, total: Int) -> Double {
        var score = 0.0
        let impRate  = total > 0 ? Double(impulsive)        / Double(total) : 0
        let touchRate = total > 0 ? Double(excessiveTouches) / Double(total) : 0

        score += impRate   * 55   // strong indicator
        score += touchRate * 30

        if stdDev > 4_000 { score += 15 }
        else if stdDev > 2_000 { score += 8 }

        return max(0, min(100, score))
    }

    private static func determineConcernLevel(focus: Double, attention: Double,
                                              impulsivity: Double, completion: Double) -> SessionMetrics.ConcernLevel {
        if focus >= 68 && impulsivity < 30 { return .low }
        if focus >= 45 || (attention >= 55 && completion >= 55) { return .moderate }
        return .elevated
    }

    private static func computeTrend(sessions: [ExerciseSession]) -> TrendReport.Trend {
        guard sessions.count >= 4 else { return .insufficient }
        let scores = sessions.compactMap { $0.metrics?.focusScore }
        guard scores.count >= 4 else { return .insufficient }

        let recent = mean(Array(scores.prefix(2)))
        let older  = mean(Array(scores.suffix(2)))
        let delta  = recent - older

        if delta > 7  { return .improving }
        if delta < -7 { return .declining }
        return .stable
    }

    // MARK: - Insight Strings

    private static func buildInsights(avgMs: Double, stdDev: Double,
                                      completionRate: Double, accuracyRate: Double,
                                      longPauses: Int, impulsive: Int,
                                      excessiveTouches: Int) -> [String] {
        var list: [String] = []

        if avgMs > 6_000 {
            list.append("Response times were slow — may suggest difficulty sustaining focus.")
        } else if avgMs < 900 {
            list.append("Responses were very quick, which can sometimes indicate impulsive answering.")
        }

        let cv = avgMs > 0 ? (stdDev / avgMs) * 100 : 0
        if cv > 80 {
            list.append("Large variation in response speed — attention may be inconsistent.")
        }

        if completionRate < 0.6 {
            list.append("Less than 60 % of tasks were completed — watch for restlessness.")
        }

        if accuracyRate < 0.5 {
            list.append("Accuracy was below 50 % — consider whether tasks felt too hard or distracting.")
        }

        if longPauses >= 3 {
            list.append("Multiple long pauses detected — may reflect difficulty re-engaging with tasks.")
        }

        if impulsive >= 2 {
            list.append("Several very fast wrong answers noted — a possible impulsivity signal.")
        }

        if excessiveTouches >= 2 {
            list.append("Repeated tapping on answer areas observed during some tasks.")
        }

        if list.isEmpty {
            list.append("No notable attention concerns this session — great work!")
        }

        return list
    }

    // MARK: - Stats Utilities

    private static func mean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func standardDeviation(_ values: [Double], mean: Double) -> Double {
        guard values.count > 1 else { return 0 }
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
}
