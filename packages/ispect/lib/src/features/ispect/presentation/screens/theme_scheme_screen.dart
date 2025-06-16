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
    final backgroundColor = iSpect.theme.backgroundColor(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
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
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildDivider(primaryColor, left: true)),
              _buildTitleContainer(primaryColor),
              Expanded(child: _buildDivider(primaryColor, right: true)),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildDivider(Color color, {bool left = false, bool right = false}) =>
      SizedBox(
        height: 4,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: left ? const Radius.circular(4) : Radius.zero,
              bottomLeft: left ? const Radius.circular(4) : Radius.zero,
              topRight: right ? const Radius.circular(4) : Radius.zero,
              bottomRight: right ? const Radius.circular(4) : Radius.zero,
            ),
          ),
        ),
      );

  Widget _buildTitleContainer(Color color) => DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
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

  static const _textStyleEntries = [
    ('Display Large', 'displayLarge'),
    ('Display Medium', 'displayMedium'),
    ('Display Small', 'displaySmall'),
    ('Headline Large', 'headlineLarge'),
    ('Headline Medium', 'headlineMedium'),
    ('Headline Small', 'headlineSmall'),
    ('Title Large', 'titleLarge'),
    ('Title Medium', 'titleMedium'),
    ('Title Small', 'titleSmall'),
    ('Body Large', 'bodyLarge'),
    ('Body Medium', 'bodyMedium'),
    ('Body Small', 'bodySmall'),
    ('Label Large', 'labelLarge'),
    ('Label Medium', 'labelMedium'),
    ('Label Small', 'labelSmall'),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _textStyleEntries.map((entry) {
        final style = _getTextStyle(textTheme, entry.$2);
        return Text(entry.$1, style: style);
      }).toList(),
    );
  }

  TextStyle? _getTextStyle(TextTheme textTheme, String styleName) =>
      switch (styleName) {
        'displayLarge' => textTheme.displayLarge,
        'displayMedium' => textTheme.displayMedium,
        'displaySmall' => textTheme.displaySmall,
        'headlineLarge' => textTheme.headlineLarge,
        'headlineMedium' => textTheme.headlineMedium,
        'headlineSmall' => textTheme.headlineSmall,
        'titleLarge' => textTheme.titleLarge,
        'titleMedium' => textTheme.titleMedium,
        'titleSmall' => textTheme.titleSmall,
        'bodyLarge' => textTheme.bodyLarge,
        'bodyMedium' => textTheme.bodyMedium,
        'bodySmall' => textTheme.bodySmall,
        'labelLarge' => textTheme.labelLarge,
        'labelMedium' => textTheme.labelMedium,
        'labelSmall' => textTheme.labelSmall,
        _ => null,
      };
}

// Buttons Component
class ButtonDisplay extends StatelessWidget {
  const ButtonDisplay({super.key});

  static void _emptyCallback() {}

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          const ElevatedButton(
            onPressed: _emptyCallback,
            child: Text('Elevated Button'),
          ),
          const FilledButton(
            onPressed: _emptyCallback,
            child: Text('Filled Button'),
          ),
          const FilledButton.tonal(
            onPressed: _emptyCallback,
            child: Text('Filled Tonal Button'),
          ),
          const OutlinedButton(
            onPressed: _emptyCallback,
            child: Text('Outlined Button'),
          ),
          const TextButton(
            onPressed: _emptyCallback,
            child: Text('Text Button'),
          ),
          const IconButton(
            onPressed: _emptyCallback,
            icon: Icon(Icons.star),
          ),
          ToggleButtons(
            isSelected: const [true, false, false],
            onPressed: (_) {},
            children: const [
              Icon(Icons.format_bold),
              Icon(Icons.format_italic),
              Icon(Icons.format_underline),
            ],
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

  static void _dismissKeyboard(PointerDownEvent event) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  static List<PopupMenuEntry<String>> _buildPopupMenuItems(
    BuildContext context,
  ) =>
      const [
        PopupMenuItem(value: 'Option 1', child: Text('Option 1')),
        PopupMenuItem(value: 'Option 2', child: Text('Option 2')),
      ];

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const TextField(
            decoration: InputDecoration(labelText: 'TextField'),
            onTapOutside: _dismissKeyboard,
          ),
          const Gap(8),
          const SearchBar(
            hintText: 'SearchBar',
            onTapOutside: _dismissKeyboard,
          ),
          const Gap(8),
          ElevatedButton(
            onPressed: () => _showDatePicker(context),
            child: const Text('Date Picker'),
          ),
          const Gap(8),
          DropdownButton<String>(
            value: 'Option 1',
            items: const [
              DropdownMenuItem(value: 'Option 1', child: Text('Option 1')),
              DropdownMenuItem(value: 'Option 2', child: Text('Option 2')),
            ],
            onChanged: (_) {},
          ),
          const Gap(8),
          ElevatedButton(
            onPressed: () => _showTimePicker(context),
            child: const Text('Time Picker'),
          ),
          const Gap(8),
          const PopupMenuButton<String>(itemBuilder: _buildPopupMenuItems),
          const RadioMenuButton<String>(
            onChanged: null,
            value: '',
            groupValue: '',
            child: Text('Radio Button'),
          ),
        ],
      );

  void _showDatePicker(BuildContext context) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  void _showTimePicker(BuildContext context) {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
  }
}

