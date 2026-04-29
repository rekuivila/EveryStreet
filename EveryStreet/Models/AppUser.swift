import Foundation
import SwiftData

@Model
final class AppUser {
    var id: String
    var username: String
    var email: String
    var zipCode: String
    var createdAt: Date

    init(id: String, username: String, email: String, zipCode: String) {
        self.id = id
        self.username = username
        self.email = email
        self.zipCode = zipCode
        self.createdAt = Date()
    }
}
