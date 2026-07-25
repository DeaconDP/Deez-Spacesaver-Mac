import XCTest
@testable import DeezSpacesaver

final class ProjectSuggestionServiceTests: XCTestCase {
    func testRanksNameMatchesAndRemovesNestedDuplicates() async throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let exact = root.appendingPathComponent("Apollo", isDirectory: true)
        let nested = exact.appendingPathComponent("Apollo-backup", isDirectory: true)
        let unrelated = root.appendingPathComponent("OtherProject", isDirectory: true)
        try createProjectDirectory(exact)
        try createProjectDirectory(nested)
        try createProjectDirectory(unrelated)

        let suggestions = try await ProjectSuggestionService().suggest(
            projectName: "Apollo",
            roots: [root.path],
            associatedPaths: []
        )

        XCTAssertEqual(suggestions.first?.path, exact.path)
        XCTAssertFalse(suggestions.contains { $0.path == nested.path })
        XCTAssertFalse(suggestions.contains { $0.path == unrelated.path })
    }

    func testExcludesAlreadyAssociatedFolder() async throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let candidate = root.appendingPathComponent("Apollo-backup", isDirectory: true)
        try createProjectDirectory(candidate)

        let suggestions = try await ProjectSuggestionService().suggest(
            projectName: "Apollo",
            roots: [root.path],
            associatedPaths: [candidate.path]
        )

        XCTAssertTrue(suggestions.isEmpty)
    }

    func testFolderScannerIncludesHiddenProjectContent() async throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let gitObjects = root
            .appendingPathComponent(".git", isDirectory: true)
            .appendingPathComponent("objects", isDirectory: true)
        try FileManager.default.createDirectory(at: gitObjects, withIntermediateDirectories: true)
        try Data(repeating: 1, count: 8_192)
            .write(to: gitObjects.appendingPathComponent("object"))

        let folder = ProjectFolder(path: root.path)
        let measurements = try await ProjectFolderScanner().measure(folders: [folder])

        XCTAssertEqual(measurements.count, 1)
        XCTAssertEqual(measurements[0].availability, .available)
        XCTAssertGreaterThan(measurements[0].allocatedBytes ?? 0, 0)
    }

    private func createProjectDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: url.appendingPathComponent(".git", isDirectory: true),
            withIntermediateDirectories: true
        )
    }

    private func temporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
