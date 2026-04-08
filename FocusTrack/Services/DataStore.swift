import Foundation
import Combine

final class DataStore: ObservableObject {
    @Published var children: [Child] = []
    @Published var sessions: [ExerciseSession] = []
    @Published var selectedChildId: UUID?
    @Published var hasCompletedOnboarding: Bool = false

    private let childrenKey    = "ft_children"
    private let sessionsKey    = "ft_sessions"
    private let onboardingKey  = "ft_onboarding_complete"

    init() {
        loadData()
    }

    // MARK: - Child Management

    func addChild(_ child: Child) {
        children.append(child)
        if selectedChildId == nil { selectedChildId = child.id }
        saveChildren()
    }

    func updateChild(_ child: Child) {
        guard let idx = children.firstIndex(where: { $0.id == child.id }) else { return }
        children[idx] = child
        saveChildren()
    }

    func deleteChild(id: UUID) {
        children.removeAll { $0.id == id }
        sessions.removeAll { $0.childId == id }
        if selectedChildId == id { selectedChildId = children.first?.id }
        saveChildren()
        saveSessions()
    }

    var selectedChild: Child? {
        children.first { $0.id == selectedChildId }
    }

    // MARK: - Session Management

    func saveSession(_ session: ExerciseSession) {
        if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[idx] = session
        } else {
            sessions.append(session)
        }
        saveSessions()
    }

    func completedSessions(for childId: UUID) -> [ExerciseSession] {
        sessions
            .filter { $0.childId == childId && $0.isComplete }
            .sorted { $0.startTime > $1.startTime }
    }

    func recentSessions(for childId: UUID, limit: Int = 10) -> [ExerciseSession] {
        Array(completedSessions(for: childId).prefix(limit))
    }

    // MARK: - Onboarding

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    // MARK: - Persistence

    private func loadData() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)

        if let data = UserDefaults.standard.data(forKey: childrenKey),
           let decoded = try? JSONDecoder().decode([Child].self, from: data) {
            children = decoded
            selectedChildId = children.first?.id
        }

        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([ExerciseSession].self, from: data) {
            sessions = decoded
        }
    }

    private func saveChildren() {
        if let encoded = try? JSONEncoder().encode(children) {
            UserDefaults.standard.set(encoded, forKey: childrenKey)
        }
    }

    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
    }
}
