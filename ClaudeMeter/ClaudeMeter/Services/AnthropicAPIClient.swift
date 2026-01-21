//
//  AnthropicAPIClient.swift
//  ClaudeMeter
//

import Foundation

enum APIError: Error {
    case notLoggedIn
    case networkError(String)
    case invalidResponse
    case decodingError(String)
}

class AnthropicAPIClient {
    private let baseURL = "https://api.anthropic.com/api/oauth/usage"
    private let keychainService = KeychainService()
    
    func fetchUsage() async throws -> UsageResponse {
        guard let token = keychainService.getAccessToken() else {
            throw APIError.notLoggedIn
        }
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("ClaudeMeter/1.0", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.notLoggedIn
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.networkError("HTTP \(httpResponse.statusCode)")
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(UsageResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
}
