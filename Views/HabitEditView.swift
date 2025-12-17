import SwiftUI

struct HabitEditView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var draftHabits: [Habit]

    init(viewModel: HabitTrackerViewModel) {
        self.viewModel = viewModel
        _draftHabits = State(initialValue: viewModel.habits)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach($draftHabits) { $habit in
                        TextField("Habit name", text: $habit.name)
                            .textInputAutocapitalization(.sentences)
                            .autocorrectionDisabled(false)
                    }
                    .onDelete { offsets in
                        draftHabits.remove(atOffsets: offsets)
                    }

                    Button {
                        addHabit()
                    } label: {
                        Label("Add Habit", systemImage: "plus")
                    }
                    .disabled(draftHabits.count >= 3)
                } footer: {
                    Text("Up to 3 habits total.")
                }
            }
            .navigationTitle("Edit Habits")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.applyHabitEdits(draftHabits)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func addHabit() {
        guard draftHabits.count < 3 else { return }
        draftHabits.append(Habit(name: "New Habit"))
    }
}