// Selection Controls Component
class SelectionControlsDisplay extends StatelessWidget {
  const SelectionControlsDisplay({super.key});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const Row(
            children: [
              Checkbox(value: true, onChanged: null),
              Text('Checkbox'),
            ],
          ),
          Row(
            children: [
              Radio(
                value: true,
                groupValue: null,
                onChanged: (value) {},
              ),
              const Text('Radio'),
            ],
          ),
          const Row(
            children: [
              Switch(value: true, onChanged: null),
              Text('Switch'),
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

/// Color scheme data for display
final List<(String, Color Function(ColorScheme))> _colorSchemeEntries = [
  ('Primary', (s) => s.primary),
  ('On Primary', (s) => s.onPrimary),
  ('Primary Container', (s) => s.primaryContainer),
  ('On Primary Container', (s) => s.onPrimaryContainer),
  ('Primary Fixed', (s) => s.primaryFixed),
  ('Primary Fixed Dim', (s) => s.primaryFixedDim),
  ('On Primary Fixed', (s) => s.onPrimaryFixed),
  ('On Primary Fixed Variant', (s) => s.onPrimaryFixedVariant),
  ('Secondary', (s) => s.secondary),
  ('On Secondary', (s) => s.onSecondary),
  ('Secondary Container', (s) => s.secondaryContainer),
  ('On Secondary Container', (s) => s.onSecondaryContainer),
  ('Secondary Fixed', (s) => s.secondaryFixed),
  ('Secondary Fixed Dim', (s) => s.secondaryFixedDim),
  ('On Secondary Fixed', (s) => s.onSecondaryFixed),
  ('On Secondary Fixed Variant', (s) => s.onSecondaryFixedVariant),
  ('Tertiary', (s) => s.tertiary),
  ('On Tertiary', (s) => s.onTertiary),
  ('Tertiary Container', (s) => s.tertiaryContainer),
  ('On Tertiary Container', (s) => s.onTertiaryContainer),
  ('Tertiary Fixed', (s) => s.tertiaryFixed),
  ('Tertiary Fixed Dim', (s) => s.tertiaryFixedDim),
  ('On Tertiary Fixed', (s) => s.onTertiaryFixed),
  ('On Tertiary Fixed Variant', (s) => s.onTertiaryFixedVariant),
  ('Error', (s) => s.error),
  ('On Error', (s) => s.onError),
  ('Error Container', (s) => s.errorContainer),
  ('On Error Container', (s) => s.onErrorContainer),
  ('Surface', (s) => s.surface),
  ('On Surface', (s) => s.onSurface),
  ('Surface Dim', (s) => s.surfaceDim),
  ('Surface Bright', (s) => s.surfaceBright),
  ('Surface Container', (s) => s.surfaceContainer),
  ('Surface Container High', (s) => s.surfaceContainerHigh),
  ('Surface Container Highest', (s) => s.surfaceContainerHighest),
  ('Inverse Surface', (s) => s.inverseSurface),
  ('On Inverse Surface', (s) => s.onInverseSurface),
  ('Inverse Primary', (s) => s.inversePrimary),
  ('Surface Tint', (s) => s.surfaceTint),
  ('Outline', (s) => s.outline),
  ('Outline Variant', (s) => s.outlineVariant),
  ('Shadow', (s) => s.shadow),
  ('Scrim', (s) => s.scrim),
];

// Color Scheme Component
class ColorSchemeDisplay extends StatelessWidget {
  const ColorSchemeDisplay({required this.colorScheme, super.key});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _colorSchemeEntries
            .map((e) => ColorBox(label: e.$1, color: e.$2(colorScheme)))
            .toList(),
      );
}

// Color Box Component
class ColorBox extends StatelessWidget {
  const ColorBox({required this.label, required this.color, super.key});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? Colors.grey;
    return Card(
      color: displayColor,
      child: SizedBox.square(
        dimension: 80,
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: getTextColorOnBackground(displayColor),
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

// Dialogs and Snackbars Component
class DialogsSnackbarsDisplay extends StatelessWidget {
  const DialogsSnackbarsDisplay({super.key});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ElevatedButton(
            onPressed: () => _showBottomSheet(context),
            child: const Text('Show Bottom Sheet'),
          ),
          ElevatedButton(
            onPressed: () => _showDialog(context),
            child: const Text('Show Dialog'),
          ),
          ElevatedButton(
            onPressed: () => _showSnackbar(context),
            child: const Text('Show Snackbar'),
          ),
        ],
      );

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Bottom Sheet')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context) {
    showDialog<void>(
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
    );
  }

  void _showSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This is a snackbar')),
    );
  }
}
