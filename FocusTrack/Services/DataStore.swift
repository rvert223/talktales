import Foundation
import CryptoKit
import Combine

final class DataStore: ObservableObject {

    // MARK: - Published state

    @Published var account: Account?         // nil = no account created yet
    @Published var isLoggedIn: Bool = false
    @Published var children: [Child] = []
    @Published var sessions: [ExerciseSession] = []
    @Published var selectedChildId: UUID?
    @Published var hasCompletedOnboarding: Bool = false

    // MARK: - UserDefaults keys

    private let accountKey      = "ft_account"
    private let loggedInKey     = "ft_logged_in"
    private let childrenKey     = "ft_children"
    private let sessionsKey     = "ft_sessions"
    private let onboardingKey   = "ft_onboarding_complete"

    init() { loadData() }

    // MARK: - Account management

    /// Creates the single device account.  Returns an error string on failure.
    func createAccount(name: String, email: String, password: String) -> String? {
        if account != nil {
            return "An account already exists on this device. Please log in."
        }
        let newAccount = Account(
            name: name,
            email: email.lowercased().trimmingCharacters(in: .whitespaces),
            passwordHash: hashPassword(password)
        )
        account    = newAccount
        isLoggedIn = true
        saveAccount()
        UserDefaults.standard.set(true, forKey: loggedInKey)
        return nil
    }

    func login(email: String, password: String) -> Bool {
        guard let stored = account else { return false }
        let normalised = email.lowercased().trimmingCharacters(in: .whitespaces)
        guard stored.email == normalised,
              stored.passwordHash == hashPassword(password) else { return false }
        isLoggedIn = true
        UserDefaults.standard.set(true, forKey: loggedInKey)
        return true
    }

    func logout() {
        isLoggedIn = false
        UserDefaults.standard.set(false, forKey: loggedInKey)
    }

    func updateAccountName(_ newName: String) {
        account?.name = newName
        saveAccount()
    }

    // MARK: - Child management

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
        sessions.removeAll  { $0.childId == id }
        if selectedChildId == id { selectedChildId = children.first?.id }
        saveChildren()
        saveSessions()
    }

    var selectedChild: Child? {
        children.first { $0.id == selectedChildId }
    }

    // MARK: - Session management

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
            .filter  { $0.childId == childId && $0.isComplete }
            .sorted  { $0.startTime > $1.startTime }
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
        // Account
        if let data = UserDefaults.standard.data(forKey: accountKey),
           let decoded = try? JSONDecoder().decode(Account.self, from: data) {
            account = decoded
        }
        isLoggedIn = UserDefaults.standard.bool(forKey: loggedInKey) && account != nil

        // Onboarding
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)

        // Children
        if let data = UserDefaults.standard.data(forKey: childrenKey),
           let decoded = try? JSONDecoder().decode([Child].self, from: data) {
            children = decoded
            selectedChildId = children.first?.id
        }

        // Sessions
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([ExerciseSession].self, from: data) {
            sessions = decoded
        }
    }

    private func saveAccount() {
        if let encoded = try? JSONEncoder().encode(account) {
            UserDefaults.standard.set(encoded, forKey: accountKey)
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

    // MARK: - Password hashing (SHA-256, local only)

    private func hashPassword(_ password: String) -> String {
        let hash = SHA256.hash(data: Data(password.utf8))
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
