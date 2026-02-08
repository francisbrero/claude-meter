//
//  AIMeterApp.swift
//  AIMeter
//
//  A lightweight macOS menu bar app to track AI usage (Claude, Codex)
//

import SwiftUI
import Combine

@main
struct AIMeterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var usageManager = UsageManager()
    var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - menubar only
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupPopover()
        setupWakeNotification()
        setupUsageObserver()
        startFetching()
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "⏳"
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: MenuBarView().environmentObject(usageManager))
    }

    func setupWakeNotification() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    func setupUsageObserver() {
        // Observe provider states changes
        usageManager.$providerStates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateStatusItem() }
            .store(in: &cancellables)

        usageManager.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateStatusItem() }
            .store(in: &cancellables)

        // Observe display mode preference changes
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateStatusItem() }
            .store(in: &cancellables)
    }

    @objc func handleWake() {
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            usageManager.refresh()
        }
    }

    func startFetching() {
        Task {
            let uptime = ProcessInfo.processInfo.systemUptime
            if uptime < 60 {
                let delaySeconds = max(30 - uptime, 5)
                try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
            }
            usageManager.refresh()
        }
    }

    func updateStatusItem() {
        guard let button = statusItem?.button else { return }

        let attributedString = NSMutableAttributedString()
        var hasContent = false

        // Get display mode preference
        let displayMode = UserDefaults.standard.string(forKey: "menuBarDisplayMode") ?? "weekly"
        let font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)

        for (index, provider) in usageManager.availableProviders.enumerated() {
            guard let state = usageManager.providerStates[provider.id],
                  let usage = state.usage else { continue }

            if index > 0 && hasContent {
                attributedString.append(NSAttributedString(string: "  ", attributes: [.font: font]))
            }

            // Provider icon - try asset catalog, then SF Symbol fallback, then emoji
            if let iconName = provider.iconName,
               let image = loadMenuBarIcon(named: iconName) {
                let attachment = NSTextAttachment()
                attachment.image = image
                // Adjust baseline to align with text
                attachment.bounds = CGRect(x: 0, y: -2, width: 14, height: 14)
                attributedString.append(NSAttributedString(attachment: attachment))
                attributedString.append(NSAttributedString(string: " ", attributes: [.font: font]))
            } else {
                attributedString.append(NSAttributedString(string: "\(provider.icon) ", attributes: [.font: font]))
            }

            // Get the appropriate limit based on display mode
            let limit: UsageLimit?
            if displayMode == "session" {
                limit = usage.limits.first { $0.name.contains("5") || $0.name.contains("Session") }
            } else {
                limit = usage.limits.first { $0.name.contains("Weekly") || $0.name.contains("7d") }
            }

            let percent = Int(limit?.utilization ?? usage.maxUtilization)
            let color: NSColor = percent >= 90 ? .systemRed
                                : percent >= 70 ? .systemOrange
                                : .systemGreen

            let percentStr = NSAttributedString(
                string: "\(percent)%",
                attributes: [.foregroundColor: color, .font: font]
            )
            attributedString.append(percentStr)
            hasContent = true
        }

        if hasContent {
            button.attributedTitle = attributedString
        } else if usageManager.isLoading {
            button.title = "⏳"
        } else {
            button.title = "❌"
        }
    }

    /// Load icon for menu bar - tries asset catalog first, then SF Symbol fallback
    private func loadMenuBarIcon(named name: String) -> NSImage? {
        // Try asset catalog first
        if let image = NSImage(named: name) {
            image.size = NSSize(width: 14, height: 14)
            image.isTemplate = true
            return image
        }

        // SF Symbol fallbacks for known icons
        let sfSymbolName: String? = switch name {
        case "claude-icon": "brain"
        case "codex-icon": "bolt"
        default: nil
        }

        if let symbolName = sfSymbolName,
           let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: name) {
            let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            let configuredImage = image.withSymbolConfiguration(config) ?? image
            configuredImage.isTemplate = true
            return configuredImage
        }

        return nil
    }

    @objc func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
