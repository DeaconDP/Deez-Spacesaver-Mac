import XCTest
@testable import DeezSpacesaver

final class GitRepositoryStatusServiceTests: XCTestCase {
    func testReportsNonRepository() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let folder = ProjectFolder(path: directory.path)

        let statuses = try await GitRepositoryStatusService().inspect(folders: [folder])

        XCTAssertEqual(statuses[folder.id], .notRepository)
    }

    func testReportsBranchCleanlinessAndGitHubRemote() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try runGit(["init"], in: directory)
        try runGit(["symbolic-ref", "HEAD", "refs/heads/main"], in: directory)
        try runGit(["remote", "add", "origin", "git@github.com:worldbuild-io/example.git"], in: directory)
        let folder = ProjectFolder(path: directory.path)
        let service = GitRepositoryStatusService()

        let clean = try await service.inspect(folders: [folder])[folder.id]
        XCTAssertEqual(clean?.state, .repository)
        XCTAssertEqual(clean?.branch, "main")
        XCTAssertEqual(clean?.hasChanges, false)
        XCTAssertEqual(clean?.githubRemoteURL, "git@github.com:worldbuild-io/example.git")
        XCTAssertNil(clean?.upstream)

        try Data("change".utf8).write(to: directory.appendingPathComponent("change.txt"))
        let changed = try await service.inspect(folders: [folder])[folder.id]
        XCTAssertEqual(changed?.hasChanges, true)
    }

    func testRecognizesGitHubRemoteURLForms() {
        XCTAssertTrue(GitRepositoryStatusService.isGitHubRemoteURL(
            "https://github.com/worldbuild-io/example.git"
        ))
        XCTAssertTrue(GitRepositoryStatusService.isGitHubRemoteURL(
            "git@github.com:worldbuild-io/example.git"
        ))
        XCTAssertTrue(GitRepositoryStatusService.isGitHubRemoteURL(
            "ssh://git@github.com/worldbuild-io/example.git"
        ))
        XCTAssertFalse(GitRepositoryStatusService.isGitHubRemoteURL(
            "https://gitlab.com/worldbuild-io/example.git"
        ))
    }

    func testParsesAheadBehindCounts() {
        XCTAssertEqual(
            GitRepositoryStatusService.parseAheadBehind("2\t3\n"),
            GitUpstreamStatus(ahead: 2, behind: 3)
        )
        XCTAssertNil(GitRepositoryStatusService.parseAheadBehind("unknown"))
    }

    private func temporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func runGit(_ arguments: [String], in directory: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", directory.path] + arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: "GitRepositoryStatusServiceTests",
                code: Int(process.terminationStatus)
            )
        }
    }
}
