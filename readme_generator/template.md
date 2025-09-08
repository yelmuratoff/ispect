<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">
  
  <p><strong>{{description}}</strong></p>
  
  <p>
    <a href="https://pub.dev/packages/{{package_name}}">
      <img src="https://img.shields.io/pub/v/{{package_name}}.svg" alt="pub version">
    </a>
    <a href="https://opensource.org/licenses/MIT">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
    </a>
    <a href="https://github.com/K1yoshiSho/ispect">
      <img src="https://img.shields.io/github/stars/K1yoshiSho/ispect?style=social" alt="GitHub stars">
    </a>
  </p>
  
  <p>
    <a href="https://pub.dev/packages/{{package_name}}/score">
      <img src="https://img.shields.io/pub/likes/{{package_name}}?logo=flutter" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/{{package_name}}/score">
      <img src="https://img.shields.io/pub/points/{{package_name}}?logo=flutter" alt="Pub points">
    </a>
  </p>
</div>

## 🔍 Overview

> **{{title}}** {{overview}}

{{custom_overview_section}}

### 🎯 Key Features

{{features}}

{{custom_sections}}

## 📦 Installation

Add {{package_name}} to your `pubspec.yaml`:

```yaml
dependencies:
  {{package_name}}: ^{{version}}
```

## ⚠️ Security & Production Guidelines

> **🚨 IMPORTANT: ISpect is a debugging tool and should NEVER be included in production builds**

### 🔒 Production Safety

ISpect contains sensitive debugging information and should only be used in development and staging environments. To ensure ISpect is completely removed from production builds, use the following approach:

### ✅ Recommended Setup with Dart Define Constants

**1. Create environment-aware initialization:**

```dart
// main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Use dart define to control ISpect inclusion
const bool kEnableISpect = bool.fromEnvironment('ENABLE_ISPECT', defaultValue: false);

void main() {
  if (kEnableISpect) {
    // Initialize ISpect only in development/staging
    _initializeISpect();
  } else {
    // Production initialization without ISpect
    runApp(MyApp());
  }
}

void _initializeISpect() {
  // ISpect initialization code here
  // This entire function will be tree-shaken in production
}
```

**2. Build Commands:**

```bash
# Development build (includes ISpect)
flutter run --dart-define=ENABLE_ISPECT=true

# Staging build (includes ISpect)
flutter build appbundle --dart-define=ENABLE_ISPECT=true

# Production build (ISpect completely removed via tree-shaking)
flutter build appbundle --dart-define=ENABLE_ISPECT=false
# or simply:
flutter build appbundle  # defaults to false
```

**3. Conditional Widget Wrapping:**

```dart
Widget build(BuildContext context) {
  return MaterialApp(
    // Conditionally add ISpectBuilder in MaterialApp builder
    builder: (context, child) {
      if (kEnableISpect) {
        return ISpectBuilder(child: child ?? const SizedBox.shrink());
      }
      return child ?? const SizedBox.shrink();
    },
    home: Scaffold(/* your app content */),
  );
}
```

### 🛡️ Security Benefits

- ✅ **Zero Production Footprint**: Tree-shaking removes all ISpect code from release builds
- ✅ **No Sensitive Data Exposure**: Debug information never reaches production users
- ✅ **Performance Optimized**: No debugging overhead in production
- ✅ **Compliance Ready**: Meets security requirements for app store releases

### 🔍 Verification

To verify ISpect is not included in your production build:

```bash
# Build release APK and check size difference
flutter build apk --dart-define=ENABLE_ISPECT=false --release
flutter build apk --dart-define=ENABLE_ISPECT=true --release

# Use flutter tools to analyze bundle
flutter analyze --dart-define=ENABLE_ISPECT=false
```

## 🚀 Quick Start

{{usage_example}}

{{advanced_configuration}}

{{integration_guides}}

{{examples_section}}

## 🏗️ Architecture

{{architecture_note}}

## 🤝 Contributing

Contributions are welcome! Please read our [contributing guidelines](../../CONTRIBUTING.md) and submit pull requests to the main branch.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

{{related_packages}}

---

<div align="center">
  <p>Built with ❤️ for the Flutter community</p>
  <a href="https://github.com/K1yoshiSho/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=K1yoshiSho/ispect" />
  </a>
</div>
