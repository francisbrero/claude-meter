//
//  MenuBarView.swift
//  ClaudeMeter
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var usageManager: UsageManager
    
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
            }
            .padding(.bottom, 4)
            
            Divider()
            
            if usageManager.isLoading && usageManager.sessionUsage == nil {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let error = usageManager.error {
                ErrorView(message: error)
            } else {
                // Session Usage
                if let session = usageManager.sessionUsage {
                    UsageRow(
                        title: "Session",
                        usage: session,
                        resetLabel: "Resets in"
                    )
                }
                
                // Weekly Usage
                if let weekly = usageManager.weeklyUsage {
                    UsageRow(
                        title: "Weekly",
                        usage: weekly,
                        resetLabel: "Resets in"
                    )
                }
                
                // Last updated
                if let lastUpdated = usageManager.lastUpdated {
                    Text("Updated \(lastUpdated, style: .relative) ago")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            
            Divider()
            
            // Footer buttons
            HStack {
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
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
                    .font(.subheadline)
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
                        .frame(width: geometry.size.width * min(usage.percentage / 100, 1.0))
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(formatNumber(usage.used)) / \(formatNumber(usage.limit))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let resetTime = usage.resetTime {
                    Text("\(resetLabel) \(formatTimeRemaining(resetTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatNumber(_ num: Int) -> String {
        if num >= 1_000_000 {
            return String(format: "%.1fM", Double(num) / 1_000_000)
        } else if num >= 1_000 {
            return String(format: "%.1fK", Double(num) / 1_000)
        }
        return "\(num)"
    }
    
    private func formatTimeRemaining(_ date: Date) -> String {
        let remaining = date.timeIntervalSinceNow
        if remaining <= 0 { return "now" }
        
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        
        if hours > 24 {
            let days = hours / 24
            return "\(days)d \(hours % 24)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.yellow)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    MenuBarView()
        .environmentObject(UsageManager())
}
