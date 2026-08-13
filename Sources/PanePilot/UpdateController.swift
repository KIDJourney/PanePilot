import AppKit
import CryptoKit
import PanePilotCore
import Security

private struct GitHubRelease: Decodable, Sendable {
    struct Asset: Decodable, Sendable {
        let name: String
        let browserDownloadURL: URL
        let digest: String?

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
            case digest
        }
    }

    let tagName: String
    let body: String?
    let htmlURL: URL
    let assets: [Asset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case body
        case htmlURL = "html_url"
        case assets
    }
}

private struct CodeIdentity: Equatable {
    let identifier: String
    let teamIdentifier: String
}

private enum UpdateError: LocalizedError {
    case invalidResponse
    case invalidVersion(String)
    case missingAssets
    case invalidChecksum
    case readOnlyInstallation
    case invalidBundle
    case signature(String)
    case command(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "GitHub returned an invalid update response."
        case .invalidVersion(let version): "The release version is invalid: \(version)."
        case .missingAssets: "The release is missing its DMG or checksum asset."
        case .invalidChecksum: "The downloaded update did not match its published checksum."
        case .readOnlyInstallation: "Move PanePilot to Applications before installing updates."
        case .invalidBundle: "The downloaded update is not a valid PanePilot app."
        case .signature(let reason): "The downloaded app signature is invalid. \(reason)"
        case .command(let message): message
        }
    }
}

@MainActor
final class UpdateController {
    private static let latestReleaseURL = URL(string: "https://api.github.com/repos/KIDJourney/PanePilot/releases/latest")!
    private static let lastCheckKey = "updates.lastAutomaticCheck.v1"

    private let defaults: UserDefaults
    private let session: URLSession
    private let onCheckingChanged: (Bool) -> Void
    private var timer: Timer?
    private(set) var isChecking = false

    init(
        defaults: UserDefaults = .standard,
        session: URLSession = .shared,
        onCheckingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.defaults = defaults
        self.session = session
        self.onCheckingChanged = onCheckingChanged
    }

    func start() {
        scheduleNextAutomaticCheck()
    }

