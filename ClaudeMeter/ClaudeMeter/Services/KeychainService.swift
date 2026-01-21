//
//  KeychainService.swift
//  ClaudeMeter
//

import Foundation
import Security

class KeychainService {
    // Claude Code stores OAuth tokens in the keychain
    // The service name may vary - this attempts common patterns
    private let possibleServices = [
        "claude-code",
        "anthropic-claude-code",
        "com.anthropic.claude-code"
    ]
    
    private let possibleAccounts = [
        "oauth-token",
        "access-token",
        "default"
    ]
    
    func getAccessToken() -> String? {
        // Try different service/account combinations
        for service in possibleServices {
            for account in possibleAccounts {
                if let token = getKeychainItem(service: service, account: account) {
                    return token
                }
            }
            
            // Also try without specifying account
            if let token = getKeychainItem(service: service, account: nil) {
                return token
            }
        }
        
        // Try generic password search
        if let token = searchGenericPassword() {
            return token
        }
        
        return nil
    }
    
    private func getKeychainItem(service: String, account: String?) -> String? {
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
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    private func searchGenericPassword() -> String? {
        // Search for any keychain item containing "claude" or "anthropic"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            return nil
        }
        
        for item in items {
            if let service = item[kSecAttrService as String] as? String,
               (service.lowercased().contains("claude") || service.lowercased().contains("anthropic")),
               let data = item[kSecValueData as String] as? Data,
               let token = String(data: data, encoding: .utf8) {
                return token
            }
        }
        
        return nil
    }
}
