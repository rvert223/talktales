import SwiftUI

/// Simon-says style pattern game.
/// The app lights up buttons in a sequence; the child must repeat from memory.
struct PatternGameView: View {
    let tracker: BehaviorTracker
    let onFinish: () -> Void

    @State private var sequence: [Int]  = []
    @State private var playerInput: [Int] = []
    @State private var phase: GamePhase = .countdown
    @State private var activeButton: Int?  = nil
    @State private var round = 1
    @State private var message = "Watch the pattern…"
    @State private var showWrong = false
    @State private var countdownValue = 3

    private let totalRounds = 6
    private let colors: [Color] = [.red, .blue, .green, .yellow]
    private let colorNames = ["Red", "Blue", "Green", "Yellow"]

    enum GamePhase { case countdown, showing, input, result }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    ProgressView(value: Double(round - 1), total: Double(totalRounds))
                        .tint(.orange)
                    Text("Round \(round)/\(totalRounds)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 8)

                Text(message)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 24)

                if phase == .countdown {
                    Text("\(countdownValue)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                        .padding(60)
                } else {
                    // 2×2 grid of colour buttons
                    let cols = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
                    LazyVGrid(columns: cols, spacing: 14) {
                        ForEach(0..<4, id: \.self) { idx in
                            ColorButton(
                                color: colors[idx],
                                label: colorNames[idx],
                                isLit: activeButton == idx,
                                isWrong: showWrong && playerInput.last == idx,
                                isDisabled: phase != .input
                            ) {
                                handlePlayerTap(idx)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
        }
        .onAppear { startCountdown() }
    }

    // MARK: - Flow

    private func startCountdown() {
        phase = .countdown
        countdownValue = 3
        message = "Get ready…"
        tick()
    }

    private func tick() {
        guard countdownValue > 0 else {
            phase = .showing
            startRound()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            countdownValue -= 1
            tick()
        }
    }

    private func startRound() {
        sequence.append(Int.random(in: 0..<4))
        playerInput = []
        tracker.beginTask(index: round - 1)
        message = "Watch the pattern…"
        phase = .showing
        showSequence(index: 0)
    }

    private func showSequence(index: Int) {
        guard index < sequence.count else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                message = "Your turn! Repeat the pattern."
                phase = .input
            }
            return
        }
        let btn = sequence[index]
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.8) {
            withAnimation(.easeIn(duration: 0.2)) { activeButton = btn }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation { activeButton = nil }
                showSequence(index: index + 1)
            }
        }
    }

    private func handlePlayerTap(_ idx: Int) {
        guard phase == .input else { return }
        tracker.recordTouch()
        playerInput.append(idx)

        let position = playerInput.count - 1

        if playerInput[position] != sequence[position] {
            // Wrong!
            showWrong = true
            message = "Oops! Let's try again."
            tracker.submitAnswer(isCorrect: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                showWrong = false
                playerInput = []
                phase = .showing
                showSequence(index: 0)
            }
            return
        }

        if playerInput.count == sequence.count {
            // Correct round!
            tracker.submitAnswer(isCorrect: true)
            if round >= totalRounds {
                message = "Amazing! All done!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { onFinish() }
            } else {
                message = "Nice work!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    round += 1
                    startRound()
                }
            }
        }
    }
}

// MARK: - Colour Button

private struct ColorButton: View {
    let color: Color
    let label: String
    let isLit: Bool
    let isWrong: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(isLit ? color : (isWrong ? Color.red : color.opacity(0.35)))
                    .shadow(color: isLit ? color.opacity(0.6) : .clear, radius: 12)
                    .aspectRatio(1, contentMode: .fit)

                Text(label)
                    .font(.headline)
                    .foregroundColor(isLit ? .white : .primary)
            }
        }
        .disabled(isDisabled)
        .scaleEffect(isLit ? 1.06 : 1)
        .animation(.spring(response: 0.2), value: isLit)
    }
}
