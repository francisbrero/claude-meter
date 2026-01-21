//
//  UsageData.swift
//  ClaudeMeter
//

import Foundation

struct UsageData {
    let used: Int
    let limit: Int
    let resetTime: Date?
    
    var percentage: Double {
        guard limit > 0 else { return 0 }
        return (Double(used) / Double(limit)) * 100
    }
    
    var remaining: Int {
        return max(0, limit - used)
    }
}

struct UsageResponse: Codable {
    let sessionUsage: SessionUsage?
    let weeklyUsage: WeeklyUsage?
    
    enum CodingKeys: String, CodingKey {
        case sessionUsage = "session_usage"
        case weeklyUsage = "weekly_usage"
    }
}

struct SessionUsage: Codable {
    let used: Int
    let limit: Int
    let resetsAt: String?
    
    enum CodingKeys: String, CodingKey {
        case used
        case limit
        case resetsAt = "resets_at"
    }
}

struct WeeklyUsage: Codable {
    let used: Int
    let limit: Int
    let resetsAt: String?
    
    enum CodingKeys: String, CodingKey {
        case used
        case limit
        case resetsAt = "resets_at"
    }
}
