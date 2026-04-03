//
//  ClaudeProvider.swift
//  AIMeter
//

import Foundation
import SwiftUI

class ClaudeProvider: UsageProvider {
    let id = "claude"
    let name = "Claude"
    let icon = "🤖"
    let iconName: String? = "claude-icon"  // Asset catalog name
    let accentColor = Color.orange

    private let baseURL = "https://api.anthropic.com/api/oauth/usage"
    private let keychainService = KeychainService()

    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    var isAvailable: Bool {
        keychainService.getAccessToken() != nil
    }

    func fetchUsage() async throws -> ProviderUsageResponse {
        guard let token = keychainService.getAccessToken() else {
            throw ProviderError.notLoggedIn(provider: name)
        }

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("AIMeter/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProviderError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                if message.contains("scope") {
                    throw ProviderError.scopeError(provider: name)
                }
            }

            if httpResponse.statusCode == 401 {
                throw ProviderError.notLoggedIn(provider: name)
            }

            throw ProviderError.apiError(statusCode: httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ProviderError.invalidResponse
        }

        return parseResponse(json)
    }

    private func parseResponse(_ json: [String: Any]) -> ProviderUsageResponse {
        var limits: [UsageLimit] = []

        // Legacy fields (may now be null for some plans)
        if let fiveHour = json["five_hour"] as? [String: Any] {
            limits.append(UsageLimit(
                name: "5 Hour",
                utilization: fiveHour["utilization"] as? Double ?? 0,
                resetTime: parseDate(fiveHour["resets_at"] as? String)
            ))
        }

        if let sevenDay = json["seven_day"] as? [String: Any] {
            limits.append(UsageLimit(
                name: "Weekly",
                utilization: sevenDay["utilization"] as? Double ?? 0,
                resetTime: parseDate(sevenDay["resets_at"] as? String)
            ))
        }

        // New per-model weekly limits
        if let opus = json["seven_day_opus"] as? [String: Any] {
            limits.append(UsageLimit(
                name: "Opus",
                utilization: opus["utilization"] as? Double ?? 0,
                resetTime: parseDate(opus["resets_at"] as? String)
            ))
        }

        if let sonnet = json["seven_day_sonnet"] as? [String: Any] {
            limits.append(UsageLimit(
                name: "Sonnet",
                utilization: sonnet["utilization"] as? Double ?? 0,
                resetTime: parseDate(sonnet["resets_at"] as? String)
            ))
        }

        if let cowork = json["seven_day_cowork"] as? [String: Any] {
            limits.append(UsageLimit(
                name: "Cowork",
                utilization: cowork["utilization"] as? Double ?? 0,
                resetTime: parseDate(cowork["resets_at"] as? String)
            ))
        }

        // Legacy sonnet_only field
        if let sonnetOnly = json["sonnet_only"] as? [String: Any] {
            limits.append(UsageLimit(
                name: "Sonnet",
                utilization: sonnetOnly["utilization"] as? Double ?? 0,
                resetTime: parseDate(sonnetOnly["resets_at"] as? String)
            ))
        }

        // Extra usage (credit-based plans)
        if let extraUsage = json["extra_usage"] as? [String: Any],
           let isEnabled = extraUsage["is_enabled"] as? Bool, isEnabled {
            let utilization = extraUsage["utilization"] as? Double ?? 0
            let usedCredits = extraUsage["used_credits"] as? Double
            let monthlyLimit = extraUsage["monthly_limit"] as? Int

            var name = "Monthly"
            if let used = usedCredits, let limit = monthlyLimit {
                name = "Monthly (\(formatCredits(used))/\(formatCredits(Double(limit))))"
            }

            limits.append(UsageLimit(
                name: name,
                utilization: utilization,
                resetTime: nil
            ))
        }

        return ProviderUsageResponse(limits: limits)
    }

    private func formatCredits(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        }
        return String(format: "%.0f", value)
    }

    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            return date
        }

        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }
}
