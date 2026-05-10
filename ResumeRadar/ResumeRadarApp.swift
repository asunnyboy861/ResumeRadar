import SwiftUI
import SwiftData

@main
struct ResumeRadarApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [JobDescription.self, Candidate.self, RedFlag.self])
    }
}
