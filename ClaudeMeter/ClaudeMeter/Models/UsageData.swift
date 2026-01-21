//
//  UsageData.swift
//  ClaudeMeter
//

import Foundation

struct UsageData {
    let utilization: Double  // Percentage (0-100)
    let resetTime: Date?

    var percentage: Double { utilization }

    var remaining: Double {
        return max(0, 100 - utilization)
    }
}

// MARK: - API Response Models

struct UsageResponse {
    let sessionUsage: SessionUsage?   // 5-hour rolling window
    let weeklyUsage: WeeklyUsage?     // 7-day rolling window
    let sonnetUsage: SonnetUsage?     // Sonnet-specific limit (optional)
}

struct SessionUsage {
    let utilization: Double  // Percentage used
    let resetsAt: String?    // ISO8601 date string

    func toUsageData() -> UsageData {
        UsageData(
            utilization: utilization,
            resetTime: parseDate(resetsAt)
        )
    }
}

struct WeeklyUsage {
    let utilization: Double
    let resetsAt: String?

    func toUsageData() -> UsageData {
        UsageData(
            utilization: utilization,
            resetTime: parseDate(resetsAt)
        )
    }
}

struct SonnetUsage {
    let utilization: Double
    let resetsAt: String?

    func toUsageData() -> UsageData {
        UsageData(
            utilization: utilization,
            resetTime: parseDate(resetsAt)
        )
    }
}

// MARK: - Date Parsing

private func parseDate(_ dateString: String?) -> Date? {
    guard let dateString = dateString else { return nil }

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    if let date = formatter.date(from: dateString) {
        return date
    }

    // Fallback without fractional seconds
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: dateString)
}
