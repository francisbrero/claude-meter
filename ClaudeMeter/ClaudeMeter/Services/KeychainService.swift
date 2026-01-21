//
//  KeychainService.swift
//  ClaudeMeter
//

import Foundation
import Security

class KeychainService {
    // Claude Code stores credentials with this service name
    private let serviceName = "Claude Code-credentials"
    
    func getAccessToken() -> String? {
        // Get the current macOS username for the account
        let username = NSUserName()
        
        guard let jsonData = getKeychainItem(service: serviceName, account: username) else {
            // Fallback: try without account specified
            guard let fallbackData = getKeychainItem(service: serviceName, account: nil) else {
                return nil
            }
            return parseAccessToken(from: fallbackData)
        }
        
        return parseAccessToken(from: jsonData)
    }
    
    private func getKeychainItem(service: String, account: String?) -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        if let account = account {
            query[kSecAttrAccount as String] = account
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        
        return data
    }
    
    private func parseAccessToken(from data: Data) -> String? {
        // The keychain stores JSON: {"claudeAiOauth":{"accessToken":"...","refreshToken":"..."}}
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let claudeAiOauth = json["claudeAiOauth"] as? [String: Any],
                  let accessToken = claudeAiOauth["accessToken"] as? String else {
                return nil
            }
            return accessToken
        } catch {
            // Maybe it's stored as plain text token
            return String(data: data, encoding: .utf8)
        }
    }
}
