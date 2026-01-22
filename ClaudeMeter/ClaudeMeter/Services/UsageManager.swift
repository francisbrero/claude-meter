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
    @Published var sonnetUsage: UsageData?
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
        let maxUtil = max(
            sessionUsage?.utilization ?? 0,
            weeklyUsage?.utilization ?? 0
        )
        switch maxUtil {
        case ..<70: return .green
        case 70..<90: return .yellow
        default: return .red
        }
    }

    var statusEmoji: String {
        let maxUtil = max(
            sessionUsage?.utilization ?? 0,
            weeklyUsage?.utilization ?? 0
        )
        switch maxUtil {
        case ..<70: return "🟢"
        case 70..<90: return "🟡"
        default: return "🔴"
        }
    }

    init() {
        startRefreshTimer()
        requestNotificationPermission()
    }

    func refresh() {
        Task {
            await fetchUsageWithRetry(retriesRemaining: 3)
        }
    }

    private func fetchUsageWithRetry(retriesRemaining: Int) async {
        isLoading = true
        error = nil

        defer { isLoading = false }

        do {
            let response = try await apiClient.fetchUsage()

            if let session = response.sessionUsage {
                let newUsage = session.toUsageData()
                sessionUsage = newUsage
                checkThresholds(usage: newUsage, type: "Session", notified: &notifiedSessionThresholds)
            }

            if let weekly = response.weeklyUsage {
                let newUsage = weekly.toUsageData()
                weeklyUsage = newUsage
                checkThresholds(usage: newUsage, type: "Weekly", notified: &notifiedWeeklyThresholds)
            }

            if let sonnet = response.sonnetUsage {
                sonnetUsage = sonnet.toUsageData()
            }

            lastUpdated = Date()

        } catch let urlError as URLError where urlError.isRetryable && retriesRemaining > 0 {
            // Retry on network errors (common after wake from sleep)
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            await fetchUsageWithRetry(retriesRemaining: retriesRemaining - 1)

        } catch {
            self.error = error.localizedDescription
        }
    }

    private func startRefreshTimer() {
        // Refresh every 2 minutes by default
        let interval = UserDefaults.standard.double(forKey: "refreshInterval")
        let refreshInterval = interval > 0 ? interval : 120

        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
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

        // Reset notifications if usage drops below lowest threshold
        if usage.percentage < Double(thresholds.min() ?? 80) {
            notified.removeAll()
        }
    }
}

// MARK: - URLError Extension

extension URLError {
    /// Network errors that may resolve after wake from sleep
    var isRetryable: Bool {
        switch self.code {
        case .notConnectedToInternet,
             .networkConnectionLost,
             .dnsLookupFailed,
             .cannotFindHost,
             .cannotConnectToHost,
             .timedOut,
             .secureConnectionFailed:
            return true
        default:
            return false
        }
    }
}
