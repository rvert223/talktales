import SwiftUI

struct MathExerciseView: View {
    let tracker: BehaviorTracker
    let onFinish: () -> Void

    private let questions = MathQuestion.all
    @State private var index = 0
    @State private var tapped: Int? = nil   // tracks which choice was tapped

    private var q: MathQuestion { questions[index] }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                progressBar
                Spacer()
                questionDisplay
                Spacer()
                choiceGrid
                    .padding(.horizontal, 28)
                Spacer()
            }
        }
        .onAppear { tracker.beginTask(index: 0) }
    }

    // MARK: - Sub-views

    private var progressBar: some View {
        VStack(spacing: 4) {
            ProgressView(value: Double(index), total: Double(questions.count))
                .tint(.blue)
                .padding(.horizontal)
                .padding(.top, 16)
            Text("\(index + 1) of \(questions.count)")
                .font(.caption).foregroundColor(.secondary)
        }
    }

    private var questionDisplay: some View {
        VStack(spacing: 12) {
            Image(systemName: "function")
                .font(.system(size: 36)).foregroundColor(.blue)
            Text(q.text)
                .font(.system(size: 44, weight: .bold, design: .rounded))
        }
    }

    private var choiceGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            ForEach(q.choices.indices, id: \.self) { i in
                let value = q.choices[i]
                let isAnswer = value == q.answer
                Button {
                    guard tapped == nil else { return }
                    tracker.recordTouch()
                    tapped = value
                    tracker.submitAnswer(isCorrect: isAnswer)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { advance() }
                } label: {
                    Text("\(value)")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity).padding(.vertical, 22)
                        .background(chipColor(value: value, isAnswer: isAnswer))
                        .foregroundColor(tapped != nil ? .white : .primary)
                        .cornerRadius(14)
                }
                .disabled(tapped != nil)
            }
        }
    }

    private func chipColor(value: Int, isAnswer: Bool) -> Color {
        guard let t = tapped else { return Color(.secondarySystemBackground) }
        if value == t { return isAnswer ? .green : .red }
        if isAnswer   { return .green }
        return Color(.secondarySystemBackground)
    }

    private func advance() {
        let next = index + 1
        if next >= questions.count { onFinish(); return }
        index = next
        tapped = nil
        tracker.beginTask(index: next)
    }
}

// MARK: - Question Data (pre-defined, no randomness)

struct MathQuestion {
    let text: String
    let answer: Int
    let choices: [Int]          // always 4 unique positive values

    static let all: [MathQuestion] = [
        make(a: 3,  b: 4),
        make(a: 7,  b: 2),
        make(a: 5,  b: 6),
        make(a: 8,  b: 3),
        make(a: 4,  b: 9),
        make(a: 6,  b: 7),
        make(a: 9,  b: 5),
        make(a: 2,  b: 8),
        make(a: 10, b: 4),
        make(a: 6,  b: 6),
    ]

    private static func make(a: Int, b: Int) -> MathQuestion {
        let ans = a + b
        // Fixed distractors that are always positive and distinct
        let opts = [ans, ans + 1, ans - 1, ans + 2]
        let choices = Array(Set(opts.map { max($0, 1) }).prefix(4)).shuffled()
        return MathQuestion(text: "\(a) + \(b) = ?", answer: ans, choices: choices)
    }
}
