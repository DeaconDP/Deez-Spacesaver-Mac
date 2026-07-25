import Foundation

struct ProjectFolderSuggestion: Identifiable, Hashable, Sendable {
    let path: String
    let score: Int
    let reasons: [String]

    var id: String { path.lowercased() }
    var name: String { URL(fileURLWithPath: path).lastPathComponent }
}

struct ProjectSuggestionService: Sendable {
    typealias ProgressHandler = @Sendable (_ inspected: Int, _ currentFolder: String) -> Void

    private static let ignoredDirectoryNames: Set<String> = [
        ".build", ".git", ".svn", "build", "cache", "caches", "deriveddata",
        "dist", "library", "node_modules", "pods", "tmp", "vendor"
    ]

    private static let markerNames: Set<String> = [
        ".git", "package.json", "Package.swift", "Cargo.toml", "pyproject.toml",
        "Gemfile", "Podfile", "composer.json", "go.mod"
    ]

    func suggest(
        projectName: String,
        roots: [String],
        associatedPaths: [String],
        maxDepth: Int = 6,
        progress: ProgressHandler? = nil
    ) async throws -> [ProjectFolderSuggestion] {
        try await Task.detached(priority: .userInitiated) {
            try Self.scan(
                projectName: projectName,
                roots: roots,
                associatedPaths: associatedPaths,
                maxDepth: maxDepth,
                progress: progress
            )
        }.value
    }

    private static func scan(
        projectName: String,
        roots: [String],
        associatedPaths: [String],
        maxDepth: Int,
        progress: ProgressHandler?
    ) throws -> [ProjectFolderSuggestion] {
        let fileManager = FileManager.default
        let normalizedProject = normalized(projectName)
        let projectTokens = tokens(projectName)
        let associated = Set(associatedPaths.map {
            ($0 as NSString).standardizingPath.lowercased()
        })
        var inspected = 0
        var candidates: [ProjectFolderSuggestion] = []

        for rootPath in roots {
            try Task.checkCancellation()
            let normalizedRoot = (rootPath as NSString).standardizingPath
            let root = URL(fileURLWithPath: normalizedRoot, isDirectory: true)
            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey],
                options: [.skipsHiddenFiles],
                errorHandler: { _, _ in true }
            ) else {
                continue
            }

            for case let url as URL in enumerator {
                try Task.checkCancellation()
                guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey]),
                      values.isDirectory == true else {
                    continue
                }

                let relative = url.path.dropFirst(normalizedRoot.count)
                let depth = relative.filter { $0 == "/" }.count
                let lowerName = url.lastPathComponent.lowercased()
                if depth > maxDepth
                    || ignoredDirectoryNames.contains(lowerName)
                    || values.isPackage == true {
                    enumerator.skipDescendants()
                    continue
                }

                inspected += 1
                if inspected.isMultiple(of: 25) {
                    progress?(inspected, url.lastPathComponent)
                }

                let path = (url.path as NSString).standardizingPath
                guard !associated.contains(path.lowercased()) else { continue }
                guard let suggestion = score(
                    url: url,
                    normalizedProject: normalizedProject,
                    projectTokens: projectTokens,
                    fileManager: fileManager
                ) else {
                    continue
                }
                candidates.append(suggestion)
            }
        }

        progress?(inspected, "Finishing suggestions")
        return removeNestedDuplicates(
            candidates.sorted {
                if $0.score != $1.score { return $0.score > $1.score }
                return $0.path.localizedCaseInsensitiveCompare($1.path) == .orderedAscending
            }
        )
    }

    private static func score(
        url: URL,
        normalizedProject: String,
        projectTokens: [String],
        fileManager: FileManager
    ) -> ProjectFolderSuggestion? {
        let normalizedName = normalized(url.lastPathComponent)
        var score = 0
        var reasons: [String] = []

        if !normalizedProject.isEmpty && normalizedName == normalizedProject {
            score += 100
            reasons.append("Folder name matches the project")
        } else if !normalizedProject.isEmpty && normalizedName.contains(normalizedProject) {
            score += 70
            reasons.append("Folder name contains the project name")
        } else {
            let matchedTokens = projectTokens.filter { normalizedName.contains($0) }
            if !matchedTokens.isEmpty {
                score += matchedTokens.count * 20
                reasons.append("Folder name shares project keywords")
            }
        }

        let markers = projectMarkers(at: url, fileManager: fileManager)
        if !markers.isEmpty {
            score += min(30, markers.count * 10)
            reasons.append("Contains \(markers.prefix(2).joined(separator: " and "))")
        }

        guard score >= 40 else { return nil }
        return ProjectFolderSuggestion(path: url.path, score: score, reasons: reasons)
    }

    private static func projectMarkers(at url: URL, fileManager: FileManager) -> [String] {
        guard let names = try? fileManager.contentsOfDirectory(atPath: url.path) else { return [] }
        return names.filter { name in
            markerNames.contains(name)
                || name.hasSuffix(".xcodeproj")
                || name.hasSuffix(".xcworkspace")
        }.sorted()
    }

    private static func removeNestedDuplicates(
        _ suggestions: [ProjectFolderSuggestion]
    ) -> [ProjectFolderSuggestion] {
        var accepted: [ProjectFolderSuggestion] = []
        for suggestion in suggestions {
            let path = suggestion.path.lowercased() + "/"
            let overlaps = accepted.contains { existing in
                let existingPath = existing.path.lowercased() + "/"
                return path.hasPrefix(existingPath) || existingPath.hasPrefix(path)
            }
            if !overlaps {
                accepted.append(suggestion)
            }
        }
        return accepted
    }

    private static func normalized(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    private static func tokens(_ value: String) -> [String] {
        value
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { $0.count >= 3 }
    }
}
