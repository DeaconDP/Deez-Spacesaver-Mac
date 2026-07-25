import Foundation
import XCTest
@testable import DeezSpacesaver

private struct FakeTrashService: TrashServicing {
    let failingPaths: Set<String>

    func moveToTrash(items: [ScannableItem]) async -> (
        succeeded: [ScannableItem],
        failed: [(ScannableItem, String)]
    ) {
        let succeeded = items.filter { !failingPaths.contains($0.path) }
        let failed = items
            .filter { failingPaths.contains($0.path) }
            .map { ($0, "Test failure") }
        return (succeeded, failed)
    }

    func emptyTrash() throws {}
}

final class CleanupActionServiceTests: XCTestCase {
    private var temporaryDirectory: URL!
    private var applicationsRoot: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        applicationsRoot = temporaryDirectory.appendingPathComponent("Applications", isDirectory: true)
        try FileManager.default.createDirectory(
            at: applicationsRoot,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temporaryDirectory)
    }

    func testRemovesSingleAppBundleWithoutRelatedData() async throws {
        let application = try makeApplication(named: "Editor", bundleID: "test.editor")
        let service = CleanupActionService(trashService: FakeTrashService(failingPaths: []))

        let result = await service.removeApplicationBundles(
            [application],
            applicationsRoot: applicationsRoot,
            currentApplicationPath: "/not/the/current/app"
        )

        XCTAssertEqual(result.succeeded.map(\.path), [application.path])
        XCTAssertTrue(result.failed.isEmpty)
    }

    func testBatchRemovalPreservesPerAppFailures() async throws {
        let first = try makeApplication(named: "First", bundleID: "test.first")
        let second = try makeApplication(named: "Second", bundleID: "test.second")
        let service = CleanupActionService(
            trashService: FakeTrashService(failingPaths: [second.path])
        )

        let result = await service.removeApplicationBundles(
            [first, second],
            applicationsRoot: applicationsRoot,
            currentApplicationPath: "/not/the/current/app"
        )

        XCTAssertEqual(result.succeeded.map(\.path), [first.path])
        XCTAssertEqual(result.failed.map { $0.0.path }, [second.path])
        XCTAssertEqual(result.failed.first?.1, "Test failure")
    }

    func testRejectsAppThatResolvesOutsideApplicationsRoot() async throws {
        let outsideRoot = temporaryDirectory.appendingPathComponent("Outside", isDirectory: true)
        try FileManager.default.createDirectory(at: outsideRoot, withIntermediateDirectories: true)
        let outside = try makeApplication(
            named: "Outside",
            bundleID: "test.outside",
            parent: outsideRoot
        )
        let service = CleanupActionService(trashService: FakeTrashService(failingPaths: []))

        let result = await service.removeApplicationBundles(
            [outside],
            applicationsRoot: applicationsRoot,
            currentApplicationPath: "/not/the/current/app"
        )

        XCTAssertTrue(result.succeeded.isEmpty)
        XCTAssertEqual(result.failed.map { $0.0.path }, [outside.path])
    }

    private func makeApplication(
        named name: String,
        bundleID: String,
        parent: URL? = nil
    ) throws -> InstalledApplication {
        let appURL = (parent ?? applicationsRoot)
            .appendingPathComponent("\(name).app", isDirectory: true)
        let contents = appURL.appendingPathComponent("Contents", isDirectory: true)
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        let plist = try PropertyListSerialization.data(
            fromPropertyList: ["CFBundleIdentifier": bundleID],
            format: .xml,
            options: 0
        )
        try plist.write(to: contents.appendingPathComponent("Info.plist"))
        return InstalledApplication(
            path: appURL.path,
            name: name,
            bundleIdentifier: bundleID,
            sizeBytes: 1_024,
            lastOpenedDate: nil,
            removalAvailability: .removable
        )
    }
}
