//
//  ClaudeMeterApp.swift
//  ClaudeMeter
//
//  A lightweight macOS menu bar app to track Claude Code usage
//

import SwiftUI

@main
struct ClaudeMeterApp: App {
    @StateObject private var usageManager = UsageManager()
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(usageManager)
        } label: {
            MenuBarLabel()
                .environmentObject(usageManager)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarLabel: View {
    @EnvironmentObject var usageManager: UsageManager
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "gauge.with.dots.needle.50percent")
            if let usage = usageManager.sessionUsage {
                Text("\(Int(usage.percentage))%")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
            }
        }
        .foregroundColor(usageManager.statusColor)
    }
}
