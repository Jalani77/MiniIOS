import Foundation
import SwiftUI

/// Data flow summary:
/// - Persisted sources of truth: `habits` and `dayRecords` in UserDefaults.
/// - UI toggles read/write `DayRecord.completedHabitIDs` for *today*.
/// - After any change, streaks are recalculated from contiguous day records per habit,
///   and the 7-day chart is derived from the last 7 days of day records.
@MainActor
final class HabitTrackerViewModel: ObservableObject {
    struct DaySummary: Identifiable, Equatable {
        var id: Date { date }
        let date: Date
        let completedCount: Int
        let dayLabel: String
    }

    @Published private(set) var habits: [Habit] = []
    @Published private(set) var dayRecords: [DayRecord] = []

    private let habitsKey = "habits"
    private let dayRecordsKey = "dayRecords"

    private var lastKnownTodayStart: Date

    init() {
        let todayStart = Calendar.current.startOfDay(for: Date())
        self.lastKnownTodayStart = todayStart
        loadOrSeed()
        refreshForNewDayIfNeeded()
        recalculateStreaks()
    }

    var todayStartOfDay: Date {
        Calendar.current.startOfDay(for: Date())
    }

    var todayDateText: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMM d")
        return formatter.string(from: Date())
    }

    var last7Days: [DaySummary] {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEEEE"

        let today = cal.startOfDay(for: Date())
        let summaries: [DaySummary] = (0..<7).compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: -(6 - offset), to: today) else { return nil }
            let record = dayRecord(for: day)
            return DaySummary(
                date: day,
                completedCount: record?.completedHabitIDs.count ?? 0,
                dayLabel: formatter.string(from: day)
            )
        }
        return summaries
    }

    func refreshForNewDayIfNeeded() {
        let cal = Calendar.current
        let nowStart = cal.startOfDay(for: Date())
        guard nowStart != lastKnownTodayStart else {
            ensureDayRecordExists(for: nowStart)
            return
        }

        lastKnownTodayStart = nowStart
        ensureDayRecordExists(for: nowStart)
        recalculateStreaks()
        persistAll()
    }

    func isHabitDoneToday(_ habitID: UUID) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return dayRecord(for: today)?.completedHabitIDs.contains(habitID) ?? false
    }

    func toggleHabitToday(_ habitID: UUID) {
        refreshForNewDayIfNeeded()

        let today = Calendar.current.startOfDay(for: Date())
        var record = ensureDayRecordExists(for: today)
        var set = Set(record.completedHabitIDs)

        if set.contains(habitID) {
            set.remove(habitID)
        } else {
            set.insert(habitID)
        }

        record.completedHabitIDs = Array(set)
        upsert(record)

        recalculateStreaks()
        persistAll()
    }

    func applyHabitEdits(_ editedHabits: [Habit]) {
        let trimmed: [Habit] = editedHabits.prefix(3).map { h in
            var copy = h
            let name = copy.name.trimmingCharacters(in: .whitespacesAndNewlines)
            copy.name = name.isEmpty ? "Habit" : name
            return copy
        }

        let existingIDs = Set(habits.map { $0.id })
        let newIDs = Set(trimmed.map { $0.id })
        let removedIDs = existingIDs.subtracting(newIDs)

        if !removedIDs.isEmpty {
            dayRecords = dayRecords.map { record in
                var r = record
                r.completedHabitIDs.removeAll { removedIDs.contains($0) }
                return r
            }
        }

        habits = trimmed

        refreshForNewDayIfNeeded()
        recalculateStreaks()
        persistAll()
    }

    func addHabit() {
        guard habits.count < 3 else { return }
        var updated = habits
        updated.append(Habit(name: "New Habit"))
        applyHabitEdits(updated)
    }

    func deleteHabits(at offsets: IndexSet) {
        var updated = habits
        updated.remove(atOffsets: offsets)
        applyHabitEdits(updated)
    }

    // MARK: - Persistence

    private func loadOrSeed() {
        let loadedHabits: [Habit]? = load([Habit].self, forKey: habitsKey)
        let loadedDayRecords: [DayRecord]? = load([DayRecord].self, forKey: dayRecordsKey)

        if let loadedHabits, !loadedHabits.isEmpty {
            habits = loadedHabits
            dayRecords = loadedDayRecords ?? []
            return
        }

        habits = [
            Habit(name: "Apply to 3 roles"),
            Habit(name: "Reach out to 1 recruiter"),
            Habit(name: "Practice 10 min interview Qs")
        ]

        dayRecords = []
        ensureDayRecordExists(for: Calendar.current.startOfDay(for: Date()))
        recalculateStreaks()
        persistAll()
    }

    private func persistAll() {
        save(habits, forKey: habitsKey)
        save(dayRecords, forKey: dayRecordsKey)
    }

    private func save<T: Codable>(_ value: T, forKey key: String) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(type, from: data)
    }

    // MARK: - DayRecord helpers

    private func dayRecord(for dayStart: Date) -> DayRecord? {
        let normalized = Calendar.current.startOfDay(for: dayStart)
        return dayRecords.first(where: { Calendar.current.startOfDay(for: $0.date) == normalized })
    }

    @discardableResult
    private func ensureDayRecordExists(for dayStart: Date) -> DayRecord {
        let normalized = Calendar.current.startOfDay(for: dayStart)
        if let existing = dayRecord(for: normalized) {
            return existing
        }
        let new = DayRecord(date: normalized, completedHabitIDs: [])
        upsert(new)
        return new
    }

    private func upsert(_ record: DayRecord) {
        let normalized = Calendar.current.startOfDay(for: record.date)
        if let idx = dayRecords.firstIndex(where: { Calendar.current.startOfDay(for: $0.date) == normalized }) {
            dayRecords[idx] = record
        } else {
            dayRecords.append(record)
            dayRecords.sort { $0.date < $1.date }
        }
    }

    // MARK: - Streaks

    private func recalculateStreaks() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        var completionByDay: [Date: Set<UUID>] = [:]
        for record in dayRecords {
            completionByDay[cal.startOfDay(for: record.date)] = Set(record.completedHabitIDs)
        }

        habits = habits.map { habit in
            var updated = habit
            var streak = 0
            var day = today
            while true {
                guard let completedSet = completionByDay[day], completedSet.contains(habit.id) else {
                    break
                }
                streak += 1
                guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
                day = cal.startOfDay(for: prev)
            }
            updated.streak = streak
            return updated
        }
    }
}
