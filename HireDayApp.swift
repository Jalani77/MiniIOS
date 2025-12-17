import SwiftUI

@main
struct HireDayApp: App {
    @StateObject private var viewModel = HabitTrackerViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView(viewModel: viewModel)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
