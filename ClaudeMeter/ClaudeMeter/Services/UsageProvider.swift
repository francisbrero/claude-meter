//
//  UsageProvider.swift
//  AIMeter
//

import Foundation
import SwiftUI

// MARK: - Provider Protocol

protocol UsageProvider {
    var id: String { get }
    var name: String { get }
    var icon: String { get }  // Fallback emoji
    var iconName: String? { get }  // Asset catalog or SF Symbol name
    var accentColor: Color { get }
    var isAvailable: Bool { get }

    func fetchUsage() async throws -> ProviderUsageResponse
}

// MARK: - Response Models

struct ProviderUsageResponse {
    let limits: [UsageLimit]

    /// Returns the highest utilization across all limits
    var maxUtilization: Double {
        limits.map(\.utilization).max() ?? 0
    }
}

struct UsageLimit {
    let name: String
    let utilization: Double  // 0-100
    let resetTime: Date?
    let isUnlimited: Bool
    let creditsUsed: Double?

    init(name: String, utilization: Double, resetTime: Date?, isUnlimited: Bool = false, creditsUsed: Double? = nil) {
        self.name = name
        self.utilization = utilization
        self.resetTime = resetTime
        self.isUnlimited = isUnlimited
        self.creditsUsed = creditsUsed
    }

    /// Dollar cost for unlimited plans (used_credits is in cents USD)
    var dollarCost: Double? {
        guard isUnlimited, let credits = creditsUsed else { return nil }
        return credits / 100.0
    }

    var statusColor: Color {
        if isUnlimited, let cost = dollarCost {
            switch cost {
            case ..<200: return .green
            case ..<1000: return .orange
            case ..<2000: return .red
            default: return .primary  // black/white depending on theme
            }
        }
        switch utilization {
        case ..<70: return .green
        case 70..<90: return .yellow
        default: return .red
        }
    }

    var statusEmoji: String {
        if isUnlimited, let cost = dollarCost {
            switch cost {
            case ..<200: return "🟢"
            case ..<1000: return "🟡"
            case ..<2000: return "🔴"
            default: return "⚫"
            }
        }
        switch utilization {
        case ..<70: return "🟢"
        case 70..<90: return "🟡"
        default: return "🔴"
        }
    }

    /// Display string for the status bar and usage row
    var displayValue: String {
        if isUnlimited, let cost = dollarCost {
            return formatDollars(cost)
        }
        return "\(Int(utilization))%"
    }

    private func formatDollars(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "$%.1fk", value / 1000)
        }
        return String(format: "$%.0f", value)
    }
}

// MARK: - Provider State

struct ProviderState {
    let provider: any UsageProvider
    var usage: ProviderUsageResponse?
    var lastUpdated: Date?
    var error: String?
    var isLoading: Bool = false

    var maxUtilization: Double {
        usage?.maxUtilization ?? 0
    }

    var statusEmoji: String {
        switch maxUtilization {
        case ..<70: return "🟢"
        case 70..<90: return "🟡"
        default: return "🔴"
        }
    }

    var statusColor: Color {
        switch maxUtilization {
        case ..<70: return .green
        case 70..<90: return .yellow
        default: return .red
        }
    }
}

// MARK: - Provider Errors

enum ProviderError: LocalizedError {
    case notLoggedIn(provider: String)
    case scopeError(provider: String)
    case networkError(String)
    case invalidResponse
    case apiError(statusCode: Int)
    case decodingError(String)
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .notLoggedIn(let provider):
            return "Not logged in to \(provider)."
        case .scopeError(let provider):
            return "\(provider) token missing required scope."
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let code):
            if code == 401 {
                return "Authentication expired."
            }
            return "API error (code: \(code))"
        case .decodingError(let message):
            return "Failed to parse response: \(message)"
        case .rateLimited:
            return "Rate limited. Will retry shortly."
        }
    }

    var isRetryable: Bool {
        switch self {
        case .rateLimited: return true
        default: return false
        }
    }
}