    func checkForUpdates(userInitiated: Bool) {
        guard !isChecking else { return }
        isChecking = true
        onCheckingChanged(true)
        if !userInitiated {
            defaults.set(Date(), forKey: Self.lastCheckKey)
        }

        Task {
            defer {
                isChecking = false
                onCheckingChanged(false)
                scheduleNextAutomaticCheck()
            }
            do {
                let release = try await fetchLatestRelease()
                guard let current = AppVersion(currentVersion),
                      let latest = AppVersion(release.tagName)
                else {
                    throw UpdateError.invalidVersion(release.tagName)
                }
                guard latest > current else {
                    if userInitiated {
                        showInformation(
                            title: "PanePilot Is Up to Date",
                            message: "You are using the latest version (\(currentVersion))."
                        )
                    }
                    return
                }
                guard confirmUpdate(release: release) else { return }
                try await install(release)
            } catch {
                if userInitiated {
                    showError(error)
                } else {
                    NSLog("PanePilot automatic update check failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    private func scheduleNextAutomaticCheck() {
        timer?.invalidate()
        let date = UpdateSchedule.nextCheckDate(
            after: Date(),
            lastCheckDate: defaults.object(forKey: Self.lastCheckKey) as? Date
        )
        timer = Timer(fireAt: date, interval: 0, target: self, selector: #selector(runAutomaticCheck), userInfo: nil, repeats: false)
        RunLoop.main.add(timer!, forMode: .common)
    }

    @objc private func runAutomaticCheck() {
        checkForUpdates(userInitiated: false)
    }

    private func fetchLatestRelease() async throws -> GitHubRelease {
        var request = URLRequest(url: Self.latestReleaseURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("PanePilot/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 20

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw UpdateError.invalidResponse
        }
        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }

    private func confirmUpdate(release: GitHubRelease) -> Bool {
        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = "PanePilot \(release.tagName) Is Available"
        let notes = release.body?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        alert.informativeText = notes.isEmpty
            ? "Install the update now?"
            : "Install the update now?\n\n\(String(notes.prefix(700)))"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Install Update")
        alert.addButton(withTitle: "Later")
        alert.addButton(withTitle: "View Release")
        let response = alert.runModal()
        if response == .alertThirdButtonReturn {
            NSWorkspace.shared.open(release.htmlURL)
            return false
        }
        return response == .alertFirstButtonReturn
    }

    private func install(_ release: GitHubRelease) async throws {
        let version = release.tagName.hasPrefix("v") ? String(release.tagName.dropFirst()) : release.tagName
        let expectedDMGName = "PanePilot-v\(version).dmg"
        guard let dmgAsset = release.assets.first(where: { $0.name == expectedDMGName }),
              let checksumAsset = release.assets.first(where: { $0.name == "\(expectedDMGName).sha256" })
        else {
            throw UpdateError.missingAssets
        }

        let currentAppURL = Bundle.main.bundleURL.resolvingSymlinksInPath()
        guard FileManager.default.isWritableFile(atPath: currentAppURL.deletingLastPathComponent().path) else {
            throw UpdateError.readOnlyInstallation
        }

        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("PanePilotUpdate-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: temporaryRoot,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        do {
            let dmgURL = temporaryRoot.appendingPathComponent(expectedDMGName)
            let checksumURL = temporaryRoot.appendingPathComponent("\(expectedDMGName).sha256")
            let (dmgData, checksumData) = try await (
                download(dmgAsset.browserDownloadURL),
                download(checksumAsset.browserDownloadURL)
            )
            try dmgData.write(to: dmgURL, options: .atomic)
            try checksumData.write(to: checksumURL, options: .atomic)
            try verifyChecksum(dmgData: dmgData, checksumData: checksumData, assetDigest: dmgAsset.digest)
            try verifyDMG(dmgURL)

            let mountPoint = try mount(dmgURL)
            let stagedURL = temporaryRoot.appendingPathComponent("PanePilot.app", isDirectory: true)
            do {
                let candidateURL = mountPoint.appendingPathComponent("PanePilot.app", isDirectory: true)
                try verifyCandidate(candidateURL, expectedVersion: version, currentAppURL: currentAppURL)
                try FileManager.default.copyItem(at: candidateURL, to: stagedURL)
            } catch {
                _ = try? run("/usr/bin/hdiutil", ["detach", mountPoint.path, "-quiet"])
                throw error
            }
            try run("/usr/bin/hdiutil", ["detach", mountPoint.path, "-quiet"])
            try verifyCandidate(stagedURL, expectedVersion: version, currentAppURL: currentAppURL)
            try launchReplacementHelper(
                currentAppURL: currentAppURL,
                stagedAppURL: stagedURL,
                temporaryRoot: temporaryRoot
            )
            NSApp.terminate(nil)
        } catch {
            try? FileManager.default.removeItem(at: temporaryRoot)
            throw error
        }
    }

    private func download(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("PanePilot/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 60
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw UpdateError.invalidResponse
        }
        return data
    }

    private func verifyChecksum(dmgData: Data, checksumData: Data, assetDigest: String?) throws {
        let actual = SHA256.hash(data: dmgData).map { String(format: "%02x", $0) }.joined()
        guard let checksumText = String(data: checksumData, encoding: .utf8),
              let expected = checksumText.split(whereSeparator: { $0.isWhitespace }).first.map(String.init),
              expected.caseInsensitiveCompare(actual) == .orderedSame
        else {
            throw UpdateError.invalidChecksum
        }
        if let assetDigest, assetDigest.hasPrefix("sha256:") {
            guard String(assetDigest.dropFirst("sha256:".count)).caseInsensitiveCompare(actual) == .orderedSame else {
                throw UpdateError.invalidChecksum
            }
        }
    }

    private func verifyDMG(_ url: URL) throws {
        try run("/usr/bin/xcrun", ["stapler", "validate", url.path])
        try run("/usr/sbin/spctl", ["-a", "-vv", "--type", "open", "--context", "context:primary-signature", url.path])
    }

    private func mount(_ url: URL) throws -> URL {
        let data = try run("/usr/bin/hdiutil", ["attach", url.path, "-nobrowse", "-readonly", "-plist"])
        guard let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let entities = plist["system-entities"] as? [[String: Any]],
              let path = entities.compactMap({ $0["mount-point"] as? String }).last
        else {
            throw UpdateError.command("Could not mount the downloaded update.")
        }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    private func verifyCandidate(_ candidate: URL, expectedVersion: String, currentAppURL: URL) throws {
        guard let bundle = Bundle(url: candidate),
              bundle.bundleIdentifier == Bundle.main.bundleIdentifier,
              bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String == expectedVersion
        else {
            throw UpdateError.invalidBundle
        }

        let currentIdentity = try codeIdentity(at: currentAppURL)
        let candidateIdentity = try codeIdentity(at: candidate)
        guard currentIdentity == candidateIdentity else {
            throw UpdateError.signature("The signing identifier or Team ID does not match the installed app.")
        }
        try run("/usr/sbin/spctl", ["-a", "-vv", "--type", "execute", candidate.path])
    }

    private func codeIdentity(at url: URL) throws -> CodeIdentity {
        var code: SecStaticCode?
        guard SecStaticCodeCreateWithPath(url as CFURL, [], &code) == errSecSuccess, let code else {
            throw UpdateError.signature("Code Signing Services could not open the app.")
        }
        let flags = SecCSFlags(rawValue: kSecCSCheckAllArchitectures | kSecCSStrictValidate | kSecCSCheckNestedCode)
        guard SecStaticCodeCheckValidity(code, flags, nil) == errSecSuccess else {
            throw UpdateError.signature("Code Signing Services rejected the app.")
        }
        var information: CFDictionary?
        guard SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &information) == errSecSuccess,
              let values = information as? [CFString: Any],
              let identifier = values[kSecCodeInfoIdentifier] as? String,
              let teamIdentifier = values[kSecCodeInfoTeamIdentifier] as? String
        else {
            throw UpdateError.signature("The signing identity is incomplete.")
        }
        return CodeIdentity(identifier: identifier, teamIdentifier: teamIdentifier)
    }

    private func launchReplacementHelper(currentAppURL: URL, stagedAppURL: URL, temporaryRoot: URL) throws {
        let helperURL = temporaryRoot.appendingPathComponent("install-update.sh")
        guard let bundledHelperURL = Bundle.main.url(forResource: "install-update", withExtension: "sh") else {
            throw UpdateError.command("The update installer helper is missing.")
        }
        try FileManager.default.copyItem(at: bundledHelperURL, to: helperURL)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: helperURL.path)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = [
            helperURL.path,
            currentAppURL.path,
            stagedAppURL.path,
            temporaryRoot.path,
            String(ProcessInfo.processInfo.processIdentifier)
        ]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
    }

    @discardableResult
    private func run(_ executable: String, _ arguments: [String]) throws -> Data {
        let process = Process()
        let output = Pipe()
        let error = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = error
        try process.run()
        process.waitUntilExit()
        let outputData = output.fileHandleForReading.readDataToEndOfFile()
        let errorData = error.fileHandleForReading.readDataToEndOfFile()
        guard process.terminationStatus == 0 else {
            let message = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw UpdateError.command(message?.isEmpty == false ? message! : "Update verification failed.")
        }
        return outputData
    }

    private func showInformation(title: String, message: String) {
        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showError(_ error: Error) {
        NSApp.activate()
        let alert = NSAlert(error: error)
        alert.messageText = "PanePilot Could Not Update"
        alert.runModal()
    }
}
