//
//  LaunchAtLogin.swift
//  ClaudeMeter
//

import Foundation
import ServiceManagement

class LaunchAtLogin: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            if isEnabled {
                enable()
            } else {
                disable()
            }
        }
    }

    init() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    private func enable() {
        do {
            try SMAppService.mainApp.register()
        } catch {
            print("Failed to enable launch at login: \(error)")
        }
    }

    private func disable() {
        do {
            try SMAppService.mainApp.unregister()
        } catch {
            print("Failed to disable launch at login: \(error)")
        }
    }
}
