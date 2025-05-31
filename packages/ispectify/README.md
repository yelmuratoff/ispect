<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">
  
  <p><strong>Foundation logging system for ISpect toolkit (based on Talker)</strong></p>
  
  <p>
    <a href="https://pub.dev/packages/ispectify">
      <img src="https://img.shields.io/pub/v/ispectify.svg" alt="pub version">
    </a>
    <a href="https://opensource.org/licenses/MIT">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
    </a>
    <a href="https://github.com/yelmuratoff/ispect">
      <img src="https://img.shields.io/github/stars/yelmuratoff/ispect?style=social" alt="GitHub stars">
    </a>
  </p>
  
  <p>
    <a href="https://pub.dev/packages/ispectify/score">
      <img src="https://img.shields.io/pub/likes/ispectify?logo=flutter" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispectify/score">
      <img src="https://img.shields.io/pub/points/ispectify?logo=flutter" alt="Pub points">
    </a>
  </p>
</div>

## 🔍 Overview

> **ISpectify** is the foundation logging system that powers the ISpect debugging toolkit.

<div align="center">

📝 **Logging** • 🔍 **Filtering** • 📊 **Monitoring** • 💾 **Export**

</div>

ISpectify provides a robust logging foundation that integrates seamlessly with the ISpect ecosystem. Built on top of the proven Talker logging library, it offers advanced features for debugging and monitoring Flutter applications.

### 🎯 Key Features

- 📝 **Structured Logging**: Advanced logging with categorization and filtering
- 🎨 **Custom Log Types**: Define your own log types with custom colors and icons
- 🔍 **Real-time Filtering**: Filter logs by type, level, and custom criteria
- 📊 **Performance Monitoring**: Track application performance metrics
- 💾 **Export Functionality**: Export logs for analysis and debugging
- 🔧 **Easy Integration**: Simple setup with minimal configuration

## 🔧 Configuration

### Settings

```dart
final ispectify = ISpectify(
  settings: ISpectifySettings(
    enabled: true,
    useConsoleLogs: true,
    useHistory: true,
    maxHistoryItems: 1000,
    colors: {
      LogLevel.info: Colors.blue,
      LogLevel.warning: Colors.orange,
      LogLevel.error: Colors.red,
    },
  ),
);
```

### Custom Log Types

```dart
// Define custom log types
ispectify.registerLogType(
  'network',
  color: Colors.green,
  icon: Icons.network_check,
);

// Use custom log type
ispectify.logCustom('network', 'HTTP request completed');
```

### Performance Monitoring

```dart
// Track performance
ispectify.trackPerformance('api_call', () async {
  // Your async operation
  await api.fetchData();
});
```

## 📦 Installation

Add ispectify to your `pubspec.yaml`:

```yaml
dependencies:
  ispectify: ^4.1.3-dev12
```

## 🚀 Quick Start

```dart
import 'package:ispectify/ispectify.dart';

void main() {
  // Initialize ISpectify
  final ispectify = ISpectify(
    settings: ISpectifySettings(
      enabled: true,
      useConsoleLogs: true,
      useHistory: true,
    ),
  );

  // Log different types of messages
  ispectify.info('Application started');
  ispectify.debug('Debug information');
  ispectify.warning('Warning message');
  ispectify.error('Error occurred');
  
  // Custom log types
  ispectify.log('Custom message', logLevel: LogLevel.verbose);
  
  runApp(MyApp());
}
```

## ⚙️ Advanced Features

### Log Filtering

```dart
// Filter logs by level
final errorLogs = ispectify.getLogsByLevel(LogLevel.error);

// Filter logs by custom criteria
final networkLogs = ispectify.getLogsByType('network');

// Search logs
final searchResults = ispectify.searchLogs('HTTP');
```

### Export Functionality

```dart
// Export logs to file
await ispectify.exportLogs('/path/to/logs.txt');

// Export specific log types
await ispectify.exportLogsByType('error', '/path/to/errors.txt');
```

## 📚 Examples

See the [example/](example/) directory for usage examples and integration patterns.

## 🏗️ Architecture

ISpectify serves as the logging foundation for the ISpect ecosystem:

| Component | Description |
|-----------|-----------|
| **Core Logger** | Based on Talker with enhanced features |
| **Log Filtering** | Advanced filtering and search capabilities |
| **Performance Tracking** | Built-in performance monitoring |
| **Export System** | Log export and analysis tools |
| **Integration Layer** | Seamless integration with ISpect toolkit |

## 🤝 Contributing

Contributions are welcome! Please read our [contributing guidelines](../../CONTRIBUTING.md) and submit pull requests to the main branch.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Packages

- [ispect](../ispect) - Main debugging interface
- [ispectify_dio](../ispectify_dio) - Dio HTTP client integration
- [ispectify_http](../ispectify_http) - Standard HTTP client integration
- [ispectify_bloc](../ispectify_bloc) - BLoC state management integration

---

<div align="center">
  <p>Built with ❤️ for the Flutter community</p>
  <a href="https://github.com/yelmuratoff/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=yelmuratoff/ispect" />
  </a>
</div>