# 🕹 NES Emulator in Swift

This is a NES (Nintendo Entertainment System) emulator written entirely in Swift, designed to be fast, accurate, and native to macOS. It simulates the core components of the NES including the CPU, PPU, memory, and input handling with a modular, testable architecture.

## ✨ Features

- Accurate 6502 CPU emulation
- PPU graphics rendering with vertical/horizontal mirroring
- ROM loading with support for iNES format
- Audio stub (in development)
- macOS-native UI using Swift and SwiftUI
- Modular Swift codebase for easy extension and testing

## 🧰 Requirements

- macOS 14 or later
- Xcode 16 or later
- Swift 5.9+
- A valid NES ROM file (iNES format)

## 🚀 Getting Started

1. Clone this repository:

   ```bash
   git clone https://github.com/your-username/nes-emulator-swift.git
   cd nes-emulator-swift
   ```

2. Open the project in Xcode:

   ```bash
   open NES.xcodeproj
   ```

3. Build and run the app from Xcode.

## 🧹 Code Style – SwiftFormat

This project uses [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) to enforce a consistent code style.

### 📦 Installing SwiftFormat

Install using [Homebrew](https://brew.sh/):

```bash
brew install swiftformat
```

### 🛠 Using SwiftFormat

To format all Swift files in the project:

```bash
swiftformat .
```

To check for formatting issues without making changes:

```bash
swiftformat . --lint
```

You can also integrate SwiftFormat into Xcode’s build process or use a pre-commit hook to enforce formatting.

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.

## 🙌 Credits

Thanks to the open-source emulation community for technical documentation and inspiration.

---

Happy emulating!
