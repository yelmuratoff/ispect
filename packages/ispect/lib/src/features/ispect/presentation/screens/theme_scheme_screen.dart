import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/inspector/src/widgets/color_picker/utils.dart';

class ThemeSchemeScreen extends StatelessWidget {
  const ThemeSchemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = ISpect.read(context).theme.backgroundColor(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text('Theme Scheme'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
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
              Expanded(
                child: _SectionDivider(color: primaryColor, isLeft: true),
              ),
              _SectionTitle(title: title, color: primaryColor),
              Expanded(
                child: _SectionDivider(color: primaryColor, isRight: true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({
    required this.color,
    this.isLeft = false,
    this.isRight = false,
  });

  final Color color;
  final bool isLeft;
  final bool isRight;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 4,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: isLeft ? const Radius.circular(4) : Radius.zero,
              bottomLeft: isLeft ? const Radius.circular(4) : Radius.zero,
              topRight: isRight ? const Radius.circular(4) : Radius.zero,
              bottomRight: isRight ? const Radius.circular(4) : Radius.zero,
            ),
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
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
class ButtonDisplay extends StatelessWidget {
  const ButtonDisplay({super.key});

  static void _emptyCallback() {}

  @override
  Widget build(BuildContext context) => const Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ElevatedButton(
            onPressed: _emptyCallback,
            child: Text('Elevated Button'),
          ),
          FilledButton(
            onPressed: _emptyCallback,
            child: Text('Filled Button'),
          ),
          FilledButton.tonal(
            onPressed: _emptyCallback,
            child: Text('Filled Tonal Button'),
          ),
          OutlinedButton(
            onPressed: _emptyCallback,
            child: Text('Outlined Button'),
          ),
          TextButton(
            onPressed: _emptyCallback,
            child: Text('Text Button'),
          ),
          IconButton(
            onPressed: _emptyCallback,
            icon: Icon(Icons.star),
          ),
          _ToggleButtonsWidget(),
          _SegmentedButtonWidget(),
        ],
      );
}

class _ToggleButtonsWidget extends StatelessWidget {
  const _ToggleButtonsWidget();

  @override
  Widget build(BuildContext context) => ToggleButtons(
        isSelected: const [true, false, false],
        onPressed: (_) {},
        children: const [
          Icon(Icons.format_bold),
          Icon(Icons.format_italic),
          Icon(Icons.format_underline),
        ],
      );
}

class _SegmentedButtonWidget extends StatelessWidget {
  const _SegmentedButtonWidget();

  @override
  Widget build(BuildContext context) => SegmentedButton<String>(
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
        onSelectionChanged: (_) {},
      );
}

// Inputs Component
class InputDisplay extends StatelessWidget {
  const InputDisplay({super.key});

  static void _dismissKeyboard(PointerDownEvent event) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) => const Column(
        children: [
          TextField(
            decoration: InputDecoration(labelText: 'TextField'),
            onTapOutside: _dismissKeyboard,
          ),
          Gap(8),
          SearchBar(
            hintText: 'SearchBar',
            onTapOutside: _dismissKeyboard,
          ),
          Gap(8),
          _DatePickerButton(),
          Gap(8),
          _DropdownWidget(),
          Gap(8),
          _TimePickerButton(),
          Gap(8),
          _PopupMenuWidget(),
          _RadioMenuWidget(),
        ],
      );
}

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton();

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: () => _showDatePicker(context),
        child: const Text('Date Picker'),
      );

  void _showDatePicker(BuildContext context) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  const _TimePickerButton();

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: () => _showTimePicker(context),
        child: const Text('Time Picker'),
      );

  void _showTimePicker(BuildContext context) {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
  }
}

class _DropdownWidget extends StatelessWidget {
  const _DropdownWidget();

  @override
  Widget build(BuildContext context) => DropdownButton<String>(
        value: 'Option 1',
        items: const [
          DropdownMenuItem(value: 'Option 1', child: Text('Option 1')),
          DropdownMenuItem(value: 'Option 2', child: Text('Option 2')),
        ],
        onChanged: (_) {},
      );
}

class _PopupMenuWidget extends StatelessWidget {
  const _PopupMenuWidget();

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'Option 1', child: Text('Option 1')),
          PopupMenuItem(value: 'Option 2', child: Text('Option 2')),
        ],
      );
}

class _RadioMenuWidget extends StatelessWidget {
  const _RadioMenuWidget();

  @override
  Widget build(BuildContext context) => const RadioMenuButton<String>(
        onChanged: null,
        value: '',
        groupValue: '',
        child: Text('Radio Button'),
      );
}

// Selection Controls Component
class SelectionControlsDisplay extends StatelessWidget {
  const SelectionControlsDisplay({super.key});

  @override
  Widget build(BuildContext context) => const Column(
        children: [
          Row(
            children: [
              Checkbox(value: true, onChanged: null),
              Text('Checkbox'),
            ],
          ),
          _RadioControlRow(),
          Row(
            children: [
              Switch(value: true, onChanged: null),
              Text('Switch'),
            ],
          ),
        ],
      );
}

class _RadioControlRow extends StatelessWidget {
  const _RadioControlRow();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Radio<bool>(
            value: true,
            groupValue: null,
            onChanged: (_) {},
          ),
          const Text('Radio'),
        ],
      );
}

// List Tiles Component
class ListTilesDisplay extends StatelessWidget {
  const ListTilesDisplay({super.key});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('ListTile 1'),
          ),
          const ListTile(
            leading: Icon(Icons.settings),
            title: Text('ListTile 2'),
          ),
          const ExpansionTile(
            title: Text('Expandable Tile'),
            children: [Text('Expanded Content')],
          ),
          Divider(
            color: Colors.grey.shade400,
            thickness: 1,
          ),
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
          Slider(
            value: 0.5,
            onChanged: (_) {},
          ),
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
            .map(
              (entry) => ColorBox(
                label: entry.$1,
                color: entry.$2(colorScheme),
              ),
            )
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
