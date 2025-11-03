import SwiftUI
import SwiftData

@main
struct CoroApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Conversation.self)
    }
}
