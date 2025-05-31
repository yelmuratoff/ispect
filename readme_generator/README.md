# README Generator System

Automated documentation generation system for ISpect package ecosystem. Generates consistent, customized README files from a unified template with package-specific configurations.

## Architecture

```
readme_generator/
├── template.md              # Base template for all READMEs
├── generate_readme.dart     # Dart generation script
└── configs/                 # Package-specific configurations
    ├── ispect.json
    ├── ispectify.json
    ├── ispectify_dio.json
    ├── ispectify_http.json
    ├── ispectify_bloc.json
    └── ispect_jira.json

bash/
└── generate_readme.sh       # CLI wrapper script
```

## Usage

### Generate README for specific package

```bash
./bash/generate_readme.sh generate ispect
```

### Generate README for all packages

```bash
./bash/generate_readme.sh generate all
```

### List available packages

```bash
./bash/generate_readme.sh list
```

### Validate package configuration

```bash
./bash/generate_readme.sh validate ispectify_dio
```

## Configuration

Each package requires a JSON configuration file in `readme_generator/configs/`:

```json
{
  "package_name": "ispect",
  "title": "ISpect",
  "description": "Core debugging interface and inspection toolkit",
  "overview": "is the main debugging toolkit...",
  "version": "4.1.3",
  "features": [
    "🌐 **Network Monitoring**: Detailed HTTP request/response inspection",
    "📝 **Comprehensive Logging**: Advanced logging system"
  ],
  "custom_overview_section": "HTML/Markdown content for overview",
  "usage_example": "```dart\n// Code example\n```",
  "architecture_note": "Architecture description",
  "custom_sections": "Additional markdown sections",
  "advanced_configuration": "Advanced config examples",
  "examples_section": "Examples section content",
  "related_packages": "Related packages section"
}
```

### Required Fields

- `package_name` - Package identifier
- `title` - Display name
- `description` - Brief description
- `version` - Package version

### Optional Fields

- `overview` - Extended description
- `features` - Feature list array
- `custom_overview_section` - Custom overview content
- `usage_example` - Code examples
- `architecture_note` - Architecture documentation
- `custom_sections` - Additional sections
- `advanced_configuration` - Advanced configuration examples
- `examples_section` - Examples documentation
- `related_packages` - Related packages links

## Template System

The base template `template.md` uses `{{placeholder_name}}` syntax for variable replacement from package configurations.

### Available Placeholders

- `{{package_name}}` - Package name
- `{{title}}` - Package title
- `{{description}}` - Package description
- `{{overview}}` - Overview text
- `{{version}}` - Version number
- `{{features}}` - Features list
- `{{usage_example}}` - Usage examples
- `{{architecture_note}}` - Architecture notes
- `{{custom_sections}}` - Custom sections
- `{{advanced_configuration}}` - Advanced configuration
- `{{examples_section}}` - Examples
- `{{related_packages}}` - Related packages

## Adding New Package

1. Create configuration file:

```bash
cp readme_generator/configs/ispect.json readme_generator/configs/new_package.json
```

2. Edit configuration for your package

3. Generate README:

```bash
./bash/generate_readme.sh generate new_package
```

## Automation

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
./bash/generate_readme.sh generate all
git add packages/*/README.md
```

### GitHub Actions

```yaml
name: Generate README
on:
  push:
    paths: ['readme_generator/**']
  
jobs:
  generate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      - name: Generate README files
        run: ./bash/generate_readme.sh generate all
      - name: Commit changes
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add packages/*/README.md
          git commit -m "docs: auto-generate README files" || exit 0
          git push
```

## Validation & Debugging

### JSON Syntax Validation

```bash
for config in readme_generator/configs/*.json; do
  jq empty "$config" || echo "❌ Invalid JSON: $config"
done
```

### Template Testing

```bash
./bash/generate_readme.sh generate ispect
cat packages/ispect/README.md
```

## Development Guidelines

1. **Consistency**: Maintain uniform structure across all packages
2. **Versioning**: Update version numbers in configurations during releases
3. **Validation**: Verify configurations before generation
4. **Automation**: Integrate generation into CI/CD pipelines
5. **Documentation**: Keep documentation synchronized with changes
