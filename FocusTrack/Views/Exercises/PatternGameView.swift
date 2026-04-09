import SwiftUI

/// Pattern-completion exercise.
/// Each round shows a colour sequence with the last item hidden — the child
/// picks which colour comes next.  All DispatchQueue timers are scheduled
/// from a single origin so timing never drifts.
struct PatternGameView: View {
    let tracker: BehaviorTracker
    let onFinish: () -> Void

    private let rounds = PatternRound.all
    @State private var index  = 0
    @State private var phase: PatPhase = .showing   // show sequence → question
    @State private var litIndex: Int?  = nil         // which circle is currently lit
    @State private var tapped: Int?    = nil         // index into choices[]

    enum PatPhase { case showing, question }

    private var round: PatternRound { rounds[index] }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                progressBar
                Spacer()
                switch phase {
                case .showing:  sequenceView
                case .question: questionView
                }
                Spacer()
            }
        }
        .onAppear { startRound() }
    }

    // MARK: - Sub-views

    private var progressBar: some View {
        VStack(spacing: 4) {
            ProgressView(value: Double(index), total: Double(rounds.count))
                .tint(.orange).padding(.horizontal).padding(.top, 16)
            Text("Round \(index + 1) of \(rounds.count)")
                .font(.caption).foregroundColor(.secondary)
        }
    }

    private var sequenceView: some View {
        VStack(spacing: 28) {
            Text("Watch the pattern…")
                .font(.headline).foregroundColor(.orange)

            HStack(spacing: 14) {
                ForEach(round.sequence.indices, id: \.self) { i in
                    Circle()
                        .fill(round.sequence[i].color.opacity(litIndex == i ? 1.0 : 0.25))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle().stroke(round.sequence[i].color, lineWidth: litIndex == i ? 3 : 1)
                        )
                        .scaleEffect(litIndex == i ? 1.12 : 1)
                        .animation(.easeOut(duration: 0.15), value: litIndex)
                }
                // Question-mark placeholder for the missing last item
                Circle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Text("?").font(.title2.bold()).foregroundColor(.secondary)
                    )
            }
        }
    }

    private var questionView: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("What colour comes next?")
                    .font(.title3.bold())
                // Sequence shown (static, no animation)
                HStack(spacing: 14) {
                    ForEach(round.sequence.indices, id: \.self) { i in
                        Circle()
                            .fill(round.sequence[i].color)
                            .frame(width: 36, height: 36)
                    }
                    Circle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(Text("?").font(.caption.bold()).foregroundColor(.secondary))
                }
            }

            // Colour choice buttons
            HStack(spacing: 16) {
                ForEach(round.choices.indices, id: \.self) { i in
                    Button {
                        guard tapped == nil else { return }
                        tracker.recordTouch()
                        tapped = i
                        tracker.submitAnswer(isCorrect: i == round.correctIndex)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { advance() }
                    } label: {
                        Circle()
                            .fill(chipColor(i: i))
                            .frame(width: 60, height: 60)
                            .overlay(checkOverlay(i: i))
                            .scaleEffect(tapped == i ? 0.92 : 1)
                            .animation(.spring(response: 0.2), value: tapped)
                    }
                    .disabled(tapped != nil)
                }
            }
        }
    }

    private func chipColor(i: Int) -> Color {
        guard let t = tapped else { return round.choices[i].color }
        if i == t                  { return i == round.correctIndex ? .green : .red }
        if i == round.correctIndex { return .green.opacity(0.5) }
        return round.choices[i].color.opacity(0.3)
    }

    @ViewBuilder
    private func checkOverlay(i: Int) -> some View {
        if let t = tapped, t == i {
            Image(systemName: i == round.correctIndex ? "checkmark" : "xmark")
                .font(.title3.bold())
                .foregroundColor(.white)
        }
    }

    // MARK: - Logic

    private func startRound() {
        phase     = .showing
        litIndex  = nil
        tapped    = nil
        tracker.beginTask(index: index)

        // Schedule each circle to light up, then transition to question phase.
        // All timers are relative to NOW so there is no drift.
        let perStep = 0.55          // seconds per circle
        let holdOn  = 0.35          // how long the circle stays lit
        let n = round.sequence.count

        for i in 0..<n {
            let onAt  = Double(i) * perStep
            let offAt = onAt + holdOn
            DispatchQueue.main.asyncAfter(deadline: .now() + onAt)  { litIndex = i }
            DispatchQueue.main.asyncAfter(deadline: .now() + offAt) { litIndex = nil }
        }
        // Switch to question after all circles have been shown
        let questionAt = Double(n) * perStep + 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + questionAt) {
            phase = .question
        }
    }

    private func advance() {
        let next = index + 1
        if next >= rounds.count { onFinish(); return }
        index = next
        startRound()
    }
}

// MARK: - Colour enum

enum PatternColor: String, CaseIterable {
    case red, blue, green, yellow, purple, orange

    var color: Color {
        switch self {
        case .red:    return .red
        case .blue:   return .blue
        case .green:  return .green
        case .yellow: return .yellow
        case .purple: return .purple
        case .orange: return .orange
        }
    }
}

// MARK: - Round data

struct PatternRound {
    let sequence: [PatternColor]   // visible part of pattern
    let answer:   PatternColor     // what comes next
    let choices:  [PatternColor]   // 4 options (contains answer)
    let correctIndex: Int

    static let all: [PatternRound] = [
        make(seq: [.red, .blue, .red, .blue],           answer: .red),
        make(seq: [.green, .green, .yellow],             answer: .green),
        make(seq: [.red, .blue, .green, .red, .blue],   answer: .green),
        make(seq: [.purple, .orange, .purple],           answer: .orange),
        make(seq: [.blue, .blue, .red, .blue, .blue],   answer: .red),
        make(seq: [.green, .yellow, .green, .yellow],   answer: .green),
    ]

    private static func make(seq: [PatternColor], answer: PatternColor) -> PatternRound {
        var opts = [answer]
        for c in PatternColor.allCases where c != answer && opts.count < 4 {
            opts.append(c)
        }
        opts.shuffle()
        let idx = opts.firstIndex(of: answer)!
        return PatternRound(sequence: seq, answer: answer, choices: opts, correctIndex: idx)
    }
}
