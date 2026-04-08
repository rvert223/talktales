import SwiftUI

struct ReadingExerciseView: View {
    let tracker: BehaviorTracker
    let onFinish: () -> Void

    @State private var story = ReadingStory.random()
    @State private var phase: Phase = .reading
    @State private var questionIndex = 0
    @State private var selectedAnswer: Int?
    @State private var showFeedback = false
    @State private var readingStartTime = Date()

    enum Phase { case reading, questions }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            switch phase {
            case .reading:
                readingPhaseView
            case .questions:
                questionPhaseView
            }
        }
    }

    // MARK: - Reading Phase

    private var readingPhaseView: some View {
        VStack(spacing: 0) {
            Label("Read this story carefully", systemImage: "book.fill")
                .font(.caption.weight(.semibold))
                .foregroundColor(.green)
                .padding(.top, 24)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(story.title)
                        .font(.title3.bold())
                        .padding(.top, 16)

                    Text(story.passage)
                        .font(.body)
                        .lineSpacing(6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }

            Button(action: startQuestions) {
                Label("I'm ready for the questions", systemImage: "chevron.right.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear { readingStartTime = Date() }
    }

    private func startQuestions() {
        // Session is already started by ExerciseSessionView; just begin first task
        tracker.beginTask(index: 0)
        phase = .questions
    }

    // MARK: - Question Phase

    private var questionPhaseView: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(questionIndex), total: Double(story.questions.count))
                .tint(.green)
                .padding(.horizontal)
                .padding(.top, 16)

            Text("Question \(questionIndex + 1) of \(story.questions.count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)

            Spacer()

            let q = story.questions[questionIndex]

            VStack(spacing: 16) {
                Text(q.text)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(spacing: 10) {
                    ForEach(Array(q.choices.enumerated()), id: \.offset) { idx, choice in
                        ReadingAnswerRow(
                            text: choice,
                            selected: selectedAnswer == idx,
                            showFeedback: showFeedback,
                            isCorrect: idx == q.correctIndex
                        ) {
                            guard !showFeedback else { return }
                            tracker.recordTouch()
                            selectedAnswer = idx
                            tracker.submitAnswer(isCorrect: idx == q.correctIndex)
                            showFeedback = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { advanceQuestion() }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()
        }
    }

    private func advanceQuestion() {
        let next = questionIndex + 1
        if next >= story.questions.count {
            onFinish()
            return
        }
        questionIndex = next
        selectedAnswer = nil
        showFeedback = false
        tracker.beginTask(index: next)
    }
}

// MARK: - Row Button

private struct ReadingAnswerRow: View {
    let text: String
    let selected: Bool
    let showFeedback: Bool
    let isCorrect: Bool
    let action: () -> Void

    private var background: Color {
        guard showFeedback && selected else {
            return selected ? Color.green.opacity(0.15) : Color(.secondarySystemBackground)
        }
        return isCorrect ? .green : .red
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                Spacer()
                if showFeedback && selected {
                    Image(systemName: isCorrect ? "checkmark" : "xmark")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(background)
            .cornerRadius(12)
        }
    }
}

// MARK: - Story Data

struct ReadingStory {
    let title: String
    let passage: String
    let questions: [ReadingQuestion]

    static func random() -> ReadingStory { all.randomElement()! }

    static let all: [ReadingStory] = [
        ReadingStory(
            title: "The Little Cloud",
            passage: """
            Once there was a small, fluffy cloud named Nimbus. Every morning, Nimbus floated high above a sleepy town. The people below could not see Nimbus clearly because the cloud was so small. One day, a farmer looked up and noticed the cloud drifting lazily across the blue sky.

            "Maybe rain is coming," said the farmer hopefully. His crops were very thirsty.

            But Nimbus was too little to make rain. Instead, the cloud floated over a pond and sprinkled just enough mist to cool a family of ducks. The ducks quacked happily. Nimbus felt proud. Not every cloud needs to make a storm to do something wonderful.
            """,
            questions: [
                ReadingQuestion(text: "What was the cloud's name?",
                                choices: ["Stratus", "Nimbus", "Cirrus", "Cumulus"],
                                correctIndex: 1),
                ReadingQuestion(text: "Why was the farmer hopeful when he saw the cloud?",
                                choices: ["He wanted shade", "He thought rain was coming", "He liked clouds", "He was bored"],
                                correctIndex: 1),
                ReadingQuestion(text: "What did Nimbus do instead of making rain?",
                                choices: ["Caused a storm", "Misted the ducks", "Flew away", "Made snow"],
                                correctIndex: 1),
                ReadingQuestion(text: "How did the ducks react?",
                                choices: ["They hid", "They quacked happily", "They swam away", "They were scared"],
                                correctIndex: 1),
                ReadingQuestion(text: "What lesson does the story share?",
                                choices: ["Storms are better than mist",
                                          "Clouds should be bigger",
                                          "Small acts can still be wonderful",
                                          "Ducks don't like rain"],
                                correctIndex: 2),
            ]
        ),
        ReadingStory(
            title: "Max the Robot",
            passage: """
            Max was a small robot who lived in a workshop full of tools and machines. Max had bright blue eyes that lit up when he was curious. One afternoon, a gear fell off the big clock on the wall. Tick — the clock stopped.

            Max looked at the gear, then at the clock. He picked up the gear carefully and climbed a ladder. With a gentle click, he pressed the gear back into place. The clock began to tick again, loudly and proudly.

            The inventor who owned the workshop walked in just as the clock chimed the hour. She smiled at Max. "Thank you," she said. Max's blue eyes glowed brighter than ever.
            """,
            questions: [
                ReadingQuestion(text: "What colour were Max's eyes?",
                                choices: ["Red", "Green", "Blue", "Yellow"],
                                correctIndex: 2),
                ReadingQuestion(text: "What fell off the clock?",
                                choices: ["A hand", "A spring", "A gear", "A battery"],
                                correctIndex: 2),
                ReadingQuestion(text: "How did Max fix the clock?",
                                choices: ["He called for help", "He pressed the gear back in", "He built a new clock", "He wound it up"],
                                correctIndex: 1),
                ReadingQuestion(text: "Who owned the workshop?",
                                choices: ["A painter", "A teacher", "An inventor", "A farmer"],
                                correctIndex: 2),
                ReadingQuestion(text: "How did Max feel at the end?",
                                choices: ["Sad", "Confused", "Proud and happy", "Tired"],
                                correctIndex: 2),
            ]
        ),
        ReadingStory(
            title: "The Speedy Snail",
            passage: """
            Everyone in the garden thought snails were slow. Everyone, that is, except Maya the snail herself. Maya had a plan. Each day she practiced gliding along the smoothest parts of the garden path. She avoided the bumpy stones and the sticky mud.

            On the day of the Big Garden Race, the grasshoppers laughed. "A snail in a race?" they said. The starting whistle blew. Maya focused on the smooth path she had studied all week. Steady and sure, she crossed the finish line just seconds after the fastest grasshopper.

            "I didn't win," Maya said, smiling, "but I was faster than anyone expected. That's enough for me."
            """,
            questions: [
                ReadingQuestion(text: "What did Maya practise every day?",
                                choices: ["Jumping", "Gliding on smooth paths", "Swimming", "Climbing"],
                                correctIndex: 1),
                ReadingQuestion(text: "Who laughed at Maya before the race?",
                                choices: ["Butterflies", "Beetles", "Grasshoppers", "Bees"],
                                correctIndex: 2),
                ReadingQuestion(text: "Did Maya win the race?",
                                choices: ["Yes, she came first", "No, but she was close", "She didn't finish", "No one finished"],
                                correctIndex: 1),
                ReadingQuestion(text: "What was Maya's attitude at the end?",
                                choices: ["She was upset", "She was satisfied with her effort", "She wanted a rematch", "She quit racing"],
                                correctIndex: 1),
                ReadingQuestion(text: "What is a key theme of this story?",
                                choices: ["Speed always wins", "Preparation and effort matter", "Grasshoppers are unkind", "Gardens are boring"],
                                correctIndex: 1),
            ]
        ),
    ]
}

struct ReadingQuestion {
    let text: String
    let choices: [String]
    let correctIndex: Int
}
