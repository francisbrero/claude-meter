//
//  MenuBarView.swift
//  AIMeter
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var usageManager: UsageManager
    @StateObject private var launchAtLogin = LaunchAtLogin()
    @AppStorage("menuBarDisplayMode") private var displayMode = "weekly"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("AI Meter")
                    .font(.headline)
                Spacer()
                Button(action: { usageManager.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(usageManager.isLoading ? 360 : 0))
                        .animation(
                            usageManager.isLoading
                                ? .linear(duration: 1).repeatForever(autoreverses: false)
                                : .default,
                            value: usageManager.isLoading
                        )
                }
                .buttonStyle(.plain)
                .disabled(usageManager.isLoading)
                .opacity(usageManager.isLoading ? 0.7 : 1.0)
            }
            .padding(.bottom, 4)

            Divider()

            if usageManager.isLoading && usageManager.providerStates.values.allSatisfy({ $0.usage == nil }) {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                // Provider Sections
                ForEach(usageManager.availableProviders, id: \.id) { provider in
                    if let state = usageManager.providerStates[provider.id] {
                        ProviderSection(provider: provider, state: state)
                    }
                }

                // Show error if no providers available
                if usageManager.availableProviders.isEmpty {
                    ErrorView(message: "No providers configured.\nRun 'claude' or 'codex' in Terminal to log in.")
                }

                // Last updated
                if let lastUpdated = usageManager.lastUpdated {
                    HStack {
                        Circle()
                            .fill(usageManager.statusColor)
                            .frame(width: 8, height: 8)
                        Text("Updated \(lastUpdated, style: .relative) ago")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }

            Divider()

            // Settings
            VStack(alignment: .leading, spacing: 8) {
                Text("Menu Bar Display")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("", selection: $displayMode) {
                    Text("Weekly").tag("weekly")
                    Text("5 Hour").tag("session")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Toggle("Launch at Login", isOn: $launchAtLogin.isEnabled)
                .toggleStyle(.checkbox)
                .font(.caption)

            Divider()

            // Footer buttons
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding()
        .frame(width: 300)
    }
}

// MARK: - Provider Section

struct ProviderSection: View {
    let provider: any UsageProvider
    let state: ProviderState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Provider Header
            HStack(spacing: 6) {
                if let iconName = provider.iconName {
                    Image(iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                } else {
                    Text(provider.icon)
                        .font(.system(size: 14))
                }
                Text(provider.name.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
                if state.isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                }
            }

            if let error = state.error {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .padding(.vertical, 2)
            } else if let usage = state.usage {
                ForEach(usage.limits, id: \.name) { limit in
                    UsageRow(
                        title: limit.name,
                        utilization: limit.utilization,
                        resetTime: limit.resetTime,
                        accentColor: provider.accentColor
                    )
                }
            } else {
                Text("Loading...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Usage Row

struct UsageRow: View {
    let title: String
    let utilization: Double
    let resetTime: Date?
    var accentColor: Color = .blue

    var statusColor: Color {
        switch utilization {
        case ..<70: return .green
        case 70..<90: return .yellow
        default: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 12))
                Spacer()
                Text("\(Int(utilization))%")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(statusColor)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(statusColor)
                        .frame(width: geometry.size.width * min(CGFloat(utilization) / 100, 1.0))
                }
            }
            .frame(height: 6)

            // Reset time
            if let resetTime = resetTime {
                Text("Resets \(formatTimeRemaining(resetTime))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func formatTimeRemaining(_ date: Date) -> String {
        let remaining = date.timeIntervalSinceNow
        if remaining <= 0 { return "now" }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        if hours > 24 {
            let days = hours / 24
            return "in \(days)d \(hours % 24)h"
        } else if hours > 0 {
            return "in \(hours)h \(minutes)m"
        } else {
            return "in \(minutes)m"
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundColor(.yellow)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    MenuBarView()
        .environmentObject(UsageManager())
}
