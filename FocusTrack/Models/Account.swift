import Foundation

struct Account: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String          // stored lowercase
    var passwordHash: String
    let createdAt: Date

    init(id: UUID = UUID(), name: String, email: String,
         passwordHash: String, createdAt: Date = Date()) {
        self.id           = id
        self.name         = name
        self.email        = email
        self.passwordHash = passwordHash
        self.createdAt    = createdAt
    }
}
