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
    <a href="https://github.com/K1yoshiSho/ispect">
      <img src="https://img.shields.io/github/stars/K1yoshiSho/ispect?style=social" alt="GitHub stars">
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

## TL;DR

Create Jira issues from in‑app debug panel with logs, screenshot, context.

## 🏗️ Architecture

ISpectJira integrates with Atlassian Jira Cloud through REST API:

| Component | Description |
|-----------|-----------|
| **ISpectJiraClient** | Singleton client managing Jira API communication |
| **JiraFeedbackBuilder** | Custom feedback widget with Jira integration |
| **JiraAuthScreen** | Authentication and project selection interface |
| **JiraSendIssueScreen** | Complete issue creation with attachments |
| **Screenshot Capture** | Automatic screenshot attachment system |

## Overview

> **ISpect Jira** integrates the ISpect debugging toolkit with Jira for automated ticket creation.

ISpectJira integrates the ISpect debugging toolkit with Jira for automated ticket creation.

### Key Features

- Automated Ticket Creation: Create Jira tickets directly from the debugging interface
- Screenshot Attachment: Automatically attach screenshots to tickets
- Context Collection: Gather device info, logs, and app state for tickets
- Configurable Fields: Customize ticket fields and metadata
- Easy Integration: Simple setup with existing Jira instances
- Flexible Auth: Support for various Jira authentication methods

## Configuration Options

### Basic Setup

```dart
void main() {
  final iSpectify = ISpectifyFlutter.init();

  ISpect.run(
    () => runApp(MyApp()),
    logger: iSpectify,
  );
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize with your Jira credentials
    ISpectJiraClient.initialize(
      projectDomain: 'your-company',  // your-company.atlassian.net
      userEmail: 'developer@company.com',
      apiToken: 'ATATT3xFfGF0...', // Generate from Jira API tokens
      projectId: '10007',
      projectKey: 'MOBILE',
    );
  }
}
```

### Authentication Methods

```dart
// Method 1: Direct initialization in code
ISpectJiraClient.initialize(
  projectDomain: 'your-domain',
  userEmail: 'your-email@domain.com',
  apiToken: 'your-api-token',
  projectId: '10007',
  projectKey: 'PROJECT',
);

// Method 2: Runtime authentication with UI
Navigator.push(
  context,
  MaterialPageRoute<void>(
    builder: (_) => JiraAuthScreen(
      onAuthorized: (domain, email, apiToken, projectId, projectKey) {
        // Credentials saved automatically to ISpectJiraClient
        ISpect.logger.good('Jira authenticated successfully');
      },
    ),
  ),
);
```

### Custom Feedback Integration

```dart
ISpectBuilder(
  feedbackBuilder: (context, onSubmit, controller) => JiraFeedbackBuilder(
    onSubmit: onSubmit,
    theme: Theme.of(context),
    scrollController: controller,
  ),
  child: child,
)
```

### Jira Action Items

```dart
ISpectOptions(
  actionItems: [
    ISpectActionItem(
      title: 'Report Bug',
      icon: Icons.bug_report_outlined,
      onTap: (context) {
        if (ISpectJiraClient.isInitialized) {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const JiraSendIssueScreen(),
            ),
          );
        } else {
          // Show authentication screen
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => JiraAuthScreen(
                onAuthorized: (domain, email, apiToken, projectId, projectKey) {
                  // Handle successful authentication
                },
              ),
            ),
          );
        }
      },
    ),
  ],
),
```

## Installation

Add ispect_jira to your `pubspec.yaml`:

```yaml
dependencies:
  ispect_jira: ^4.3.6
```

## Security & Production Guidelines

> IMPORTANT: ISpect is development‑only. Keep it out of production builds.

<details>
<summary><strong>Full security & environment setup (click to expand)</strong></summary>

</details>

## 🚀 Quick Start

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_jira/ispect_jira.dart';

// Use dart define to control ISpect Jira integration
const bool kEnableISpectJira = bool.fromEnvironment('ENABLE_ISPECT', defaultValue: false);

void main() {
  if (kEnableISpectJira) {
    _initializeWithISpect();
  } else {
    // Production initialization without ISpect
    runApp(MyApp());
  }
}

