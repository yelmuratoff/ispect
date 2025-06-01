<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">
  
  <p><strong>BLoC state management integration for ISpectify logging system</strong></p>
  
  <p>
    <a href="https://pub.dev/packages/ispectify_bloc">
      <img src="https://img.shields.io/pub/v/ispectify_bloc.svg" alt="pub version">
    </a>
    <a href="https://opensource.org/licenses/MIT">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
    </a>
    <a href="https://github.com/yelmuratoff/ispect">
      <img src="https://img.shields.io/github/stars/yelmuratoff/ispect?style=social" alt="GitHub stars">
    </a>
  </p>
  
  <p>
    <a href="https://pub.dev/packages/ispectify_bloc/score">
      <img src="https://img.shields.io/pub/likes/ispectify_bloc?logo=flutter" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispectify_bloc/score">
      <img src="https://img.shields.io/pub/points/ispectify_bloc?logo=flutter" alt="Pub points">
    </a>
  </p>
</div>

## 🔍 Overview

> **ISpectify BLoC** provides seamless integration between BLoC state management and the ISpectify logging system.

<div align="center">

🔄 **State Tracking** • 📝 **Event Logging** • 🔍 **Transition Monitoring** • ❌ **Error Handling**

</div>

Enhance your BLoC debugging workflow by automatically capturing and logging all state management interactions. Perfect for tracking state changes, debugging complex flows, and monitoring application behavior.

### 🎯 Key Features

- 🔄 **State Change Logging**: Automatic logging of all BLoC state changes
- 📝 **Event Tracking**: Detailed event logging with parameters
- 🔍 **Transition Monitoring**: Complete state transition tracking
- ❌ **Error Handling**: BLoC error logging with stack traces
- ⚡ **Performance Metrics**: State change timing and performance tracking
- 🎛️ **Configurable**: Flexible filtering and formatting options

## 🔧 Configuration Options

### Basic Configuration

```dart
Bloc.observer = ISpectifyBlocObserver(
  ispectify: ispectify,
  settings: ISpectifyBlocSettings(
    // Event logging
    printEvents: true,
    
    // State logging
    printStates: true,
    
    // Transition logging
    printTransitions: true,
    
    // Change logging
    printChanges: true,
    
    // Error handling
    printErrors: true,
  ),
);
```

### Advanced Filtering

```dart
Bloc.observer = ISpectifyBlocObserver(
  ispectify: ispectify,
  settings: ISpectifyBlocSettings(
    // Filter specific BLoCs
    blocFilter: (bloc) => bloc.runtimeType != NavigationBloc,
    
    // Filter sensitive events
    eventFilter: (event) {
      if (event is AuthEvent) {
        return event.copyWith(password: '***');
      }
      return event;
    },
    
    // Filter states
    stateFilter: (state) {
      if (state is UserState) {
        return state.copyWith(sensitiveData: null);
      }
      return state;
    },
    
    // Custom log levels
    eventLogLevel: LogLevel.debug,
    stateLogLevel: LogLevel.info,
    errorLogLevel: LogLevel.error,
  ),
);
```

## 📦 Installation

Add ispectify_bloc to your `pubspec.yaml`:

```yaml
dependencies:
  ispectify_bloc: ^4.1.3-dev13
```

## 🚀 Quick Start

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ispectify_bloc/ispectify_bloc.dart';
import 'package:ispectify/ispectify.dart';

void main() {
  final ispectify = ISpectify();
  
  // Set up BLoC observer
  Bloc.observer = ISpectifyBlocObserver(
    ispectify: ispectify,
    settings: ISpectifyBlocSettings(
      printEvents: true,
      printStates: true,
      printTransitions: true,
      printChanges: true,
    ),
  );
  
  runApp(MyApp());
}

// Your BLoC will be automatically logged
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<CounterIncremented>((event, emit) {
      emit(state + 1);
    });
  }
}
```

## ⚙️ Advanced Features

### Custom Log Formatting

```dart
Bloc.observer = ISpectifyBlocObserver(
  ispectify: ispectify,
  settings: ISpectifyBlocSettings(
    eventFormatter: (bloc, event) => '${bloc.runtimeType}: ${event.runtimeType}',
    stateFormatter: (bloc, state) => '${bloc.runtimeType} -> ${state.runtimeType}',
    transitionFormatter: (bloc, transition) => 
      '${bloc.runtimeType}: ${transition.event.runtimeType} -> ${transition.nextState.runtimeType}',
  ),
);
```

### Performance Monitoring

```dart
Bloc.observer = ISpectifyBlocObserver(
  ispectify: ispectify,
  settings: ISpectifyBlocSettings(
    trackPerformance: true,
    performanceThreshold: Duration(milliseconds: 100), // Log slow transitions
  ),
);
```

### Multiple Observers

```dart
// Combine with other observers
class MultiBlocObserver extends BlocObserver {
  final List<BlocObserver> _observers;
  
  MultiBlocObserver(this._observers);
  
  @override
  void onChange(BlocBase bloc, Change change) {
    for (final observer in _observers) {
      observer.onChange(bloc, change);
    }
  }
  
  // Implement other methods...
}

Bloc.observer = MultiBlocObserver([
  ISpectifyBlocObserver(ispectify: ispectify),
  CustomBlocObserver(),
]);
```

## 📚 Examples

See the [example/](example/) directory for complete integration examples with different BLoC patterns.

## 🏗️ Architecture

ISpectifyBloc integrates with the BLoC library through observers:

| Component | Description |
|-----------|-----------|
| **BLoC Observer** | Captures all BLoC events and state changes |
| **Event Logger** | Logs events with parameters and metadata |
| **State Logger** | Logs state changes and transitions |
| **Error Handler** | Captures and logs BLoC errors |
| **Performance Tracker** | Measures state change performance |

## 🤝 Contributing

Contributions are welcome! Please read our [contributing guidelines](../../CONTRIBUTING.md) and submit pull requests to the main branch.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Packages

- [ispectify](../ispectify) - Foundation logging system
- [ispect](../ispect) - Main debugging interface
- [flutter_bloc](https://pub.dev/packages/flutter_bloc) - BLoC state management library
- [bloc](https://pub.dev/packages/bloc) - Core BLoC library

---

<div align="center">
  <p>Built with ❤️ for the Flutter community</p>
  <a href="https://github.com/yelmuratoff/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=yelmuratoff/ispect" />
  </a>
</div>