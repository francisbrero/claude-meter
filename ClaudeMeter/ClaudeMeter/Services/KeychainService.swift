//
//  KeychainService.swift
//  AIMeter
//

import Foundation

class KeychainService {

    /// Get token from Claude Code's keychain using security CLI (avoids ACL prompt)
    func getAccessToken() -> String? {
        // Try primary keychain entry
        if let token = getTokenFromKeychain(service: "Claude Code-credentials") {
            return token
        }

        // Try alternate keychain entry
        if let token = getTokenFromKeychain(service: "Claude Code") {
            return token
        }

        return nil
    }

    private func getTokenFromKeychain(service: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", service, "-w"]

        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let jsonString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !jsonString.isEmpty else {
            return nil
        }

        // Parse as JSON to get OAuth token
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return nil
        }

        // Check for claudeAiOauth structure
        if let oauth = json["claudeAiOauth"] as? [String: Any],
           let accessToken = oauth["accessToken"] as? String {
            return accessToken
        }

        return nil
    }
}
