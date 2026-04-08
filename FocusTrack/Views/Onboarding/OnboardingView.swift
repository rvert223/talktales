import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var page = 0

    var body: some View {
        TabView(selection: $page) {
            WelcomePage(onNext: { withAnimation { page = 1 } })
                .tag(0)
            HowItWorksPage(onNext: { withAnimation { page = 2 } })
                .tag(1)
            DisclaimerPage(onNext: { withAnimation { page = 2 } })
                .tag(1)
            AddChildPage(onDone: finishOnboarding)
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .animation(.easeInOut, value: page)
    }

    private func finishOnboarding() {
        dataStore.completeOnboarding()
    }
}

// MARK: - Page 0: Welcome

private struct WelcomePage: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            VStack(spacing: 12) {
                Text("FocusTrack")
                    .font(.largeTitle.bold())
                Text("Helping parents spot early attention\npatterns in their children.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            PrimaryButton(title: "Get Started", action: onNext)
                .padding(.horizontal, 32)
            Spacer().frame(height: 20)
        }
        .padding()
    }
}

// MARK: - Page 1: How It Works

private struct HowItWorksPage: View {
    let onNext: () -> Void

    private let steps: [(icon: String, color: Color, title: String, detail: String)] = [
        ("pencil.circle.fill", .blue,   "Short Exercises",
         "Your child completes quick activities — math, reading, memory, and pattern tasks."),
        ("waveform.path.ecg", .purple,  "Automatic Tracking",
         "The app silently measures response timing, focus duration, and touch patterns."),
        ("chart.bar.fill",    .green,   "Parent Insights",
         "Clear, jargon-free reports highlight trends over time so you know what to watch."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Text("How FocusTrack Works")
                .font(.title2.bold())
                .padding(.top, 48)
                .padding(.bottom, 32)

            ForEach(steps, id: \.title) { step in
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: step.icon)
                        .font(.title2)
                        .foregroundColor(step.color)
                        .frame(width: 44)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title).font(.headline)
                        Text(step.detail).font(.subheadline).foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
            }

            Spacer()
            PrimaryButton(title: "Next", action: onNext)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
        }
    }
}

// MARK: - Page 2: Disclaimer

private struct DisclaimerPage: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Important Notice")
                .font(.title2.bold())

            Text("""
                FocusTrack is an **educational screening tool**, not a medical device.

                Results are designed to help parents notice patterns, not to diagnose ADHD or any other condition.

                If you have concerns about your child's attention, please speak with a qualified healthcare professional.
                """)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()
            PrimaryButton(title: "I Understand", action: onNext)
                .padding(.horizontal, 32)
            Spacer().frame(height: 20)
        }
        .padding()
    }
}

// MARK: - Page 3: Add First Child

private struct AddChildPage: View {
    @EnvironmentObject var dataStore: DataStore
    let onDone: () -> Void

    @State private var name = ""
    @State private var age  = 7
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Text("Add Your Child's Profile")
                    .font(.title2.bold())
                    .padding(.top, 48)

                Text("This helps us tailor exercises and context for reports.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(spacing: 16) {
                    LabeledTextField(label: "Child's Name", placeholder: "e.g. Alex", text: $name)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Age").font(.caption).foregroundColor(.secondary)
                        Picker("Age", selection: $age) {
                            ForEach(4...16, id: \.self) { Text("\($0)").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                        .clipped()
                    }
                    .padding(.horizontal, 16)
                }

                if showError {
                    Text("Please enter a name.")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                PrimaryButton(title: "Start Tracking") {
                    guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                        showError = true
                        return
                    }
                    dataStore.addChild(Child(name: name.trimmingCharacters(in: .whitespaces), age: age))
                    onDone()
                }
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Shared Components

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(14)
        }
    }
}

struct LabeledTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
        }
        .padding(.horizontal, 16)
    }
}
