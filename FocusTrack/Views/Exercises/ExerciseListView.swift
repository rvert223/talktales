import SwiftUI

struct ExerciseListView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedExercise: ExerciseType?
    @State private var showSession = false
    @State private var sessionChild: Child?   // captured before cover opens

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ChildSelectorBar()
                        .padding(.horizontal)

                    if let child = dataStore.selectedChild {
                        Text("Choose an activity for \(child.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        ForEach(ExerciseType.allCases) { type in
                            ExerciseCard(type: type) {
                                sessionChild = dataStore.selectedChild
                                selectedExercise = type
                                showSession = true
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        EmptyStateView(message: "Add a child profile in Settings to get started.")
                            .padding(.top, 60)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .navigationTitle("Exercises")
            .background(Color(.systemGroupedBackground))
            .fullScreenCover(isPresented: $showSession) {
                if let exercise = selectedExercise, let child = sessionChild {
                    ExerciseSessionView(exerciseType: exercise, child: child)
                        .environmentObject(dataStore)
                }
            }
        }
    }
}

// MARK: - Exercise Card

private struct ExerciseCard: View {
    let type: ExerciseType
    let onStart: () -> Void

    var body: some View {
        Button(action: onStart) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(type.color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: type.icon)
                        .font(.title2)
                        .foregroundColor(type.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(type.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    HStack(spacing: 12) {
                        Label("\(type.taskCount) tasks", systemImage: "list.bullet")
                        Label("~\(type.estimatedMinutes) min",  systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }
}
