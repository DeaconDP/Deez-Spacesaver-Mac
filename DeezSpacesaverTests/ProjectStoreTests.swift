import XCTest
@testable import DeezSpacesaver

final class ProjectStoreTests: XCTestCase {
    @MainActor
    func testPersistsProjectsFoldersTagsAndRoots() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("projects.json")

        let store = ProjectStore(fileURL: fileURL)
        let project = try store.createProject(named: "Apollo")
        try store.addFolder(
            path: directory.appendingPathComponent("Apollo Backup").path,
            tag: ProjectFolderTag("Archive"),
            to: project.id
        )
        try store.setSearchRoots([directory.path, directory.path])

        let reloaded = ProjectStore(fileURL: fileURL)
        XCTAssertEqual(reloaded.projects.count, 1)
        XCTAssertEqual(reloaded.projects.first?.name, "Apollo")
        XCTAssertEqual(reloaded.projects.first?.folders.first?.tag.name, "Archive")
        XCTAssertEqual(reloaded.searchRoots, [directory.path])
    }

    @MainActor
    func testRejectsDuplicateFolderWithinProject() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ProjectStore(fileURL: directory.appendingPathComponent("projects.json"))
        let project = try store.createProject(named: "Apollo")

        try store.addFolder(path: directory.path, tag: .working, to: project.id)
        XCTAssertThrowsError(
            try store.addFolder(path: directory.path, tag: .backup, to: project.id)
        ) { error in
            XCTAssertEqual(error as? ProjectStoreError, .duplicateFolder)
        }
    }

    @MainActor
    func testRejectsOverlappingProjectFolders() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let parent = directory.appendingPathComponent("Apollo", isDirectory: true)
        let child = parent.appendingPathComponent("Backup", isDirectory: true)
        try FileManager.default.createDirectory(at: child, withIntermediateDirectories: true)
        let store = ProjectStore(fileURL: directory.appendingPathComponent("projects.json"))
        let project = try store.createProject(named: "Apollo")

        try store.addFolder(path: parent.path, tag: .working, to: project.id)
        XCTAssertThrowsError(
            try store.addFolder(path: child.path, tag: .backup, to: project.id)
        ) { error in
            XCTAssertEqual(error as? ProjectStoreError, ProjectStoreError.overlappingFolder)
        }
    }

    @MainActor
    func testMalformedDocumentRecoversWithVisibleError() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("projects.json")
        try Data("not-json".utf8).write(to: fileURL)

        let store = ProjectStore(fileURL: fileURL)
        XCTAssertTrue(store.projects.isEmpty)
        XCTAssertNotNil(store.lastError)
    }

    func testProjectFolderSortingFieldsDirectionsAndFallbacks() {
        let alpha = ProjectFolder(
            path: "/Work/Alpha",
            tag: .backup,
            allocatedBytes: 100
        )
        let beta = ProjectFolder(
            path: "/Archive/Beta",
            tag: .working,
            allocatedBytes: nil
        )
        let gamma = ProjectFolder(
            path: "/Work/Gamma",
            tag: .backup,
            allocatedBytes: 300
        )
        let folders = [beta, gamma, alpha]

        XCTAssertEqual(
            ProjectFolderSortField.size.sorted(folders, ascending: false).map(\.name),
            ["Gamma", "Alpha", "Beta"]
        )
        XCTAssertEqual(
            ProjectFolderSortField.size.sorted(folders, ascending: true).map(\.name),
            ["Alpha", "Gamma", "Beta"]
        )
        XCTAssertEqual(
            ProjectFolderSortField.tag.sorted(folders, ascending: true).map(\.name),
            ["Alpha", "Gamma", "Beta"]
        )
        XCTAssertEqual(
            ProjectFolderSortField.name.sorted(folders, ascending: true).map(\.name),
            ["Alpha", "Beta", "Gamma"]
        )
        XCTAssertEqual(
            ProjectFolderSortField.name.sorted(folders, ascending: false).map(\.name),
            ["Gamma", "Beta", "Alpha"]
        )
        XCTAssertEqual(
            ProjectFolderSortField.location.sorted(folders, ascending: true).map(\.name),
            ["Beta", "Alpha", "Gamma"]
        )

        let sameName = [
            ProjectFolder(path: "/B/Same", tag: .working),
            ProjectFolder(path: "/A/Same", tag: .working)
        ]
        XCTAssertEqual(
            ProjectFolderSortField.name.sorted(sameName, ascending: false).map(\.path),
            ["/A/Same", "/B/Same"]
        )
    }

    private func temporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
