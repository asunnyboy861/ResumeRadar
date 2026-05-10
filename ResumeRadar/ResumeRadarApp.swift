import SwiftUI
import SwiftData

@main
struct ResumeRadarApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [JobDescription.self, Candidate.self, RedFlag.self]) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                print("ModelContainer error: \(error.localizedDescription)")
            }
        }
    }
}
