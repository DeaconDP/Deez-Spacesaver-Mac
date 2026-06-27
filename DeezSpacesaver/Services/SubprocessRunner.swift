import Foundation

enum SubprocessError: LocalizedError {
    case launchFailed(String)
    case nonZeroExit(code: Int32, output: String)

    var errorDescription: String? {
        switch self {
        case .launchFailed(let message):
            return "Failed to run command: \(message)"
        case .nonZeroExit(let code, let output):
            return "Command failed (\(code)): \(output)"
        }
    }
}

struct SubprocessRunner {
    func run(executable: String, arguments: [String] = []) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            throw SubprocessError.launchFailed(error.localizedDescription)
        }

        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw SubprocessError.nonZeroExit(code: process.terminationStatus, output: output)
        }
        return output
    }

    func runShell(_ command: String) throws -> String {
        try run(executable: "/bin/zsh", arguments: ["-lc", command])
    }
}
