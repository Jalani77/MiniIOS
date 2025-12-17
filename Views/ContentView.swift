import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel

    @Environment(\.scenePhase) private var scenePhase
    @State private var isEditingHabits = false

    private let dayRefreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                habitsSection
                chartSection
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit Habits") {
                    isEditingHabits = true
                }
            }
        }
        .sheet(isPresented: $isEditingHabits) {
            HabitEditView(viewModel: viewModel)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.refreshForNewDayIfNeeded()
            }
        }
        .onReceive(dayRefreshTimer) { _ in
            viewModel.refreshForNewDayIfNeeded()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("HireDay – Interview Habits")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)

            Text(viewModel.todayDateText)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today")
                .font(.title3.bold())

            VStack(spacing: 10) {
                ForEach(viewModel.habits) { habit in
                    HabitRow(
                        name: habit.name,
                        isDone: viewModel.isHabitDoneToday(habit.id),
                        streak: habit.streak,
                        onToggle: {
                            viewModel.toggleHabitToday(habit.id)
                        }
                    )
                }

                if viewModel.habits.isEmpty {
                    Text("Add up to 3 habits in Edit Habits.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                }
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Last 7 Days")
                .font(.title3.bold())

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(viewModel.last7Days) { day in
                    DayBar(day: day)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
}

private struct HabitRow: View {
    let name: String
    let isDone: Bool
    let streak: Int
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(isDone ? Color.green : Color.secondary)
                    .accessibilityLabel(isDone ? "Mark not done" : "Mark done")
            }
            .buttonStyle(.plain)

            Text(name)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            Spacer(minLength: 8)

            Label("\(streak)-day streak", systemImage: "flame.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(streak > 0 ? Color.orange : Color.secondary)
                .labelStyle(.titleAndIcon)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct DayBar: View {
    let day: HabitTrackerViewModel.DaySummary

    private let maxHeight: CGFloat = 72
    private let minHeight: CGFloat = 6

    var body: some View {
        let height = barHeight(for: day.completedCount)
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(fillColor(for: day.completedCount))
                .frame(width: 18, height: height)
                .frame(height: maxHeight, alignment: .bottom)

            Text(day.dayLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 20)
        .accessibilityLabel("\(day.dayLabel): \(day.completedCount) completed")
    }

    private func barHeight(for count: Int) -> CGFloat {
        let clamped = min(max(count, 0), 3)
        guard clamped > 0 else { return minHeight }
        let t = CGFloat(clamped) / 3
        return minHeight + (maxHeight - minHeight) * t
    }

    private func fillColor(for count: Int) -> Color {
        count > 0 ? Color.accentColor.opacity(0.85) : Color.secondary.opacity(0.25)
    }
}
