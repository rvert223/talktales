import SwiftUI

/// Simplified reading exercise: each question shows a short passage snippet
/// and 4 choices. No separate "reading phase" — keeps the state machine simple.
struct ReadingExerciseView: View {
    let tracker: BehaviorTracker
    let onFinish: () -> Void

    private let questions = ReadingQ.all.shuffled()
    @State private var index = 0
    @State private var tapped: Int? = nil   // index into choices[]

    private var q: ReadingQ { questions[index] }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                progressBar
                ScrollView {
                    VStack(spacing: 20) {
                        passageCard
                        questionText
                        choiceList
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear { tracker.beginTask(index: 0) }
    }

    // MARK: - Sub-views

    private var progressBar: some View {
        VStack(spacing: 4) {
            ProgressView(value: Double(index), total: Double(questions.count))
                .tint(.green).padding(.horizontal).padding(.top, 16)
            Text("Question \(index + 1) of \(questions.count)")
                .font(.caption).foregroundColor(.secondary)
        }
    }

    private var passageCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Read", systemImage: "book.fill")
                .font(.caption.weight(.semibold)).foregroundColor(.green)
            Text(q.passage)
                .font(.subheadline).lineSpacing(5)
        }
        .padding()
        .background(Color.green.opacity(0.08))
        .cornerRadius(12)
        .padding(.top, 16)
    }

    private var questionText: some View {
        Text(q.question)
            .font(.headline)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 4)
    }

    private var choiceList: some View {
        VStack(spacing: 10) {
            ForEach(q.choices.indices, id: \.self) { i in
                Button {
                    guard tapped == nil else { return }
                    tracker.recordTouch()
                    tapped = i
                    tracker.submitAnswer(isCorrect: i == q.correctIndex)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { advance() }
                } label: {
                    HStack {
                        Text(q.choices[i])
                            .font(.subheadline).foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if let t = tapped, t == i {
                            Image(systemName: i == q.correctIndex ? "checkmark" : "xmark")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(chipColor(i: i))
                    .cornerRadius(12)
                }
                .disabled(tapped != nil)
            }
        }
    }

    private func chipColor(i: Int) -> Color {
        guard let t = tapped else { return Color(.secondarySystemBackground) }
        if i == t          { return i == q.correctIndex ? .green : .red }
        if i == q.correctIndex { return .green.opacity(0.4) }
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

// MARK: - Data

struct ReadingQ {
    let passage: String
    let question: String
    let choices: [String]
    let correctIndex: Int

    static let all: [ReadingQ] = [
        ReadingQ(
            passage: "Mia found a small bird with a hurt wing in her garden. She gently placed it in a box with soft cloth and gave it water.",
            question: "Why did Mia put the bird in a box?",
            choices: ["To keep it as a pet", "To help it recover", "To show her friends", "To take it to school"],
            correctIndex: 1
        ),
        ReadingQ(
            passage: "The library was quiet on Saturday morning. Jake found a book about dinosaurs and sat by the window to read.",
            question: "Where did Jake sit to read?",
            choices: ["At a table", "On the floor", "By the window", "Near the door"],
            correctIndex: 2
        ),
        ReadingQ(
            passage: "Every evening, Grandma and Leo looked at the stars together. She taught him the names of the constellations.",
            question: "What did Grandma teach Leo?",
            choices: ["How to cook dinner", "Names of constellations", "How to draw", "Names of planets"],
            correctIndex: 1
        ),
        ReadingQ(
            passage: "Sam's team lost the soccer game. Even though he was sad, he shook hands with the other team and said 'good game.'",
            question: "What does Sam's action show?",
            choices: ["He was angry", "He did not care", "He was a good sport", "He wanted to play again"],
            correctIndex: 2
        ),
        ReadingQ(
            passage: "The baker woke at 4 a.m. to make fresh bread. By the time the shop opened, the whole street smelled of warm loaves.",
            question: "Why did the baker wake up so early?",
            choices: ["To open the shop", "To make fresh bread", "To clean the kitchen", "To deliver orders"],
            correctIndex: 1
        ),
        ReadingQ(
            passage: "During the storm, the power went out. Lily lit candles and they played board games by candlelight until morning.",
            question: "What did Lily use when the power went out?",
            choices: ["A flashlight", "A lantern", "Candles", "Her phone"],
            correctIndex: 2
        ),
        ReadingQ(
            passage: "The caterpillar spun a cocoon around itself. Weeks later it emerged as a colourful butterfly and flew away.",
            question: "What came out of the cocoon?",
            choices: ["A moth", "A bee", "A butterfly", "A caterpillar"],
            correctIndex: 2
        ),
        ReadingQ(
            passage: "Carlos practised the piano every day for a month. At the recital, he played his piece without a single mistake.",
            question: "How did Carlos do at the recital?",
            choices: ["He forgot the notes", "He played perfectly", "He played too fast", "He did not attend"],
            correctIndex: 1
        ),
    ]
}
