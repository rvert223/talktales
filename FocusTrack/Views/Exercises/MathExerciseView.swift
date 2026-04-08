import SwiftUI

struct MathExerciseView: View {
    let tracker: BehaviorTracker
    let onFinish: () -> Void

    @State private var questions: [MathQuestion] = MathQuestion.generate(count: 10)
    @State private var currentIndex = 0
    @State private var selectedAnswer: Int?
    @State private var showFeedback = false
    @State private var progress: Double = 0

    private var current: MathQuestion { questions[currentIndex] }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: progress, total: 1)
                    .tint(.blue)
                    .padding(.horizontal)
                    .padding(.top, 16)

                Text("\(currentIndex + 1) of \(questions.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)

                Spacer()

                // Question
                VStack(spacing: 12) {
                    Image(systemName: "function")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)
                    Text(current.question)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 40)

                // Answer choices
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(current.choices, id: \.self) { choice in
                        AnswerButton(
                            value: choice,
                            selected: selectedAnswer == choice,
                            isCorrect: showFeedback ? choice == current.answer : nil
                        ) {
                            guard !showFeedback else { return }
                            tracker.recordTouch()
                            selectedAnswer = choice
                            let correct = choice == current.answer
                            tracker.submitAnswer(isCorrect: correct)
                            showFeedback = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { advance() }
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .onAppear {
            tracker.beginTask(index: 0)
            updateProgress()
        }
    }

    private func advance() {
        let next = currentIndex + 1
        if next >= questions.count {
            onFinish()
            return
        }
        currentIndex = next
        selectedAnswer = nil
        showFeedback = false
        updateProgress()
        tracker.beginTask(index: next)
    }

    private func updateProgress() {
        withAnimation { progress = Double(currentIndex) / Double(questions.count) }
    }
}

// MARK: - Answer Button

private struct AnswerButton: View {
    let value: Int
    let selected: Bool
    let isCorrect: Bool?
    let action: () -> Void

    private var background: Color {
        guard let correct = isCorrect else {
            return selected ? .blue : Color(.secondarySystemBackground)
        }
        return correct ? .green : .red
    }

    private var foreground: Color {
        (selected || isCorrect != nil) ? .white : .primary
    }

    var body: some View {
        Button(action: action) {
            Text("\(value)")
                .font(.title2.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(background)
                .foregroundColor(foreground)
                .cornerRadius(14)
                .scaleEffect(selected ? 0.95 : 1)
                .animation(.spring(response: 0.2), value: selected)
        }
    }
}

// MARK: - Data

struct MathQuestion {
    let question: String
    let answer: Int
    let choices: [Int]

    static func generate(count: Int) -> [MathQuestion] {
        (0..<count).map { _ in
            let a = Int.random(in: 1...12)
            let b = Int.random(in: 1...12)
            let ans = a + b
            var opts = Set<Int>([ans])
            while opts.count < 4 {
                opts.insert(ans + Int.random(in: -5...5))
            }
            let shuffled = opts.sorted().shuffled()
            return MathQuestion(question: "\(a) + \(b) = ?", answer: ans, choices: shuffled)
        }
    }
}
