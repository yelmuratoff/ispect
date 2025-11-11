import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/json_viewer/extensions/color_extensions.dart';

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
class ButtonDisplay extends StatefulWidget {
  const ButtonDisplay({super.key});

  @override
  State<ButtonDisplay> createState() => _ButtonDisplayState();
}

class _ButtonDisplayState extends State<ButtonDisplay> {
  final List<bool> _toggleSelection = [true, false, false];
  Set<String> _segmentedSelection = {'Segment 1'};

  void _showButtonFeedback(BuildContext context, String buttonType) {
    if (kDebugMode) {
      debugPrint('🎯 Button interaction: $buttonType');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$buttonType pressed!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Button States:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Gap(8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () =>
                    _showButtonFeedback(context, 'Elevated Button'),
                child: const Text('Elevated Button'),
              ),
              FilledButton(
                onPressed: () => _showButtonFeedback(context, 'Filled Button'),
                child: const Text('Filled Button'),
              ),
              FilledButton.tonal(
                onPressed: () =>
                    _showButtonFeedback(context, 'Filled Tonal Button'),
                child: const Text('Filled Tonal Button'),
              ),
              OutlinedButton(
                onPressed: () =>
                    _showButtonFeedback(context, 'Outlined Button'),
                child: const Text('Outlined Button'),
              ),
              TextButton(
                onPressed: () => _showButtonFeedback(context, 'Text Button'),
                child: const Text('Text Button'),
              ),
              IconButton(
                onPressed: () => _showButtonFeedback(context, 'Icon Button'),
                icon: const Icon(Icons.star),
              ),
            ],
          ),
          const Gap(16),
          _ToggleButtonsWidget(
            isSelected: _toggleSelection,
            onPressed: (index) {
              setState(() {
                _toggleSelection[index] = !_toggleSelection[index];
              });
            },
          ),
          const Gap(8),
          _SegmentedButtonWidget(
            selected: _segmentedSelection,
            onSelectionChanged: (newSelection) {
              setState(() {
                _segmentedSelection = newSelection;
              });
            },
          ),
          const Gap(16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toggle States:',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text('Bold: ${_toggleSelection[0] ? "ON" : "OFF"}'),
                Text('Italic: ${_toggleSelection[1] ? "ON" : "OFF"}'),
                Text('Underline: ${_toggleSelection[2] ? "ON" : "OFF"}'),
                Text('Selected Segment: ${_segmentedSelection.join(", ")}'),
              ],
            ),
          ),
        ],
      );
}

class _ToggleButtonsWidget extends StatelessWidget {
  const _ToggleButtonsWidget({
    required this.isSelected,
    required this.onPressed,
  });

  final List<bool> isSelected;
  final ValueChanged<int> onPressed;

  @override
  Widget build(BuildContext context) => ToggleButtons(
        isSelected: isSelected,
        onPressed: onPressed,
        children: const [
          Icon(Icons.format_bold),
          Icon(Icons.format_italic),
          Icon(Icons.format_underline),
        ],
      );
}

class _SegmentedButtonWidget extends StatelessWidget {
  const _SegmentedButtonWidget({
    required this.selected,
    required this.onSelectionChanged,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onSelectionChanged;

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
        selected: selected,
        onSelectionChanged: onSelectionChanged,
      );
}

// Inputs Component
class InputDisplay extends StatefulWidget {
  const InputDisplay({super.key});

  @override
  State<InputDisplay> createState() => _InputDisplayState();
}

class _InputDisplayState extends State<InputDisplay> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedDropdownValue = 'Option 1';
  String _selectedRadioMenuValue = 'option1';

  static void _dismissKeyboard(PointerDownEvent event) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Input Values:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Gap(8),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(labelText: 'TextField'),
            onTapOutside: _dismissKeyboard,
            onChanged: (_) => setState(() {}),
          ),
          const Gap(8),
          SearchBar(
            controller: _searchController,
            hintText: 'SearchBar',
            onTapOutside: _dismissKeyboard,
            onChanged: (_) => setState(() {}),
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Values:',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text('TextField: "${_textController.text}"'),
                Text('SearchBar: "${_searchController.text}"'),
                Text('Dropdown: $_selectedDropdownValue'),
                Text('Radio Menu: $_selectedRadioMenuValue'),
              ],
            ),
          ),
          const Gap(8),
          const _DatePickerButton(),
          const Gap(8),
          _DropdownWidget(
            value: _selectedDropdownValue,
            onChanged: (value) {
              setState(() {
                _selectedDropdownValue = value ?? 'Option 1';
              });
            },
          ),
          const Gap(8),
          const _TimePickerButton(),
          const Gap(8),
          const _PopupMenuWidget(),
          _RadioMenuWidget(
            value: _selectedRadioMenuValue,
            groupValue: _selectedRadioMenuValue,
            onChanged: (value) {
              setState(() {
                _selectedRadioMenuValue = value ?? 'option1';
              });
            },
          ),
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
  const _DropdownWidget({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButton<String>(
        value: value,
        items: const [
          DropdownMenuItem(value: 'Option 1', child: Text('Option 1')),
          DropdownMenuItem(value: 'Option 2', child: Text('Option 2')),
          DropdownMenuItem(value: 'Option 3', child: Text('Option 3')),
        ],
        onChanged: onChanged,
      );
}

class _PopupMenuWidget extends StatefulWidget {
  const _PopupMenuWidget();

  @override
  State<_PopupMenuWidget> createState() => _PopupMenuWidgetState();
}

class _PopupMenuWidgetState extends State<_PopupMenuWidget> {
  String _selectedItem = 'No selection';

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text('Selected: $_selectedItem'),
          PopupMenuButton<String>(
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'Option 1', child: Text('Option 1')),
              PopupMenuItem(value: 'Option 2', child: Text('Option 2')),
              PopupMenuItem(value: 'Option 3', child: Text('Option 3')),
            ],
            onSelected: (value) {
              setState(() {
                _selectedItem = value;
              });
            },
            child: const Chip(
              label: Text('Popup Menu'),
              avatar: Icon(Icons.arrow_drop_down),
            ),
          ),
        ],
      );
}

