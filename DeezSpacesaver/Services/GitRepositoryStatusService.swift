import Foundation

struct GitUpstreamStatus: Equatable, Sendable {
    let ahead: Int
    let behind: Int
}

struct GitRepositoryStatus: Equatable, Sendable {
    enum State: Equatable, Sendable {
        case repository
        case notRepository
        case unavailable
    }

    let state: State
    let branch: String?
    let hasChanges: Bool
    let githubRemoteURL: String?
    let upstream: GitUpstreamStatus?

    static let notRepository = GitRepositoryStatus(
        state: .notRepository,
        branch: nil,
        hasChanges: false,
        githubRemoteURL: nil,
        upstream: nil
    )

    static let unavailable = GitRepositoryStatus(
        state: .unavailable,
        branch: nil,
        hasChanges: false,
        githubRemoteURL: nil,
        upstream: nil
    )
}

struct GitRepositoryStatusService: Sendable {
    func inspect(folders: [ProjectFolder]) async throws -> [UUID: GitRepositoryStatus] {
        try await Task.detached(priority: .utility) {
            var statuses: [UUID: GitRepositoryStatus] = [:]
            for folder in folders {
                try Task.checkCancellation()
                statuses[folder.id] = Self.inspect(path: folder.path)
            }
            return statuses
        }.value
    }

    static func isGitHubRemoteURL(_ value: String) -> Bool {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let url = URL(string: normalized), let host = url.host {
            return host == "github.com" || host.hasSuffix(".github.com")
        }
        return normalized.range(
            of: #"^(?:[^@/\s]+@)?github\.com:"#,
            options: .regularExpression
        ) != nil
    }

    static func parseAheadBehind(_ output: String) -> GitUpstreamStatus? {
        let counts = output.split(whereSeparator: \.isWhitespace).compactMap { Int($0) }
        guard counts.count == 2 else { return nil }
        return GitUpstreamStatus(ahead: counts[0], behind: counts[1])
    }

    private static func inspect(path: String) -> GitRepositoryStatus {
        do {
            let repositoryCheck = try runGit(path: path, arguments: ["rev-parse", "--is-inside-work-tree"])
            guard repositoryCheck.exitCode == 0,
                  repositoryCheck.output.trimmingCharacters(in: .whitespacesAndNewlines) == "true" else {
                return .notRepository
            }

            let branchResult = try runGit(
                path: path,
                arguments: ["symbolic-ref", "--quiet", "--short", "HEAD"]
            )
            let branch: String
            if branchResult.exitCode == 0 {
                branch = branchResult.output.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                let revision = try runGit(path: path, arguments: ["rev-parse", "--short", "HEAD"])
                let hash = revision.output.trimmingCharacters(in: .whitespacesAndNewlines)
                branch = hash.isEmpty ? "Detached HEAD" : "Detached \(hash)"
            }

            let workingTree = try runGit(
                path: path,
                arguments: ["status", "--porcelain=v1", "--untracked-files=normal"]
            )
            let hasChanges = !workingTree.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            let remotes = try runGit(
                path: path,
                arguments: ["config", "--get-regexp", #"^remote\..*\.url$"#]
            )
            let githubRemoteURL = remotes.output
                .split(whereSeparator: \.isNewline)
                .compactMap { line -> String? in
                    guard let separator = line.firstIndex(where: \.isWhitespace) else { return nil }
                    let url = String(line[line.index(after: separator)...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    return isGitHubRemoteURL(url) ? url : nil
                }
                .first

            let upstreamCheck = try runGit(
                path: path,
                arguments: ["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}"]
            )
            let upstream: GitUpstreamStatus?
            if upstreamCheck.exitCode == 0 {
                let counts = try runGit(
                    path: path,
                    arguments: ["rev-list", "--left-right", "--count", "HEAD...@{upstream}"]
                )
                upstream = counts.exitCode == 0 ? parseAheadBehind(counts.output) : nil
            } else {
                upstream = nil
            }

            return GitRepositoryStatus(
                state: .repository,
                branch: branch.isEmpty ? "Unknown branch" : branch,
                hasChanges: hasChanges,
                githubRemoteURL: githubRemoteURL,
                upstream: upstream
            )
        } catch {
            return .unavailable
        }
    }

    private static func runGit(path: String, arguments: [String]) throws -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path] + arguments

        var environment = ProcessInfo.processInfo.environment
        environment["GIT_OPTIONAL_LOCKS"] = "0"
        environment["GIT_TERMINAL_PROMPT"] = "0"
        environment["LC_ALL"] = "C"
        process.environment = environment

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        return CommandResult(
            exitCode: process.terminationStatus,
            output: String(data: data, encoding: .utf8) ?? ""
        )
    }

    private struct CommandResult {
        let exitCode: Int32
        let output: String
    }
}
