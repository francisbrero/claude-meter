//
//  UsageManager.swift
//  AIMeter
//

import Foundation
import SwiftUI
import UserNotifications

@MainActor
class UsageManager: ObservableObject {
    @Published var providerStates: [String: ProviderState] = [:]
    @Published var isLoading = false
    @Published var lastUpdated: Date?

    private var refreshTimer: Timer?
    private var refreshTask: Task<Void, Never>?
    private let notificationManager = NotificationManager()

    // Notification thresholds per provider
    private var notifiedThresholds: [String: Set<Int>] = [:]
    private let thresholds = [80, 90]

    private var providers: [any UsageProvider] = [
        ClaudeProvider(),
        CodexProvider()
    ]

    var availableProviders: [any UsageProvider] {
        providers.filter { $0.isAvailable }
    }

    // MARK: - Menu Bar Display

    var menuBarText: String {
        let parts = availableProviders.compactMap { provider -> String? in
            guard let state = providerStates[provider.id],
                  let usage = state.usage else {
                return nil
            }
            let emoji = state.statusEmoji
            let percent = Int(usage.maxUtilization)
            return "\(emoji) \(percent)%"
        }

        if parts.isEmpty {
            if isLoading {
                return "⏳"
            }
            return "❌"
        }

        return parts.joined(separator: " | ")
    }

    var statusColor: Color {
        let maxUtil = providerStates.values
            .compactMap { $0.usage?.maxUtilization }
            .max() ?? 0

        switch maxUtil {
        case ..<70: return .green
        case 70..<90: return .yellow
        default: return .red
        }
    }

    // MARK: - Lifecycle

    init() {
        // Initialize provider states
        for provider in providers {
            providerStates[provider.id] = ProviderState(provider: provider)
        }

        startRefreshTimer()
        requestNotificationPermission()
    }

    // MARK: - Refresh

    func refresh() {
        // Cancel any existing refresh and start fresh ("latest wins")
        refreshTask?.cancel()

        refreshTask = Task { @MainActor in
            await fetchAllProviders()
            // Only nil if not cancelled (prevents race where new task starts before old one nils)
            if !Task.isCancelled {
                refreshTask = nil
            }
        }
    }

    private func fetchAllProviders() async {
        isLoading = true
        defer { isLoading = false }

        // Exit early if cancelled
        try? Task.checkCancellation()

        await withTaskGroup(of: (String, ProviderUsageResponse?, String?).self) { group in
            for provider in availableProviders {
                group.addTask {
                    do {
                        let response = try await self.fetchWithRetry(provider: provider, retriesRemaining: 3)
                        return (provider.id, response, nil)
                    } catch {
                        return (provider.id, nil, error.localizedDescription)
                    }
                }
            }

            for await (providerId, response, error) in group {
                if var state = providerStates[providerId] {
                    if let response = response {
                        state.usage = response
                        state.lastUpdated = Date()
                        state.error = nil

                        // Check notification thresholds
                        checkThresholds(
                            providerId: providerId,
                            providerName: state.provider.name,
                            usage: response
                        )
                    } else {
                        state.error = error
                    }
                    state.isLoading = false
                    providerStates[providerId] = state
                }
            }
        }

        lastUpdated = Date()
    }

    private func fetchWithRetry(provider: any UsageProvider, retriesRemaining: Int) async throws -> ProviderUsageResponse {
        do {
            return try await provider.fetchUsage()
        } catch let urlError as URLError where urlError.isRetryable && retriesRemaining > 0 {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            return try await fetchWithRetry(provider: provider, retriesRemaining: retriesRemaining - 1)
        }
    }

    // MARK: - Timer

    private func startRefreshTimer() {
        let interval = UserDefaults.standard.double(forKey: "refreshInterval")
        let refreshInterval = interval > 0 ? interval : 120

        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func checkThresholds(providerId: String, providerName: String, usage: ProviderUsageResponse) {
        var notified = notifiedThresholds[providerId] ?? []
        let maxUtil = usage.maxUtilization

        for threshold in thresholds {
            if maxUtil >= Double(threshold) && !notified.contains(threshold) {
                notified.insert(threshold)
                notificationManager.sendNotification(
                    title: "\(providerName) Usage Alert",
                    body: "Usage is at \(Int(maxUtil))%"
                )
            }
        }

        // Reset notifications if usage drops below lowest threshold
        if maxUtil < Double(thresholds.min() ?? 80) {
            notified.removeAll()
        }

        notifiedThresholds[providerId] = notified
    }

    // MARK: - Legacy Compatibility

    // Keep these for backward compatibility with existing UI
    var sessionUsage: UsageData? {
        guard let claudeState = providerStates["claude"],
              let usage = claudeState.usage,
              let limit = usage.limits.first(where: { $0.name.contains("Session") || $0.name.contains("5h") }) else {
            return nil
        }
        return UsageData(utilization: limit.utilization, resetTime: limit.resetTime)
    }

    var weeklyUsage: UsageData? {
        guard let claudeState = providerStates["claude"],
              let usage = claudeState.usage,
              let limit = usage.limits.first(where: { $0.name.contains("Weekly") || $0.name.contains("7d") }) else {
            return nil
        }
        return UsageData(utilization: limit.utilization, resetTime: limit.resetTime)
    }

    var sonnetUsage: UsageData? {
        guard let claudeState = providerStates["claude"],
              let usage = claudeState.usage,
              let limit = usage.limits.first(where: { $0.name.contains("Sonnet") }) else {
            return nil
        }
        return UsageData(utilization: limit.utilization, resetTime: limit.resetTime)
    }

    var error: String? {
        // Return first error from any provider
        providerStates.values.compactMap { $0.error }.first
    }
}

// MARK: - URLError Extension

extension URLError {
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
