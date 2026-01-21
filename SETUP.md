# Project Setup

## Creating the Xcode Project

Since Xcode project files are complex binary/XML formats, here's how to set up the project:

### Option 1: Create New Project in Xcode

1. Open Xcode
2. File → New → Project
3. Select **macOS** → **App**
4. Configure:
   - Product Name: `ClaudeMeter`
   - Team: Your team
   - Organization Identifier: `com.francisbrero`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Uncheck "Include Tests"
5. Save to the `ClaudeMeter` folder in this repo
6. Delete the auto-generated files (ContentView.swift, etc.)
7. Add existing files from `ClaudeMeter/ClaudeMeter/` folder:
   - Drag all `.swift` files into the project
   - Make sure "Copy items if needed" is **unchecked**
   - Select "Create groups"

### Option 2: Quick Setup Script

Run in Terminal:
```bash
cd /path/to/claude-meter/ClaudeMeter
xcodegen generate  # if you have XcodeGen installed
```

## Project Settings

After creating the project, configure these settings:

### General
- Deployment Target: **macOS 13.0**
- App Category: **Utilities**

### Signing & Capabilities
- Add **Keychain Sharing** capability
- Add **Network** (Outgoing Connections)

### Info.plist
Ensure these keys are set (copy from `ClaudeMeter/Info.plist`):
- `LSUIElement` = `YES` (menu bar app, no dock icon)

### Build Settings
- Swift Language Version: **Swift 5**

## File Structure

```
ClaudeMeter/
├── ClaudeMeterApp.swift      # App entry point
├── Views/
│   └── MenuBarView.swift     # Main UI
├── Models/
│   └── UsageData.swift       # Data models
├── Services/
│   ├── UsageManager.swift    # State management
│   ├── AnthropicAPIClient.swift  # API calls
│   ├── KeychainService.swift # Keychain access
│   └── NotificationManager.swift # Notifications
├── Info.plist
└── ClaudeMeter.entitlements
```

## Running

1. Build: ⌘B
2. Run: ⌘R
3. The app will appear in your menu bar (not in the Dock)

## Troubleshooting

### Keychain Access
If the app can't read Claude Code credentials:
1. Open Keychain Access
2. Search for "claude" or "anthropic"
3. Note the Service name and Account name
4. Update `KeychainService.swift` with correct values

### Sandbox Issues
If you get sandbox errors accessing the keychain:
1. Disable App Sandbox temporarily for development
2. Or add appropriate keychain-access-groups
