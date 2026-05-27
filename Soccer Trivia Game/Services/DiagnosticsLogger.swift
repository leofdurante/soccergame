import Foundation
import os

/// Lightweight persistent logger for user-facing diagnostics.
@MainActor
final class DiagnosticsLogger {
    static let shared = DiagnosticsLogger()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Soccerholic", category: "auth")
    private let defaults = UserDefaults.standard
    private let key = "diagnostics.auth.logs"
    private let maxEntries = 200
    
    private init() {}
    
    func logAuth(_ message: String) {
        let stamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(stamp)] \(message)"
        logger.log("\(line, privacy: .public)")
        
        var logs = defaults.stringArray(forKey: key) ?? []
        logs.append(line)
        if logs.count > maxEntries {
            logs.removeFirst(logs.count - maxEntries)
        }
        defaults.set(logs, forKey: key)
    }
    
    func latestAuthLog() -> String? {
        defaults.stringArray(forKey: key)?.last
    }
}

