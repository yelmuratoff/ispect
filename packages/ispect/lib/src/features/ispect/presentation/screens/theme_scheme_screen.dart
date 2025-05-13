import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/inspector/src/widgets/color_picker/utils.dart';

class ThemeSchemeScreen extends StatelessWidget {
  const ThemeSchemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iSpect = ISpect.read(context);

    return Scaffold(
      backgroundColor: iSpect.theme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: iSpect.theme.backgroundColor(context),
        title: const Text('Theme Scheme'),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),
      ),
      floatingActionButton: const DebugFloatingActionButton(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ThemeSection(
              title: 'Text Styles',
              child: TextStylesDisplay(),
            ),
            const ThemeSection(
              title: 'Buttons',
              child: ButtonDisplay(),
            ),
            const ThemeSection(
              title: 'Inputs',
              child: InputDisplay(),
            ),
            const ThemeSection(
              title: 'Selection Controls',
              child: SelectionControlsDisplay(),
            ),
            const ThemeSection(
              title: 'List & Tiles',
              child: ListTilesDisplay(),
            ),
            const ThemeSection(
              title: 'Progress & Sliders',
              child: ProgressSlidersDisplay(),
            ),
            ThemeSection(
              title: 'Colors',
              child: ColorSchemeDisplay(colorScheme: theme.colorScheme),
            ),
            const ThemeSection(
              title: 'Dialogs & Snackbars',
              child: DialogsSnackbarsDisplay(),
            ),
          ],
        ),
      ),
    );
  }
}

// Section Widget
class ThemeSection extends StatelessWidget {
  const ThemeSection({required this.title, required this.child, super.key});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(
          top: 16,
          bottom: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(4),
                    ),
                  ),
                  child: Text(
                    '  $title  ',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );
}

// FAB Component
class DebugFloatingActionButton extends StatelessWidget {
  const DebugFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('FAB'),
        icon: const Icon(Icons.add),
      );
}

// Text Styles Component
class TextStylesDisplay extends StatelessWidget {
  const TextStylesDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Display Large', style: textTheme.displayLarge),
        Text('Display Medium', style: textTheme.displayMedium),
        Text('Display Small', style: textTheme.displaySmall),
        Text('Headline Large', style: textTheme.headlineLarge),
        Text('Headline Medium', style: textTheme.headlineMedium),
        Text('Headline Small', style: textTheme.headlineSmall),
        Text('Title Large', style: textTheme.titleLarge),
        Text('Title Medium', style: textTheme.titleMedium),
        Text('Title Small', style: textTheme.titleSmall),
        Text('Body Large', style: textTheme.bodyLarge),
        Text('Body Medium', style: textTheme.bodyMedium),
        Text('Body Small', style: textTheme.bodySmall),
        Text('Label Large', style: textTheme.labelLarge),
        Text('Label Medium', style: textTheme.labelMedium),
        Text('Label Small', style: textTheme.labelSmall),
      ],
    );
  }
}

// Buttons Component
class ButtonDisplay extends StatefulWidget {
  const ButtonDisplay({super.key});

  @override
  State<ButtonDisplay> createState() => _ButtonDisplayState();
}

class _ButtonDisplayState extends State<ButtonDisplay> {
  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ElevatedButton(
            onPressed: () {},
            child: const Text('Elevated Button'),
          ),
          FilledButton(
            onPressed: () {},
            child: const Text('Filled Button'),
          ),
          FilledButton.tonal(
            onPressed: () {},
            child: const Text('Filled Tonal Button'),
          ),
          OutlinedButton(
            onPressed: () {},
            child: const Text('Outlined Button'),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Text Button'),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.star),
          ),
          ToggleButtons(
            isSelected: const [true, false, false],
            children: const [
              Icon(Icons.format_bold),
              Icon(Icons.format_italic),
              Icon(Icons.format_underline),
            ],
            onPressed: (_) {},
          ),
          SegmentedButton(
            segments: const [
              ButtonSegment(
                value: 'Segment 1',
                icon: Icon(Icons.star),
              ),
              ButtonSegment(
                value: 'Segment 2',
                icon: Icon(Icons.star),
              ),
            ],
            selected: const {'Segment 1'},
          ),
        ],
      );
}

// Inputs Component
class InputDisplay extends StatelessWidget {
  const InputDisplay({super.key});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'TextField',
            ),
            onTapOutside: (event) {
              FocusManager.instance.primaryFocus?.unfocus();
            },
          ),
          const Gap(8),
          SearchBar(
            onChanged: (_) {},
            hintText: 'SearchBar',
            onTapOutside: (event) {
              FocusManager.instance.primaryFocus?.unfocus();
            },
          ),
          const Gap(8),
          ElevatedButton(
            onPressed: () {
              showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
            },
            child: const Text('Date Picker'),
          ),
          const Gap(8),
          DropdownButton<String>(
            value: 'Option 1',
            items: const [
              DropdownMenuItem(
                value: 'Option 1',
                child: Text('Option 1'),
              ),
              DropdownMenuItem(
                value: 'Option 2',
                child: Text('Option 2'),
              ),
            ],
            onChanged: (_) {},
          ),
          const Gap(8),
          ElevatedButton(
            onPressed: () {
              showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
            },
            child: const Text('Time Picker'),
          ),
          const Gap(8),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'Option 1',
                child: Text('Option 1'),
              ),
              const PopupMenuItem(
                value: 'Option 2',
                child: Text('Option 2'),
              ),
            ],
          ),
          RadioMenuButton<String>(
            onChanged: (_) {},
            value: '',
            groupValue: '',
            child: const Text('Radio Button'),
          ),
        ],
      );
}