class _RadioMenuWidget extends StatelessWidget {
  const _RadioMenuWidget({
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          // ignore: deprecated_member_use
          Radio<String>(
            value: value,
            // ignore: deprecated_member_use
            groupValue: groupValue,
            // ignore: deprecated_member_use
            onChanged: onChanged,
          ),
          const Text('Radio Menu Button'),
        ],
      );
}

// Selection Controls Component
class SelectionControlsDisplay extends StatefulWidget {
  const SelectionControlsDisplay({super.key});

  @override
  State<SelectionControlsDisplay> createState() =>
      _SelectionControlsDisplayState();
}

class _SelectionControlsDisplayState extends State<SelectionControlsDisplay> {
  bool _checkboxValue = true;
  bool _switchValue = true;
  String? _radioValue = 'option1';

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Controls State:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Gap(8),
          Row(
            children: [
              Checkbox(
                value: _checkboxValue,
                onChanged: (value) {
                  setState(() {
                    _checkboxValue = value ?? false;
                  });
                },
              ),
              Text('Checkbox: ${_checkboxValue ? "Checked" : "Unchecked"}'),
            ],
          ),
          _RadioControlRow(
            groupValue: _radioValue,
            onChanged: (value) {
              setState(() {
                _radioValue = value;
              });
            },
          ),
          Row(
            children: [
              Switch(
                value: _switchValue,
                onChanged: (value) {
                  setState(() {
                    _switchValue = value;
                  });
                },
              ),
              Text('Switch: ${_switchValue ? "On" : "Off"}'),
            ],
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Radio selected: ${_radioValue ?? "None"}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      );
}

class _RadioControlRow extends StatelessWidget {
  const _RadioControlRow({
    required this.groupValue,
    required this.onChanged,
  });

  final String? groupValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          // ignore: deprecated_member_use
          Radio<String>(
            value: 'option1',
            // ignore: deprecated_member_use
            groupValue: groupValue,
            // ignore: deprecated_member_use
            onChanged: onChanged,
          ),
          const Text('Radio'),
        ],
      );
}

// List Tiles Component
class ListTilesDisplay extends StatefulWidget {
  const ListTilesDisplay({super.key});

  @override
  State<ListTilesDisplay> createState() => _ListTilesDisplayState();
}

class _ListTilesDisplayState extends State<ListTilesDisplay> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('ListTile 1'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ListTile 1 tapped!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('ListTile 2'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ListTile 2 tapped!')),
              );
            },
          ),
          ExpansionTile(
            title: const Text('Expandable Tile'),
            initiallyExpanded: _isExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _isExpanded = expanded;
              });
            },
            children: const [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text('Expanded Content - This tile can be expanded!'),
              ),
            ],
          ),
          Divider(
            color: Colors.grey.shade400,
            thickness: 1,
          ),
        ],
      );
}

// Progress and Sliders Component
class ProgressSlidersDisplay extends StatefulWidget {
  const ProgressSlidersDisplay({super.key});

  @override
  State<ProgressSlidersDisplay> createState() => _ProgressSlidersDisplayState();
}

class _ProgressSlidersDisplayState extends State<ProgressSlidersDisplay>
    with TickerProviderStateMixin {
  double _sliderValue = 0.5;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) => LinearProgressIndicator(
              value: _progressController.value,
            ),
          ),
          const Gap(16),
          const CircularProgressIndicator(),
          const Gap(16),
          Column(
            children: [
              Text('Slider Value: ${_sliderValue.toStringAsFixed(2)}'),
              Slider(
                value: _sliderValue,
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                  });
                },
              ),
            ],
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
              color: displayColor.contrastText(),
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
