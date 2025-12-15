import Foundation

struct Habit: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var streak: Int

    init(id: UUID = UUID(), name: String, streak: Int = 0) {
        self.id = id
        self.name = name
        self.streak = streak
    }
}
