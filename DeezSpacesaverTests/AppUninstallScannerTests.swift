import XCTest
@testable import DeezSpacesaver

final class AppUninstallScannerTests: XCTestCase {
    func testIsProtectedBundleID() {
        XCTAssertTrue(AppUninstallScanner.isProtectedBundleID("com.apple.Safari"))
        XCTAssertTrue(AppUninstallScanner.isProtectedBundleID("com.apple.garageband10"))
        XCTAssertFalse(AppUninstallScanner.isProtectedBundleID("com.microsoft.VSCode"))
        XCTAssertFalse(AppUninstallScanner.isProtectedBundleID("notion.id"))
    }

    func testIsUnusedUsesLastLaunchWhenAvailable() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        let oldLaunch = Calendar.current.date(byAdding: .day, value: -120, to: Date())!
        let recentLaunch = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let recentModified = Date()

        XCTAssertTrue(AppUninstallScanner.isUnused(lastUsed: oldLaunch, modifiedDate: recentModified, cutoff: cutoff))
        XCTAssertFalse(AppUninstallScanner.isUnused(lastUsed: recentLaunch, modifiedDate: oldLaunch, cutoff: cutoff))
    }

    func testIsUnusedFallsBackToModifiedDateWithoutLaunchRecord() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        let oldModified = Calendar.current.date(byAdding: .day, value: -120, to: Date())!
        let recentModified = Calendar.current.date(byAdding: .day, value: -10, to: Date())!

        XCTAssertTrue(AppUninstallScanner.isUnused(lastUsed: nil, modifiedDate: oldModified, cutoff: cutoff))
        XCTAssertFalse(AppUninstallScanner.isUnused(lastUsed: nil, modifiedDate: recentModified, cutoff: cutoff))
        XCTAssertFalse(AppUninstallScanner.isUnused(lastUsed: nil, modifiedDate: nil, cutoff: cutoff))
    }

    func testRelatedSupportPathCandidatesIncludeCachesAndBundleIDSupport() {
        let library = URL(fileURLWithPath: "/Users/test/Library")
        let appURL = URL(fileURLWithPath: "/Applications/Example.app")
        let paths = AppUninstallScanner.relatedSupportPathCandidates(
            appURL: appURL,
            bundleID: "com.example.app",
            appName: "Example",
            library: library
        ).map(\.path)

        XCTAssertTrue(paths.contains("/Applications/Example.app"))
        XCTAssertTrue(paths.contains("/Users/test/Library/Application Support/com.example.app"))
        XCTAssertTrue(paths.contains("/Users/test/Library/Application Support/Example"))
        XCTAssertTrue(paths.contains("/Users/test/Library/Caches/com.example.app"))
        XCTAssertTrue(paths.contains("/Users/test/Library/Saved Application State/com.example.app.savedState"))
    }

    func testDetailTextIncludesSupportCount() {
        let lastUsed = Calendar.current.date(byAdding: .day, value: -120, to: Date())!
        let detail = AppUninstallScanner.detailText(lastUsed: lastUsed, modifiedDate: nil, supportCount: 2)
        XCTAssertTrue(detail.contains("Last used"))
        XCTAssertTrue(detail.contains("2 support locations"))
    }

    func testDetailTextWithoutLaunchRecordUsesModifiedDate() {
        let modified = Calendar.current.date(byAdding: .day, value: -100, to: Date())!
        let detail = AppUninstallScanner.detailText(lastUsed: nil, modifiedDate: modified, supportCount: 0)
        XCTAssertTrue(detail.contains("No launch record"))
        XCTAssertTrue(detail.contains("bundle modified"))
    }
}
