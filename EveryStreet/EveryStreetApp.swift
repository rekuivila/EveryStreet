import SwiftUI
import SwiftData

@main
struct EveryStreetApp: App {
    @State private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authViewModel)
        }
        .modelContainer(for: [Walk.self, AppUser.self])
    }
}
