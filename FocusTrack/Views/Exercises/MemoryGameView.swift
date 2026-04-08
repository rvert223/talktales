import SwiftUI

struct MemoryGameView: View {
    let tracker: BehaviorTracker
    let onFinish: () -> Void

    @State private var cards: [MemoryCard] = MemoryCard.shuffledDeck()
    @State private var firstFlipped: Int?
    @State private var matchedPairs = 0
    @State private var isChecking = false
    @State private var moveCount = 0

    private let totalPairs = 8

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Label("Pairs: \(matchedPairs)/\(totalPairs)", systemImage: "square.grid.2x2.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.purple)
                    Spacer()
                    Label("Moves: \(moveCount)", systemImage: "hand.tap")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)

                ProgressView(value: Double(matchedPairs), total: Double(totalPairs))
                    .tint(.purple)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                // 4×4 grid
                let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(cards.indices, id: \.self) { idx in
                        CardView(card: cards[idx])
                            .aspectRatio(0.75, contentMode: .fit)
                            .onTapGesture {
                                tracker.recordTouch()
                                handleTap(idx)
                            }
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
        }
        .onAppear { tracker.beginTask(index: 0) }
    }

    // MARK: - Game Logic

    private func handleTap(_ idx: Int) {
        guard !isChecking,
              !cards[idx].isMatched,
              !cards[idx].isFaceUp else { return }

        withAnimation(.spring(response: 0.35)) {
            cards[idx].isFaceUp = true
        }

        if let first = firstFlipped {
            // Second card flipped
            isChecking = true
            moveCount += 1

            if cards[first].emoji == cards[idx].emoji {
                // Match!
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        cards[first].isMatched = true
                        cards[idx].isMatched   = true
                    }
                    matchedPairs += 1
                    tracker.submitAnswer(isCorrect: true)
                    tracker.beginTask(index: matchedPairs)
                    firstFlipped = nil
                    isChecking = false
                    if matchedPairs == totalPairs { onFinish() }
                }
            } else {
                // No match — flip back
                tracker.submitAnswer(isCorrect: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring(response: 0.35)) {
                        cards[first].isFaceUp = false
                        cards[idx].isFaceUp   = false
                    }
                    firstFlipped = nil
                    isChecking = false
                }
            }
        } else {
            firstFlipped = idx
        }
    }
}

// MARK: - Card View

private struct CardView: View {
    let card: MemoryCard

    var body: some View {
        ZStack {
            if card.isFaceUp || card.isMatched {
                RoundedRectangle(cornerRadius: 10)
                    .fill(card.isMatched ? Color.purple.opacity(0.15) : Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                Text(card.emoji)
                    .font(.system(size: 28))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.purple)
                Image(systemName: "questionmark")
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
        }
        .rotation3DEffect(.degrees(card.isFaceUp || card.isMatched ? 0 : 180),
                          axis: (x: 0, y: 1, z: 0))
    }
}

// MARK: - Model

struct MemoryCard {
    let id: UUID
    let emoji: String
    var isFaceUp: Bool
    var isMatched: Bool

    static let emojis = ["🐶","🐱","🐭","🐹","🐰","🦊","🐻","🐼"]

    static func shuffledDeck() -> [MemoryCard] {
        let pairs = emojis.flatMap { emoji -> [MemoryCard] in
            [MemoryCard(id: UUID(), emoji: emoji, isFaceUp: false, isMatched: false),
             MemoryCard(id: UUID(), emoji: emoji, isFaceUp: false, isMatched: false)]
        }
        return pairs.shuffled()
    }
}
