# Contributing to ClaudeMeter

Thank you for your interest in contributing to ClaudeMeter! This document provides guidelines and instructions for contributing.

## Code of Conduct

Please be respectful and constructive in all interactions. We're building something useful together.

## How to Contribute

### Reporting Bugs

1. Check if the issue already exists in [GitHub Issues](https://github.com/francisbrero/claude-meter/issues)
2. If not, create a new issue with:
   - Clear, descriptive title
   - Steps to reproduce the bug
   - Expected vs actual behavior
   - macOS version and ClaudeMeter version
   - Any relevant screenshots or error messages

### Suggesting Features

1. Check existing issues and milestones for similar suggestions
2. Create a new issue with the `enhancement` label
3. Describe the feature and why it would be useful
4. Include mockups or examples if applicable

### Submitting Code Changes

We use a fork-and-pull-request workflow. **Direct pushes to the main repository are not allowed.**

#### Setup

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/claude-meter.git
   cd claude-meter
   ```
3. **Add the upstream remote**:
   ```bash
   git remote add upstream https://github.com/francisbrero/claude-meter.git
   ```

#### Making Changes

1. **Create a feature branch** from `master`:
   ```bash
   git checkout master
   git pull upstream master
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following our coding standards (see below)

3. **Build and test** your changes:
   ```bash
   cd ClaudeMeter
   xcodegen generate
   xcodebuild -project ClaudeMeter.xcodeproj -scheme ClaudeMeter -configuration Debug build
   ```

4. **Commit your changes** with clear, descriptive messages:
   ```bash
   git commit -m "feat: Add your feature description"
   ```

   We follow [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat:` - New features
   - `fix:` - Bug fixes
   - `docs:` - Documentation changes
   - `refactor:` - Code refactoring
   - `chore:` - Maintenance tasks

5. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request** on GitHub:
   - Target the `master` branch
   - Fill out the PR template
   - Link any related issues
   - Wait for review

#### Pull Request Guidelines

- Keep PRs focused on a single change
- Update documentation if needed
- Ensure the app builds without errors
- Test on macOS 13.0+ if possible
- Respond to review feedback promptly

## Coding Standards

### Swift Style

- Use Swift's native naming conventions (camelCase for variables/functions, PascalCase for types)
- Keep functions focused and concise
- Add comments for complex logic, but prefer self-documenting code
- Use `@MainActor` for UI-related classes
- Handle errors gracefully with user-friendly messages

### Project Structure

```
ClaudeMeter/
├── ClaudeMeterApp.swift      # App entry point & AppDelegate
├── Views/                    # SwiftUI views
├── Models/                   # Data models
├── Services/                 # Business logic (API, Keychain, etc.)
└── Assets.xcassets/          # App icons and assets
```

### Dependencies

- We aim to keep dependencies minimal
- Use native frameworks (SwiftUI, AppKit, Security) when possible
- Discuss new dependencies in an issue before adding them

## Development Setup

### Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) for project generation

### Building

```bash
# Install XcodeGen if needed
brew install xcodegen

# Generate Xcode project and build
cd ClaudeMeter
xcodegen generate
open ClaudeMeter.xcodeproj
```

### Testing the App

1. Build and run from Xcode (⌘R)
2. Ensure you're logged into Claude Code with proper scopes:
   ```bash
   claude /logout
   claude
   ```

## Questions?

- Open a [Discussion](https://github.com/francisbrero/claude-meter/discussions) for general questions
- Check existing issues for common problems
- Tag maintainers in issues if you need help

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT).

---

Thank you for contributing! 🎉