// Selection Controls Component
class SelectionControlsDisplay extends StatelessWidget {
  const SelectionControlsDisplay({super.key});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            children: [
              Checkbox(value: true, onChanged: (_) {}),
              const Text('Checkbox'),
            ],
          ),
          Row(
            children: [
              Radio(value: true, groupValue: true, onChanged: (_) {}),
              const Text('Radio'),
            ],
          ),
          Row(
            children: [
              Switch(value: true, onChanged: (_) {}),
              const Text('Switch'),
            ],
          ),
        ],
      );
}

// List Tiles Component
class ListTilesDisplay extends StatelessWidget {
  const ListTilesDisplay({super.key});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const ListTile(leading: Icon(Icons.info), title: Text('ListTile 1')),
          const ListTile(
            leading: Icon(Icons.settings),
            title: Text('ListTile 2'),
          ),
          const ExpansionTile(
            title: Text('Expandable Tile'),
            children: [Text('Expanded Content')],
          ),
          Divider(color: Colors.grey.shade400, thickness: 1),
        ],
      );
}

// Progress and Sliders Component
class ProgressSlidersDisplay extends StatelessWidget {
  const ProgressSlidersDisplay({super.key});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const LinearProgressIndicator(),
          const CircularProgressIndicator(),
          Slider(value: 0.5, onChanged: (_) {}),
        ],
      );
}

// Color Scheme Component
class ColorSchemeDisplay extends StatelessWidget {
  const ColorSchemeDisplay({required this.colorScheme, super.key});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _colorMap.entries
            .map((e) => ColorBox(label: e.key, color: e.value(colorScheme)))
            .toList(),
      );

  static final _colorMap = {
    'Primary': (ColorScheme s) => s.primary,
    'On Primary': (ColorScheme s) => s.onPrimary,
    'Primary Container': (ColorScheme s) => s.primaryContainer,
    'On Primary Container': (ColorScheme s) => s.onPrimaryContainer,
    'Primary Fixed': (ColorScheme s) => s.primaryFixed,
    'Primary Fixed Dim': (ColorScheme s) => s.primaryFixedDim,
    'On Primary Fixed': (ColorScheme s) => s.onPrimaryFixed,
    'On Primary Fixed Variant': (ColorScheme s) => s.onPrimaryFixedVariant,
    'Secondary': (ColorScheme s) => s.secondary,
    'On Secondary': (ColorScheme s) => s.onSecondary,
    'Secondary Container': (ColorScheme s) => s.secondaryContainer,
    'On Secondary Container': (ColorScheme s) => s.onSecondaryContainer,
    'Secondary Fixed': (ColorScheme s) => s.secondaryFixed,
    'Secondary Fixed Dim': (ColorScheme s) => s.secondaryFixedDim,
    'On Secondary Fixed': (ColorScheme s) => s.onSecondaryFixed,
    'On Secondary Fixed Variant': (ColorScheme s) => s.onSecondaryFixedVariant,
    'Tertiary': (ColorScheme s) => s.tertiary,
    'On Tertiary': (ColorScheme s) => s.onTertiary,
    'Tertiary Container': (ColorScheme s) => s.tertiaryContainer,
    'On Tertiary Container': (ColorScheme s) => s.onTertiaryContainer,
    'Tertiary Fixed': (ColorScheme s) => s.tertiaryFixed,
    'Tertiary Fixed Dim': (ColorScheme s) => s.tertiaryFixedDim,
    'On Tertiary Fixed': (ColorScheme s) => s.onTertiaryFixed,
    'On Tertiary Fixed Variant': (ColorScheme s) => s.onTertiaryFixedVariant,
    'Error': (ColorScheme s) => s.error,
    'On Error': (ColorScheme s) => s.onError,
    'Error Container': (ColorScheme s) => s.errorContainer,
    'On Error Container': (ColorScheme s) => s.onErrorContainer,
    'Surface': (ColorScheme s) => s.surface,
    'On Surface': (ColorScheme s) => s.onSurface,
    'Surface Dim': (ColorScheme s) => s.surfaceDim,
    'Surface Bright': (ColorScheme s) => s.surfaceBright,
    'Surface Container': (ColorScheme s) => s.surfaceContainer,
    'Surface Container High': (ColorScheme s) => s.surfaceContainerHigh,
    'Surface Container Highest': (ColorScheme s) => s.surfaceContainerHighest,
    'Inverse Surface': (ColorScheme s) => s.inverseSurface,
    'On Inverse Surface': (ColorScheme s) => s.onInverseSurface,
    'Inverse Primary': (ColorScheme s) => s.inversePrimary,
    'Surface Tint': (ColorScheme s) => s.surfaceTint,
    'Outline': (ColorScheme s) => s.outline,
    'Outline Variant': (ColorScheme s) => s.outlineVariant,
    'Shadow': (ColorScheme s) => s.shadow,
    'Scrim': (ColorScheme s) => s.scrim,
  };
}

// Color Box Component
class ColorBox extends StatelessWidget {
  const ColorBox({required this.label, required this.color, super.key});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Card(
            color: color ?? Colors.grey,
            child: SizedBox.square(
              dimension: 80,
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: getTextColorOnBackground(color ?? Colors.grey),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}

// Dialogs and Snackbars Component
class DialogsSnackbarsDisplay extends StatelessWidget {
  const DialogsSnackbarsDisplay({super.key});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (context) => Column(
                children: [
                  const ListTile(
                    title: Text('Bottom Sheet'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            child: const Text('Show Bottom Sheet'),
          ),
          ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Dialog'),
                content: const Text('This is a dialog'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            child: const Text('Show Dialog'),
          ),
          ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This is a snackbar')),
            ),
            child: const Text('Show Snackbar'),
          ),
        ],
      );
}
