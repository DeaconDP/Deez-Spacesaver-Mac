import XCTest
@testable import DeezSpacesaver

final class SafetyGuardTests: XCTestCase {
    func testDeniesSystemPaths() {
        XCTAssertTrue(SafetyGuard.isDenied("/System/Library"))
        XCTAssertTrue(SafetyGuard.isDenied("/usr/bin/python3"))
        XCTAssertFalse(SafetyGuard.isDenied("/Users/test/Documents/file.pdf"))
    }

    func testExcludePaths() {
        let excludes = ["/Users/test/Projects"]
        XCTAssertTrue(SafetyGuard.isExcluded("/Users/test/Projects/app", excludePaths: excludes))
        XCTAssertFalse(SafetyGuard.isExcluded("/Users/test/Downloads", excludePaths: excludes))
    }

    func testLargeBatchConfirmation() {
        XCTAssertFalse(SafetyGuard.requiresLargeBatchConfirmation(itemCount: 10, totalBytes: 1_000_000))
        XCTAssertTrue(SafetyGuard.requiresLargeBatchConfirmation(itemCount: 501, totalBytes: 1_000))
        XCTAssertTrue(SafetyGuard.requiresLargeBatchConfirmation(itemCount: 10, totalBytes: 11 * 1_024 * 1_024 * 1_024))
    }

    func testApplicationsRequiresUninstallCategory() {
        let item = ScannableItem(path: "/Applications/SomeApp.app", sizeBytes: 100, categoryID: "downloads")
        XCTAssertFalse(SafetyGuard.canDelete(item: item, category: .downloads, excludePaths: []))
        XCTAssertTrue(SafetyGuard.canDelete(item: item, category: .appUninstall, excludePaths: []))
    }
}
