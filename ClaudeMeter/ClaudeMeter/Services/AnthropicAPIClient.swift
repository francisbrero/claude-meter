//
//  AnthropicAPIClient.swift
//  ClaudeMeter
//

import Foundation

enum APIError: LocalizedError {
    case notLoggedIn
    case scopeError
    case networkError(String)
    case invalidResponse
    case apiError(statusCode: Int)
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return "Not logged in to Claude Code.\nRun 'claude' in Terminal to log in."
        case .scopeError:
            return "Token missing required scope.\nRun 'claude logout' then 'claude' to re-authenticate."
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let code):
            if code == 401 {
                return "Authentication expired.\nRun 'claude' to re-authenticate."
            }
            return "API error (code: \(code))"
        case .decodingError(let message):
            return "Failed to parse response: \(message)"
        }
    }
}

class AnthropicAPIClient {
    private let baseURL = "https://api.anthropic.com/api/oauth/usage"
    private let keychainService = KeychainService()
    
    // URLSession with timeouts (handles wake-from-sleep better)
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()
    
    func fetchUsage() async throws -> UsageResponse {
        guard let token = keychainService.getAccessToken() else {
            throw APIError.notLoggedIn
        }
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ClaudeMeter/1.0", forHTTPHeaderField: "User-Agent")
        // Required beta header to enable OAuth usage endpoint
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Check for error responses
        if httpResponse.statusCode != 200 {
            // Try to parse error message
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                
                if message.contains("scope") {
                    throw APIError.scopeError
                }
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.notLoggedIn
            }
            
            throw APIError.apiError(statusCode: httpResponse.statusCode)
        }
        
        // Parse successful response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        
        return parseUsageResponse(json)
    }
    
    private func parseUsageResponse(_ json: [String: Any]) -> UsageResponse {
        // Response format:
        // {
        //   "five_hour": { "utilization": 30.5, "resets_at": "..." },
        //   "seven_day": { "utilization": 45.2, "resets_at": "..." },
        //   "sonnet_only": { "utilization": 20.0, "resets_at": "..." }  // optional
        // }
        
        let fiveHour = json["five_hour"] as? [String: Any]
        let sevenDay = json["seven_day"] as? [String: Any]
        let sonnetOnly = json["sonnet_only"] as? [String: Any]
        
        var sessionUsage: SessionUsage? = nil
        var weeklyUsage: WeeklyUsage? = nil
        var sonnetUsage: SonnetUsage? = nil
        
        if let fiveHour = fiveHour {
            sessionUsage = SessionUsage(
                utilization: fiveHour["utilization"] as? Double ?? 0,
                resetsAt: fiveHour["resets_at"] as? String
            )
        }
        
        if let sevenDay = sevenDay {
            weeklyUsage = WeeklyUsage(
                utilization: sevenDay["utilization"] as? Double ?? 0,
                resetsAt: sevenDay["resets_at"] as? String
            )
        }
        
        if let sonnet = sonnetOnly {
            sonnetUsage = SonnetUsage(
                utilization: sonnet["utilization"] as? Double ?? 0,
                resetsAt: sonnet["resets_at"] as? String
            )
        }
        
        return UsageResponse(
            sessionUsage: sessionUsage,
            weeklyUsage: weeklyUsage,
            sonnetUsage: sonnetUsage
        )
    }
}
