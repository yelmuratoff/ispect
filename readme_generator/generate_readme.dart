#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

const String configDir = 'readme_generator/configs';
const String templateFile = 'readme_generator/template.md';
const String packagesDir = 'packages';
const String versionConfigFile = 'version.config';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart generate_readme.dart <package_name> [all]');
    print('Examples:');
    print('  dart generate_readme.dart ispect');
    print('  dart generate_readme.dart all');
    exit(1);
  }

  final command = args[0];

  if (command == 'all') {
    generateAllReadmes();
  } else {
    generateReadme(command);
  }
}

String readVersionFromConfig() {
  try {
    final versionFile = File(versionConfigFile);
    if (!versionFile.existsSync()) {
      print('⚠️  Version config file not found: $versionConfigFile');
      return '0.0.0';
    }

    final content = versionFile.readAsStringSync();
    final versionLine = content
        .split('\n')
        .firstWhere(
          (line) => line.trim().startsWith('VERSION='),
          orElse: () => 'VERSION=0.0.0',
        );

    return versionLine.split('=')[1].trim();
  } catch (e) {
    print('⚠️  Error reading version: $e');
    return '0.0.0';
  }
}

void generateAllReadmes() {
  final configFiles = Directory(configDir)
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.json'))
      .toList();

  print('Generating README files for ${configFiles.length} packages...\n');

  for (final configFile in configFiles) {
    final packageName = configFile.uri.pathSegments.last.replaceAll(
      '.json',
      '',
    );
    generateReadme(packageName);
  }

  print('\n✅ All README files generated successfully!');
}

void generateReadme(String packageName) {
  try {
    print('📝 Generating README for $packageName...');

    // Read template
    final template = File(templateFile).readAsStringSync();

    // Read config
    final configFile = File('$configDir/$packageName.json');
    if (!configFile.existsSync()) {
      print('❌ Config file not found: $configDir/$packageName.json');
      return;
    }

    final configJson =
        json.decode(configFile.readAsStringSync()) as Map<String, dynamic>;

    // Read version from config file
    final version = readVersionFromConfig();
    print('📦 Using version: $version');

    // Generate README content
    String readme = template;

    // Add version to config data
    final configWithVersion = Map<String, dynamic>.from(configJson);
    configWithVersion['version'] = version;

    // Replace simple placeholders
    configWithVersion.forEach((key, value) {
      if (value is String) {
        readme = readme.replaceAll('{{$key}}', value);
      } else if (value is List) {
        if (key == 'features') {
          final featuresText = value
              .cast<String>()
              .map((feature) => '- $feature')
              .join('\n');
          readme = readme.replaceAll('{{$key}}', featuresText);
        }
      }
    });

    // Handle empty sections
    readme = _cleanupEmptySections(readme);

    // Write README file
    final outputFile = File('$packagesDir/$packageName/README.md');
    outputFile.writeAsStringSync(readme);

    print('✅ README generated: ${outputFile.path}');
  } catch (e) {
    print('❌ Error generating README for $packageName: $e');
  }
}

String _cleanupEmptySections(String content) {
  // Remove empty sections
  final emptyPatterns = [
    RegExp(r'\{\{[^}]+\}\}'), // Remove unreplaced placeholders
  ];

  for (final pattern in emptyPatterns) {
    content = content.replaceAll(pattern, '');
  }

  // Clean up multiple empty lines
  content = content.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');

  return content.trim();
}
