//
//  UsageManager.swift
//  ClaudeMeter
//

import Foundation
import SwiftUI
import UserNotifications

@MainActor
class UsageManager: ObservableObject {
    @Published var sessionUsage: UsageData?
    @Published var weeklyUsage: UsageData?
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastUpdated: Date?
    
    private var refreshTimer: Timer?
    private let apiClient = AnthropicAPIClient()
    private let notificationManager = NotificationManager()
    
    // Notification thresholds
    private var notifiedSessionThresholds: Set<Int> = []
    private var notifiedWeeklyThresholds: Set<Int> = []
    private let thresholds = [80, 90]
    
    var statusColor: Color {
        guard let session = sessionUsage else { return .secondary }
        switch session.percentage {
        case ..<70: return .green
        case 70..<90: return .yellow
        default: return .red
        }
    }
    
    init() {
        startRefreshTimer()
        refresh()
        requestNotificationPermission()
    }
    
    func refresh() {
        Task {
            await fetchUsage()
        }
    }
    
    private func fetchUsage() async {
        isLoading = true
        error = nil
        
        do {
            let response = try await apiClient.fetchUsage()
            
            if let session = response.sessionUsage {
                let resetTime = parseDate(session.resetsAt)
                sessionUsage = UsageData(used: session.used, limit: session.limit, resetTime: resetTime)
                checkThresholds(usage: sessionUsage!, type: "Session", notified: &notifiedSessionThresholds)
            }
            
            if let weekly = response.weeklyUsage {
                let resetTime = parseDate(weekly.resetsAt)
                weeklyUsage = UsageData(used: weekly.used, limit: weekly.limit, resetTime: resetTime)
                checkThresholds(usage: weeklyUsage!, type: "Weekly", notified: &notifiedWeeklyThresholds)
            }
            
            lastUpdated = Date()
        } catch APIError.notLoggedIn {
            error = "Not logged in to Claude Code.\nRun 'claude' in Terminal to log in."
        } catch APIError.networkError(let message) {
            error = "Network error: \(message)"
        } catch {
            self.error = "Failed to fetch usage: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
    }
    
    private func startRefreshTimer() {
        // Refresh every 2 minutes
        let interval = UserDefaults.standard.double(forKey: "refreshInterval")
        let refreshInterval = interval > 0 ? interval : 120
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    private func checkThresholds(usage: UsageData, type: String, notified: inout Set<Int>) {
        for threshold in thresholds {
            if usage.percentage >= Double(threshold) && !notified.contains(threshold) {
                notified.insert(threshold)
                notificationManager.sendNotification(
                    title: "Claude \(type) Usage Alert",
                    body: "\(type) usage is at \(Int(usage.percentage))%"
                )
            }
        }
        
        // Reset notifications if usage drops below thresholds
        if usage.percentage < 80 {
            notified.removeAll()
        }
    }
}
