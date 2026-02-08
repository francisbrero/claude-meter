//
//  CodexCredentialService.swift
//  AIMeter
//

import Foundation

class CodexCredentialService {
    private let keychainServiceName = "Codex Auth"
    private let authFilePath = ".codex/auth.json"

    func getAccessToken() -> String? {
        // 1. Try Keychain first (for keyring storage mode)
        if let token = readFromKeychain() {
            return token
        }

        // 2. Fallback to file-based storage
        if let token = readFromAuthFile() {
            return token
        }

        return nil
    }

    // MARK: - Keychain Access

    private func readFromKeychain() -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        task.arguments = [
            "find-generic-password",
            "-s", keychainServiceName,
            "-w"  // Output password only
        ]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let token = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !token.isEmpty {
                    return token
                }
            }
        } catch {
            // Keychain access failed, try file fallback
        }

        return nil
    }

    // MARK: - File-Based Auth

    private func readFromAuthFile() -> String? {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let authPath = homeDir.appendingPathComponent(authFilePath)

        guard FileManager.default.fileExists(atPath: authPath.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: authPath)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }

            // Primary pattern: { "tokens": { "access_token": "..." } }
            if let tokens = json["tokens"] as? [String: Any],
               let token = tokens["access_token"] as? String {
                return token
            }

            // Fallback patterns for different auth.json structures
            if let token = json["access_token"] as? String {
                return token
            }

            if let token = json["token"] as? String {
                return token
            }

        } catch {
            // File read or parse failed
        }

        return nil
    }
}
