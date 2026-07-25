import Foundation

enum ProjectStoreError: LocalizedError, Equatable {
    case emptyProjectName
    case emptyTag
    case projectNotFound
    case folderNotFound
    case duplicateFolder
    case overlappingFolder

    var errorDescription: String? {
        switch self {
        case .emptyProjectName:
            return "Enter a project name."
        case .emptyTag:
            return "Enter a tag name."
        case .projectNotFound:
            return "The selected project no longer exists."
        case .folderNotFound:
            return "The selected folder no longer exists."
        case .duplicateFolder:
            return "That folder is already associated with this project."
        case .overlappingFolder:
            return "That folder overlaps another folder already associated with this project."
        }
    }
}

@MainActor
final class ProjectStore: ObservableObject {
    @Published private(set) var projects: [ManagedProject] = []
    @Published private(set) var searchRoots: [String] = []
    @Published private(set) var lastError: String?

    private struct Document: Codable {
        let version: Int
        var projects: [ManagedProject]
        var searchRoots: [String]
    }

    private let fileURL: URL
    private let fileManager: FileManager

    init(fileURL: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultFileURL(fileManager: fileManager)
        load()
    }

    @discardableResult
    func createProject(named name: String) throws -> ManagedProject {
        let project = ManagedProject(name: name)
        guard !project.name.isEmpty else { throw ProjectStoreError.emptyProjectName }
        projects.append(project)
        try persist()
        return project
    }

    func renameProject(id: UUID, to name: String) throws {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { throw ProjectStoreError.emptyProjectName }
        guard let index = projects.firstIndex(where: { $0.id == id }) else {
            throw ProjectStoreError.projectNotFound
        }
        projects[index].name = normalized
        try persist()
    }

    func deleteProject(id: UUID) throws {
        guard projects.contains(where: { $0.id == id }) else {
            throw ProjectStoreError.projectNotFound
        }
        projects.removeAll { $0.id == id }
        try persist()
    }

    func addFolder(path: String, tag: ProjectFolderTag, to projectID: UUID) throws {
        guard !tag.name.isEmpty else { throw ProjectStoreError.emptyTag }
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else {
            throw ProjectStoreError.projectNotFound
        }
        let normalizedPath = Self.canonicalPath(path)
        guard !projects[index].folders.contains(where: {
            Self.canonicalPath($0.path).caseInsensitiveCompare(normalizedPath) == .orderedSame
        }) else {
            throw ProjectStoreError.duplicateFolder
        }
        guard !projects[index].folders.contains(where: {
            Self.pathsOverlap(Self.canonicalPath($0.path), normalizedPath)
        }) else {
            throw ProjectStoreError.overlappingFolder
        }
        projects[index].folders.append(ProjectFolder(path: normalizedPath, tag: tag))
        try persist()
    }

    func removeFolder(id folderID: UUID, from projectID: UUID) throws {
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }) else {
            throw ProjectStoreError.projectNotFound
        }
        guard projects[projectIndex].folders.contains(where: { $0.id == folderID }) else {
            throw ProjectStoreError.folderNotFound
        }
        projects[projectIndex].folders.removeAll { $0.id == folderID }
        try persist()
    }

    func setTag(_ tag: ProjectFolderTag, for folderID: UUID, in projectID: UUID) throws {
        guard !tag.name.isEmpty else { throw ProjectStoreError.emptyTag }
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }) else {
            throw ProjectStoreError.projectNotFound
        }
        guard let folderIndex = projects[projectIndex].folders.firstIndex(where: { $0.id == folderID }) else {
            throw ProjectStoreError.folderNotFound
        }
        projects[projectIndex].folders[folderIndex].tag = tag
        try persist()
    }

    func updateFolderMeasurement(
        folderID: UUID,
        projectID: UUID,
        allocatedBytes: Int64?,
        availability: ProjectFolderAvailability,
        scannedAt: Date
    ) throws {
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }) else {
            throw ProjectStoreError.projectNotFound
        }
        guard let folderIndex = projects[projectIndex].folders.firstIndex(where: { $0.id == folderID }) else {
            throw ProjectStoreError.folderNotFound
        }
        projects[projectIndex].folders[folderIndex].allocatedBytes = allocatedBytes
        projects[projectIndex].folders[folderIndex].availability = availability
        projects[projectIndex].folders[folderIndex].lastScannedAt = scannedAt
        try persist()
    }

    func setSearchRoots(_ paths: [String]) throws {
        var seen = Set<String>()
        searchRoots = paths.compactMap { path in
            let normalized = (path as NSString).standardizingPath
            let key = normalized.lowercased()
            guard seen.insert(key).inserted else { return nil }
            return normalized
        }
        try persist()
    }

    func project(id: UUID) -> ManagedProject? {
        projects.first { $0.id == id }
    }

    private func load() {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let document = try JSONDecoder().decode(Document.self, from: data)
            projects = document.projects
            searchRoots = document.searchRoots
            lastError = nil
        } catch {
            projects = []
            searchRoots = []
            lastError = "Saved projects could not be loaded: \(error.localizedDescription)"
        }
    }

    private func persist() throws {
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let document = Document(version: 1, projects: projects, searchRoots: searchRoots)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(document)
        try data.write(to: fileURL, options: .atomic)
        lastError = nil
    }

    private static func defaultFileURL(fileManager: FileManager) -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base
            .appendingPathComponent("DeezSpacesaver", isDirectory: true)
            .appendingPathComponent("projects.json")
    }

    private static func canonicalPath(_ path: String) -> String {
        URL(fileURLWithPath: (path as NSString).standardizingPath)
            .resolvingSymlinksInPath()
            .standardizedFileURL
            .path
    }

    private static func pathsOverlap(_ lhs: String, _ rhs: String) -> Bool {
        if lhs == "/" || rhs == "/" { return true }
        let left = lhs.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let right = rhs.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return left.hasPrefix(right + "/") || right.hasPrefix(left + "/")
    }
}
