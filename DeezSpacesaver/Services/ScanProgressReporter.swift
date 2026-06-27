import Foundation

/// Thread-safe progress reporter; scanners call this from background work.
/// The `update` closure is responsible for hopping to `@MainActor` for UI state.
final class ScanProgressReporter: @unchecked Sendable {
    private let update: @Sendable (Double?, String) -> Void
    private let lock = NSLock()
    private var lastReport = Date.distantPast
    private let minInterval: TimeInterval = 0.1

    init(update: @escaping @Sendable (Double?, String) -> Void) {
        self.update = update
    }

    func report(progress: Double?, message: String) {
        lock.lock()
        defer { lock.unlock() }
        let now = Date()
        guard now.timeIntervalSince(lastReport) >= minInterval else { return }
        lastReport = now
        let clamped = progress.map { min(max($0, 0), 1) }
        update(clamped, message)
    }

    func reportImmediate(progress: Double?, message: String) {
        lock.lock()
        defer { lock.unlock() }
        lastReport = Date()
        let clamped = progress.map { min(max($0, 0), 1) }
        update(clamped, message)
    }
}
