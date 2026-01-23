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

    var statusColor: Color {
        switch utilization {
        case ..<70: return .green
        case 70..<90: return .yellow
        default: return .red
        }
    }

    var statusEmoji: String {
        switch utilization {
        case ..<70: return "🟢"
        case 70..<90: return "🟡"
        default: return "🔴"
        }
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
        }
    }
}
