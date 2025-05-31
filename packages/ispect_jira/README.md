<div align="center">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/ispect/ispect.png?raw=true" width="400">
  
  <p><strong>Jira ticket creation integration for ISpect debugging toolkit</strong></p>
  
  <p>
    <a href="https://pub.dev/packages/ispect_jira">
      <img src="https://img.shields.io/pub/v/ispect_jira.svg" alt="pub version">
    </a>
    <a href="https://opensource.org/licenses/MIT">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT">
    </a>
    <a href="https://github.com/yelmuratoff/ispect">
      <img src="https://img.shields.io/github/stars/yelmuratoff/ispect?style=social" alt="GitHub stars">
    </a>
  </p>
  
  <p>
    <a href="https://pub.dev/packages/ispect_jira/score">
      <img src="https://img.shields.io/pub/likes/ispect_jira?logo=flutter" alt="Pub likes">
    </a>
    <a href="https://pub.dev/packages/ispect_jira/score">
      <img src="https://img.shields.io/pub/points/ispect_jira?logo=flutter" alt="Pub points">
    </a>
  </p>
</div>

## 🔍 Overview

> **ISpect Jira** provides seamless integration between ISpect debugging toolkit and Jira for automated bug reporting and ticket creation.

<div align="center">

🎫 **Ticket Creation** • 📸 **Screenshots** • 📝 **Context** • 🔧 **Configuration**

</div>

Streamline your bug reporting workflow by automatically creating detailed Jira tickets with screenshots, device information, and debugging context directly from your Flutter app during development and testing.

### 🎯 Key Features

- 🎫 **Automated Ticket Creation**: Create Jira tickets directly from the debugging interface
- 📸 **Screenshot Attachment**: Automatically attach screenshots to tickets
- 📝 **Context Collection**: Gather device info, logs, and app state for tickets
- 🔧 **Configurable Fields**: Customize ticket fields and metadata
- 🚀 **Easy Integration**: Simple setup with existing Jira instances
- 🎛️ **Flexible Auth**: Support for various Jira authentication methods

## 🔧 Configuration Options

### Basic Configuration

```dart
final jiraService = ISpectJiraService(
  config: JiraConfig(
    baseUrl: 'https://your-domain.atlassian.net',
    username: 'your-email@domain.com',
    apiToken: 'your-api-token',
    projectKey: 'MOBILE',
    
    // Default ticket settings
    issueType: 'Bug',
    priority: 'Medium',
    labels: ['mobile-app', 'flutter'],
  ),
);
```

### Advanced Configuration

```dart
final jiraService = ISpectJiraService(
  config: JiraConfig(
    baseUrl: 'https://your-domain.atlassian.net',
    username: 'your-email@domain.com',
    apiToken: 'your-api-token',
    projectKey: 'MOBILE',
    
    // Custom fields
    customFields: {
      'customfield_10001': 'Mobile App',
      'customfield_10002': 'Flutter',
    },
    
    // Ticket template
    titleTemplate: '[MOBILE] {summary}',
    descriptionTemplate: '''
*Device Info:*
{device_info}

*App Version:*
{app_version}

*Description:*
{description}

*Steps to Reproduce:*
{steps}

*Logs:*
{logs}
''',
  ),
);
```

### Authentication Methods

```dart
// API Token (recommended)
final config = JiraConfig(
  baseUrl: 'https://your-domain.atlassian.net',
  username: 'your-email@domain.com',
  apiToken: 'your-api-token',
  projectKey: 'PROJECT',
);

// Basic Auth
final config = JiraConfig(
  baseUrl: 'https://your-domain.atlassian.net',
  username: 'your-username',
  password: 'your-password',
  projectKey: 'PROJECT',
);

// OAuth (for self-hosted Jira)
final config = JiraConfig(
  baseUrl: 'https://your-jira-instance.com',
  oauthConfig: OAuthConfig(
    consumerKey: 'your-consumer-key',
    privateKey: 'your-private-key',
    accessToken: 'your-access-token',
  ),
  projectKey: 'PROJECT',
);
```

