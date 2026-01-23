//
//  MenuBarView.swift
//  ClaudeMeter
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var usageManager: UsageManager
    @StateObject private var launchAtLogin = LaunchAtLogin()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Claude Meter")
                    .font(.headline)
                Spacer()
                Button(action: { usageManager.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .disabled(usageManager.isLoading)
                .opacity(usageManager.isLoading ? 0.5 : 1.0)
            }
            .padding(.bottom, 4)

            Divider()

            if usageManager.isLoading && usageManager.sessionUsage == nil {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if let error = usageManager.error {
                ErrorView(message: error)
            } else {
                // Session Usage (5-hour)
                if let session = usageManager.sessionUsage {
                    UsageRow(
                        title: "Session (5h)",
                        usage: session,
                        resetLabel: "Resets"
                    )
                }

                // Weekly Usage (7-day)
                if let weekly = usageManager.weeklyUsage {
                    UsageRow(
                        title: "Weekly (7d)",
                        usage: weekly,
                        resetLabel: "Resets"
                    )
                }

                // Sonnet Usage (optional)
                if let sonnet = usageManager.sonnetUsage {
                    UsageRow(
                        title: "Sonnet",
                        usage: sonnet,
                        resetLabel: "Resets"
                    )
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
        .frame(width: 280)
    }
}

struct UsageRow: View {
    let title: String
    let usage: UsageData
    let resetLabel: String

    var statusColor: Color {
        switch usage.percentage {
        case ..<70: return .green
        case 70..<90: return .yellow
        default: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(usage.percentage))%")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(statusColor)
                        .frame(width: geometry.size.width * min(CGFloat(usage.percentage) / 100, 1.0))
                }
            }
            .frame(height: 8)

            // Reset time
            if let resetTime = usage.resetTime {
                Text("\(resetLabel) \(formatTimeRemaining(resetTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
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
