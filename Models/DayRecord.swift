import Foundation

struct DayRecord: Codable, Equatable {
    var date: Date
    var completedHabitIDs: [UUID]

    init(date: Date, completedHabitIDs: [UUID] = []) {
        self.date = Calendar.current.startOfDay(for: date)
        self.completedHabitIDs = completedHabitIDs
    }
}
