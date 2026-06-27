import XCTest
@testable import DeezSpacesaver

final class FullDiskAccessServiceTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = try XCTUnwrap(
            FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
        )
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        tempDirectory = nil
    }

    func testCanListProtectedDirectoryReturnsFalseWhenPathMissing() throws {
        let root = try XCTUnwrap(tempDirectory)
        let missingPath = root.appendingPathComponent("missing").path
        XCTAssertFalse(FullDiskAccessService.canListProtectedDirectory(at: missingPath))
    }

    func testCanListProtectedDirectoryReturnsFalseWhenPathIsFile() throws {
        let root = try XCTUnwrap(tempDirectory)
        let fileURL = root.appendingPathComponent("not-a-directory.txt")
        try Data("test".utf8).write(to: fileURL)
        XCTAssertFalse(FullDiskAccessService.canListProtectedDirectory(at: fileURL.path))
    }

    func testCanListProtectedDirectoryReturnsTrueWhenDirectoryIsReadable() throws {
        let root = try XCTUnwrap(tempDirectory)
        let directoryURL = root.appendingPathComponent("readable", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try Data("child".utf8).write(to: directoryURL.appendingPathComponent("child.txt"))

        XCTAssertTrue(FullDiskAccessService.canListProtectedDirectory(at: directoryURL.path))
    }

    func testProbeFullDiskAccessReturnsTrueWhenAnyProbeSucceeds() throws {
        let home = try XCTUnwrap(tempDirectory)
        let mailPath = home.appendingPathComponent("Library/Mail")
        try FileManager.default.createDirectory(at: mailPath, withIntermediateDirectories: true)

        XCTAssertTrue(FullDiskAccessService.probeFullDiskAccess(homeDirectory: home))
    }

    func testProbeFullDiskAccessReturnsFalseWhenNoProbeSucceeds() throws {
        let home = try XCTUnwrap(tempDirectory)
        XCTAssertFalse(FullDiskAccessService.probeFullDiskAccess(homeDirectory: home))
    }
}
