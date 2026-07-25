import Foundation
import XCTest
@testable import DeezSpacesaver

final class ApplicationInventoryServiceTests: XCTestCase {
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

    func testDiscoversNestedAppsButDoesNotDescendIntoAppBundles() throws {
        let utilities = applicationsRoot.appendingPathComponent("Utilities", isDirectory: true)
        try makeApp(named: "Editor", in: applicationsRoot, bundleID: "test.editor", bytes: 4_096)
        let utility = try makeApp(named: "Utility", in: utilities, bundleID: "test.utility", bytes: 4_096)
        try makeApp(named: "NestedHelper", in: utility, bundleID: "test.helper", bytes: 4_096)
        try makeApp(named: ".Hidden", in: applicationsRoot, bundleID: "test.hidden", bytes: 4_096)

        let names = ApplicationInventoryService.discoverApplications(
            under: applicationsRoot
        ).map(\.lastPathComponent)

        XCTAssertEqual(Set(names), Set(["Editor.app", "Utility.app"]))
    }

    func testLoadSortsLargestFirstAndKeepsMissingLastOpenedMetadata() async throws {
        try makeApp(named: "Small", in: applicationsRoot, bundleID: "test.small", bytes: 4_096)
        try makeApp(named: "Large", in: applicationsRoot, bundleID: "test.large", bytes: 1_048_576)

        let service = ApplicationInventoryService(
            applicationsRoot: applicationsRoot,
            currentApplicationPath: "/not/the/current/app"
        )
        let applications = try await service.load()

        XCTAssertEqual(applications.map(\.name), ["Large", "Small"])
        XCTAssertGreaterThan(applications[0].sizeBytes, applications[1].sizeBytes)
        XCTAssertNil(applications.first(where: { $0.name == "Large" })?.lastOpenedDate)
    }

    func testRemovalAvailabilityProtectsCurrentAndSystemApps() throws {
        let current = try makeApp(
            named: "Current",
            in: applicationsRoot,
            bundleID: "test.current",
            bytes: 4_096
        )
        let system = try makeApp(
            named: "System",
            in: applicationsRoot,
            bundleID: "com.apple.test",
            bytes: 4_096
        )

        XCTAssertEqual(
            ApplicationInventoryService.removalAvailability(
                for: current,
                bundleIdentifier: "test.current",
                applicationsRoot: applicationsRoot,
                currentApplicationPath: current.path,
                runningBundleIdentifiers: []
            ),
            .currentApplication
        )
        XCTAssertEqual(
            ApplicationInventoryService.removalAvailability(
                for: system,
                bundleIdentifier: "com.apple.test",
                applicationsRoot: applicationsRoot,
                currentApplicationPath: current.path,
                runningBundleIdentifiers: []
            ),
            .protectedSystemApplication
        )
    }

    @discardableResult
    private func makeApp(
        named name: String,
        in parent: URL,
        bundleID: String,
        bytes: Int
    ) throws -> URL {
        let appURL = parent.appendingPathComponent("\(name).app", isDirectory: true)
        let contents = appURL.appendingPathComponent("Contents", isDirectory: true)
        let resources = contents.appendingPathComponent("Resources", isDirectory: true)
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
        let plist = try PropertyListSerialization.data(
            fromPropertyList: ["CFBundleIdentifier": bundleID],
            format: .xml,
            options: 0
        )
        try plist.write(to: contents.appendingPathComponent("Info.plist"))
        try Data(repeating: 1, count: bytes).write(
            to: resources.appendingPathComponent("payload.bin")
        )
        return appURL
    }
}
