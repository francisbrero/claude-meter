//
//  CodexProvider.swift
//  AIMeter
//

import Foundation
import SwiftUI

class CodexProvider: UsageProvider {
    let id = "codex"
    let name = "Codex"
    let icon = "⚡"
    let iconName: String? = "codex-icon"  // Asset catalog name
    let accentColor = Color.green

    private let baseURL = "https://chatgpt.com/backend-api/wham/usage"
    private let credentialService = CodexCredentialService()

    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    var isAvailable: Bool {
        credentialService.getAccessToken() != nil
    }

    func fetchUsage() async throws -> ProviderUsageResponse {
        guard let token = credentialService.getAccessToken() else {
            throw ProviderError.notLoggedIn(provider: name)
        }

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("AIMeter/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProviderError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw ProviderError.notLoggedIn(provider: name)
            }
            throw ProviderError.apiError(statusCode: httpResponse.statusCode)
        }

        do {
            let codexResponse = try JSONDecoder().decode(CodexUsageResponse.self, from: data)
            return parseResponse(codexResponse)
        } catch {
            throw ProviderError.decodingError(error.localizedDescription)
        }
    }

    private func parseResponse(_ response: CodexUsageResponse) -> ProviderUsageResponse {
        var limits: [UsageLimit] = []

        // 5-hour limit
        if let primary = response.rateLimit.primaryWindow {
            limits.append(UsageLimit(
                name: "5 Hour",
                utilization: primary.usedPercent,
                resetTime: Date(timeIntervalSince1970: TimeInterval(primary.resetAt))
            ))
        }

        // Weekly limit
        if let secondary = response.rateLimit.secondaryWindow {
            limits.append(UsageLimit(
                name: "Weekly",
                utilization: secondary.usedPercent,
                resetTime: Date(timeIntervalSince1970: TimeInterval(secondary.resetAt))
            ))
        }

        // Code review limit
        if let codeReview = response.codeReviewRateLimit?.primaryWindow {
            limits.append(UsageLimit(
                name: "Code Review",
                utilization: codeReview.usedPercent,
                resetTime: Date(timeIntervalSince1970: TimeInterval(codeReview.resetAt))
            ))
        }

        return ProviderUsageResponse(limits: limits)
    }
}

// MARK: - Codex API Response Models

struct CodexUsageResponse: Decodable {
    let planType: String?
    let rateLimit: CodexRateLimit
    let codeReviewRateLimit: CodexRateLimit?
    let credits: CodexCredits?

    enum CodingKeys: String, CodingKey {
        case planType = "plan_type"
        case rateLimit = "rate_limit"
        case codeReviewRateLimit = "code_review_rate_limit"
        case credits
    }
}

struct CodexRateLimit: Decodable {
    let allowed: Bool?
    let limitReached: Bool?
    let primaryWindow: CodexWindow?
    let secondaryWindow: CodexWindow?

    enum CodingKeys: String, CodingKey {
        case allowed
        case limitReached = "limit_reached"
        case primaryWindow = "primary_window"
        case secondaryWindow = "secondary_window"
    }
}

struct CodexWindow: Decodable {
    let usedPercent: Double
    let limitWindowSeconds: Int
    let resetAfterSeconds: Int
    let resetAt: Int

    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case limitWindowSeconds = "limit_window_seconds"
        case resetAfterSeconds = "reset_after_seconds"
        case resetAt = "reset_at"
    }
}

struct CodexCredits: Decodable {
    let hasCredits: Bool?
    let unlimited: Bool?
    let balance: String?

    enum CodingKeys: String, CodingKey {
        case hasCredits = "has_credits"
        case unlimited
        case balance
    }
}
