import SwiftUI

/// Quick-peek memory exercise.
/// Each round: show 4 emoji for 2.5 s → hide them → ask "which one was in position X?"
struct MemoryGameView: View {
    let tracker: BehaviorTracker
    let onFinish: () -> Void

    private let rounds = MemoryRound.all
    @State private var index = 0
    @State private var phase: MemPhase = .showing
    @State private var tapped: Int? = nil      // index into choices[]

    enum MemPhase { case showing, question }

    private var round: MemoryRound { rounds[index] }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                progressBar
                Spacer()
                switch phase {
                case .showing:  peekView
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
                .tint(.purple).padding(.horizontal).padding(.top, 16)
            Text("Round \(index + 1) of \(rounds.count)")
                .font(.caption).foregroundColor(.secondary)
        }
    }

    private var peekView: some View {
        VStack(spacing: 24) {
            Text("Remember these!")
                .font(.headline).foregroundColor(.purple)
            HStack(spacing: 18) {
                ForEach(round.shown.indices, id: \.self) { i in
                    Text(round.shown[i])
                        .font(.system(size: 44))
                        .frame(width: 64, height: 64)
                        .background(Color.purple.opacity(0.12))
                        .cornerRadius(14)
                }
            }
            Text("Memorise them…")
                .font(.subheadline).foregroundColor(.secondary)
        }
    }

    private var questionView: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("Which emoji was in")
                    .font(.headline)
                Text("position \(round.askPosition)?")
                    .font(.title2.bold())
            }
            .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                ForEach(round.choices.indices, id: \.self) { i in
                    Button {
                        guard tapped == nil else { return }
                        tracker.recordTouch()
                        tapped = i
                        tracker.submitAnswer(isCorrect: i == round.correctIndex)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { advance() }
                    } label: {
                        Text(round.choices[i])
                            .font(.system(size: 40))
                            .frame(width: 72, height: 72)
                            .background(chipColor(i: i))
                            .cornerRadius(16)
                    }
                    .disabled(tapped != nil)
                }
            }
        }
    }

    private func chipColor(i: Int) -> Color {
        guard let t = tapped else { return Color.purple.opacity(0.12) }
        if i == t                  { return i == round.correctIndex ? .green : .red }
        if i == round.correctIndex { return .green.opacity(0.4) }
        return Color.purple.opacity(0.06)
    }

    // MARK: - Logic

    private func startRound() {
        phase = .showing
        tapped = nil
        tracker.beginTask(index: index)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
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

// MARK: - Data

struct MemoryRound {
    let shown: [String]          // 4 emoji shown to user
    let askPosition: Int         // 1-based position asked about
    let choices: [String]        // 4 emoji choices (contains correct answer)
    let correctIndex: Int        // index into choices[]

    static let all: [MemoryRound] = [
        make(shown: ["🐶","🐱","🐰","🦊"], ask: 2),
        make(shown: ["🍎","🍌","🍇","🍓"], ask: 3),
        make(shown: ["🚀","🌙","⭐","🌍"], ask: 1),
        make(shown: ["🎸","🎹","🎺","🥁"], ask: 4),
        make(shown: ["🌸","🌻","🌺","🍀"], ask: 2),
        make(shown: ["🐘","🦁","🐬","🦋"], ask: 3),
        make(shown: ["🏀","⚽","🎾","🏈"], ask: 1),
        make(shown: ["🍕","🍔","🌮","🍜"], ask: 4),
    ]

    private static func make(shown: [String], ask: Int) -> MemoryRound {
        let correct = shown[ask - 1]
        let pool    = ["🌵","🎃","🚂","💎","🎈","🔑","🌈","🦄"].filter { !shown.contains($0) }
        var choices = [correct] + Array(pool.prefix(3))
        choices.shuffle()
        let idx = choices.firstIndex(of: correct)!
        return MemoryRound(shown: shown, askPosition: ask, choices: choices, correctIndex: idx)
    }
}