## 📦 Installation

Add ispect_jira to your `pubspec.yaml`:

```yaml
dependencies:
  ispect_jira: ^4.1.3-dev12
```

## 🚀 Quick Start

```dart
import 'package:ispect_jira/ispect_jira.dart';
import 'package:ispect/ispect.dart';

void main() {
  // Configure Jira integration
  final jiraService = ISpectJiraService(
    config: JiraConfig(
      baseUrl: 'https://your-domain.atlassian.net',
      username: 'your-email@domain.com',
      apiToken: 'your-api-token',
      projectKey: 'PROJECT',
    ),
  );
  
  ISpect.run(
    () => runApp(MyApp()),
    ispectify: ISpectify(),
    jiraService: jiraService,
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ISpectScopeWrapper(
      // Jira integration is automatically available in feedback system
      child: MaterialApp(
        builder: (context, child) => ISpectBuilder(
          child: child ?? const SizedBox.shrink(),
        ),
        home: HomePage(),
      ),
    );
  }
}
```

## ⚙️ Advanced Features

### Custom Ticket Builder

```dart
final jiraService = ISpectJiraService(
  config: config,
  ticketBuilder: CustomTicketBuilder(),
);

class CustomTicketBuilder implements JiraTicketBuilder {
  @override
  Future<JiraTicket> buildTicket(
    String summary,
    String description,
    FeedbackData feedbackData,
  ) async {
    return JiraTicket(
      summary: '[MOBILE] $summary',
      description: await _buildDescription(description, feedbackData),
      priority: _determinePriority(feedbackData),
      labels: _generateLabels(feedbackData),
      attachments: await _collectAttachments(feedbackData),
    );
  }
}
```

### Conditional Ticket Creation

```dart
final jiraService = ISpectJiraService(
  config: config,
  shouldCreateTicket: (feedbackData) {
    // Only create tickets for errors or specific conditions
    return feedbackData.hasErrors || feedbackData.severity == 'high';
  },
);
```

### Multiple Jira Instances

```dart
// Production Jira
final prodJira = ISpectJiraService(
  config: JiraConfig(
    baseUrl: 'https://prod.atlassian.net',
    projectKey: 'PROD',
    // ...
  ),
);

// Development Jira
final devJira = ISpectJiraService(
  config: JiraConfig(
    baseUrl: 'https://dev.atlassian.net',
    projectKey: 'DEV',
    // ...
  ),
);

// Use different services based on environment
final jiraService = kDebugMode ? devJira : prodJira;
```

## 📚 Examples

See the [example/](example/) directory for complete integration examples including:
- Basic Jira setup
- Custom ticket templates
- Multiple environment configuration
- Advanced authentication scenarios

## 🏗️ Architecture

ISpectJira integrates with Jira through REST API:

| Component | Description |
|-----------|-----------|
| **Jira Client** | REST API client for Jira communication |
| **Ticket Builder** | Creates tickets with debugging context |
| **Attachment Handler** | Manages screenshot and log attachments |
| **Auth Manager** | Handles various authentication methods |
| **Context Collector** | Gathers device and app information |

## 🤝 Contributing

Contributions are welcome! Please read our [contributing guidelines](../../CONTRIBUTING.md) and submit pull requests to the main branch.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Packages

- [ispect](../ispect) - Main debugging interface
- [ispectify](../ispectify) - Foundation logging system
- [http](https://pub.dev/packages/http) - HTTP client for API communication
- [feedback](https://pub.dev/packages/feedback) - User feedback system

---

<div align="center">
  <p>Built with ❤️ for the Flutter community</p>
  <a href="https://github.com/yelmuratoff/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=yelmuratoff/ispect" />
  </a>
</div>