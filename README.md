# Claude Meter 🔋

A lightweight macOS menu bar app that displays your personal Claude Code usage limits at a glance.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/license-MIT-green)

<img width="301" height="343" alt="image" src="https://github.com/user-attachments/assets/6088e9db-74e1-46cd-9522-24e4bf8b058a" />


## Features

### v1.0 (MVP)
- 🔄 **Auto-refresh** — Updates every 2 minutes (configurable)
- 🚦 **Color-coded status** — Green (<70%), Yellow (70-90%), Red (>90%)
- ⏱️ **Reset countdown** — Time until session and weekly limits reset
- 📊 **Session & Weekly limits** — Both displayed in dropdown
- 🔔 **Threshold alerts** — Notifications at 80% and 90% usage
- 🪶 **Lightweight** — Native Swift, minimal resources

### Roadmap (v2.0)
- 📈 Historical usage charts
- 💰 Cost estimates
- 📁 Per-project breakdown
- 📝 Activity timeline
- ⚙️ Settings panel

## Installation

### Download
1. Go to [Releases](https://github.com/francisbrero/claude-meter/releases)
2. Download `ClaudeMeter.zip`
3. Unzip and drag `ClaudeMeter.app` to your Applications folder
4. Open the app (you may need to right-click → Open the first time)

### Build from Source
```bash
git clone https://github.com/francisbrero/claude-meter.git
cd claude-meter
open ClaudeMeter.xcodeproj
```
Then build with ⌘B and run with ⌘R.

## Requirements

- macOS 13.0 (Ventura) or later
- [Claude Code CLI](https://claude.ai/code) installed and logged in

## Setup

1. Install Claude Code if you haven't already:
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```

2. Log in to Claude Code:
   ```bash
   claude
   ```

3. Launch Claude Meter — it reads your credentials from Keychain automatically

## How It Works

Claude Meter reads your Claude Code OAuth credentials from macOS Keychain and queries the usage API endpoint at `api.anthropic.com/api/oauth/usage`.

> ⚠️ **Note:** This uses an undocumented API that could change at any time. The app will gracefully handle API changes but may stop working if Anthropic modifies the endpoint.

## Status Colors

| Status | Color | Usage |
|--------|-------|-------|
| Normal | 🟢 Green | < 70% |
| Warning | 🟡 Yellow | 70-90% |
| Critical | 🔴 Red | > 90% |

## Privacy

- 🔒 Your credentials never leave your machine
- 📵 No analytics or telemetry
- 🚫 No data sent anywhere except Anthropic's API
- 👀 Open source — verify the code yourself

## Troubleshooting

### "Not logged in to Claude Code"
Run `claude` in Terminal and complete the login flow.

### "Token missing required scope"
Your OAuth token was created before the usage API scope existed. Fix:
```bash
claude logout
claude
```
Then re-authenticate. The new token will have the required `user:profile` scope.

### App doesn't appear in menubar
Check if the app is running in Activity Monitor. Try quitting and reopening.

### Usage shows wrong values
Click the refresh button (↻) in the dropdown. If still wrong, your Claude Code session may have expired — run `claude` again.

## Contributing

PRs welcome! Please open an issue first to discuss major changes.

## License

MIT License — do whatever you want with it.

## Disclaimer

This is an unofficial tool not affiliated with Anthropic. It uses an undocumented API that may change without notice.

---

Made with 🔧 by [@francisbrero](https://github.com/francisbrero)