void _initializeWithISpect() {
  final iSpectify = ISpectifyFlutter.init();

  ISpect.run(
    () => runApp(MyApp()),
    logger: iSpectify,
    isPrintLoggingEnabled: true,
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    
    // Initialize Jira client only when ISpect is enabled
    if (kEnableISpectJira) {
      ISpectJiraClient.initialize(
        projectDomain: 'your-domain',
        userEmail: 'your-email@domain.com',
        apiToken: 'your-api-token',
        projectId: '10007',
        projectKey: 'PROJECT',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with ISpect only when enabled
    if (kEnableISpectJira) {
      return MaterialApp(
        builder: (context, child) => ISpectBuilder(
          options: ISpectOptions(
            actionItems: [
              ISpectActionItem(
                title: 'Report Bug',
                icon: Icons.bug_report_outlined,
                onTap: (context) {
                  if (ISpectJiraClient.isInitialized) {
                    // Navigate to create issue screen
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const JiraSendIssueScreen(),
                      ),
                    );
                  } else {
                    // Navigate to auth screen
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => JiraAuthScreen(
                          onAuthorized: (domain, email, apiToken, projectId, projectKey) {
                            ISpect.logger.good('Jira authorized');
                          },
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          feedbackBuilder: (context, onSubmit, controller) => JiraFeedbackBuilder(
            onSubmit: onSubmit,
            theme: Theme.of(context),
            scrollController: controller,
          ),
          child: child ?? const SizedBox.shrink(),
        ),
        home: const HomePage(),
      );
    }
    
    // Production app without ISpect
    return MaterialApp(
      home: const HomePage(),
    );
  }
}

// Placeholder home page
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ISpect Jira Example')),
      body: const Center(
        child: Text('Jira integration enabled only in development'),
      ),
    );
  }
}
```

### Minimal Setup

## Advanced Features

### Custom Issue Creation

```dart
// Create issues programmatically
final issue = await ISpectJiraClient.createIssue(
  assigneeId: 'user-id',
  description: 'Bug description with context',
  issueTypeId: '10001', // Bug type ID
  label: 'mobile-app',
  summary: 'App crashes on startup',
  priorityId: '3', // Medium priority
);

// Add attachments to existing issue
final attachments = [File('screenshot.png')];
await ISpectJiraClient.addAttachmentsToIssue(
  issue: issue,
  attachments: attachments,
);
```

### Client State Management

```dart
// Check client initialization state
if (ISpectJiraClient.isInitialized) {
  print('Jira client is fully configured');
  print('Project: ${ISpectJiraClient.projectKey}');
  print('Domain: ${ISpectJiraClient.projectDomain}');
}

if (ISpectJiraClient.isClientInitialized) {
  print('Jira API client is ready');
}

// Restart client with new credentials
ISpectJiraClient.restart();
```

### Fetching Jira Data

```dart
// Get available projects
final projects = await ISpectJiraClient.getProjects();

// Get current user
final user = await ISpectJiraClient.getCurrentUser();

// Get issue types and statuses
final statuses = await ISpectJiraClient.getStatuses();

// Get available labels
final labels = await ISpectJiraClient.getLabels();

// Get project users
final users = await ISpectJiraClient.getUsers();

// Get boards and sprints
final boards = await ISpectJiraClient.getBoards();
final sprints = await ISpectJiraClient.getSprints(boardId: 123);
```

### Custom Send Issue Screen

```dart
// Navigate with pre-filled data
Navigator.push(
  context,
  MaterialPageRoute<void>(
    builder: (_) => JiraSendIssueScreen(
      initialDescription: 'Pre-filled bug description',
      initialAttachmentPath: '/path/to/screenshot.png',
    ),
  ),
);
```

### Localization Support

```dart
MaterialApp(
  localizationsDelegates: ISpectLocalizations.localizationDelegates([
    AppLocalizations.delegate,
    ISpectJiraLocalization.delegate, // Add Jira localizations
  ]),
  // ... rest of app configuration
)
```

## Examples

See the [example/](example/) directory for integration examples including:
- Basic Jira setup
- Custom ticket templates
- Multiple environment configuration
- Authentication scenarios

## 🤝 Contributing

Contributions are welcome! Please read our [contributing guidelines](../../CONTRIBUTING.md) and submit pull requests to the main branch.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Related Packages

- [ispect](../ispect) - Main debugging interface
- [ispectify](../ispectify) - Foundation logging system
- [atlassian_apis](https://pub.dev/packages/atlassian_apis) - Jira REST API client
- [feedback](https://pub.dev/packages/feedback) - User feedback system

---

<div align="center">
  <p>Built with ❤️ for the Flutter community</p>
  <a href="https://github.com/K1yoshiSho/ispect/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=K1yoshiSho/ispect" />
  </a>
</div>