import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/utils/squircle.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/ispect_app_bar_title.dart';
import 'package:ispect/src/common/widgets/ispect_bordered_surface.dart';
import 'package:ispect/src/common/widgets/ispect_flat_app_bar.dart';
import 'package:ispect/src/common/widgets/ispect_input.dart';
import 'package:ispect/src/common/widgets/ispect_theme_scope.dart';
import 'package:ispect/src/common/widgets/resizable_split_view.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/core/res/json_color.dart';
import 'package:ispect/src/features/http_composer/controllers/http_composer_controller.dart';

const List<String> _httpMethods = [
  'GET',
  'POST',
  'PUT',
  'PATCH',
  'DELETE',
  'HEAD',
  'OPTIONS',
];

const double _kTabletFormMaxWidth = 720;
const int _kInlinePreviewMaxLines = 12;

/// In-app HTTP composer ("mini-Postman"): edit/replay a captured request or
/// build one from scratch and send it through a registered client.
class HttpComposerScreen extends StatefulWidget {
  const HttpComposerScreen({
    required this.senders,
    this.onPickComposerFile,
    this.seed,
    super.key,
  });

  final List<NetworkRequestSender> senders;
  final ISpectComposerFilePicker? onPickComposerFile;

  /// Optional request to pre-fill the form (used by "edit & resend").
  final NetworkReplayRequest? seed;

  /// Opens the composer pre-filled from a captured network [log].
  ///
  /// Pushes onto the nearest navigator (ISpect's own), reusing the registered
  /// senders and the host's file picker. Wrapped in [ISpectScopeController] so
  /// the screen resolves ISpect theme/localization on routes that don't inherit
  /// the scope.
  static Future<void> openFromLog(BuildContext context, ISpectLogData log) {
    final model = ISpect.read(context);
    final seed = HttpComposerController.seedFromLog(log);
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ISpectScopeController(
          model: model,
          child: HttpComposerScreen(
            senders: ISpect.senders,
            onPickComposerFile: model.options.onPickComposerFile,
            seed: seed,
          ),
        ),
        settings: const RouteSettings(name: 'ISpect HTTP Composer'),
      ),
    );
  }

  @override
  State<HttpComposerScreen> createState() => _HttpComposerScreenState();
}

class _HttpComposerScreenState extends State<HttpComposerScreen> {
  late final HttpComposerController _controller = HttpComposerController(
    senders: widget.senders,
    filePicker: widget.onPickComposerFile,
    seed: widget.seed,
  );
  late final TextEditingController _urlController =
      TextEditingController(text: _controller.url);
  late final TextEditingController _bodyController =
      TextEditingController(text: _controller.bodyText);

  double _splitRatio = 0.5;

  @override
  void dispose() {
    _controller.dispose();
    _urlController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ISpectThemeScope(child: Builder(builder: _buildScaffold));

  Widget _buildScaffold(BuildContext context) => Scaffold(
        backgroundColor: context.ispectThemeBackground,
        appBar: ISpectFlatAppBar(
          title: ISpectAppBarTitle(
            child: Text(context.ispectL10n.composerTitle),
          ),
          leading: const ISpectAppBarBackButton(),
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => _ComposerBody(
              controller: _controller,
              urlController: _urlController,
              bodyController: _bodyController,
              initialSplitRatio: _splitRatio,
              onSplitRatioChanged: (ratio) => _splitRatio = ratio,
            ),
          ),
        ),
      );
}

class _ComposerBody extends StatelessWidget {
  const _ComposerBody({
    required this.controller,
    required this.urlController,
    required this.bodyController,
    required this.initialSplitRatio,
    required this.onSplitRatioChanged,
  });

  final HttpComposerController controller;
  final TextEditingController urlController;
  final TextEditingController bodyController;
  final double initialSplitRatio;
  final ValueChanged<double> onSplitRatioChanged;

  @override
  Widget build(BuildContext context) {
    if (controller.senders.isEmpty) {
      return _CenteredMessage(
        icon: Icons.cloud_off_rounded,
        message: context.ispectL10n.composerNoClients,
      );
    }

    return context.screenSizeWhen(
      phone: () => _RequestPane(
        controller: controller,
        urlController: urlController,
        bodyController: bodyController,
        showInlineResult: true,
      ),
      tablet: () => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kTabletFormMaxWidth),
          child: _RequestPane(
            controller: controller,
            urlController: urlController,
            bodyController: bodyController,
            showInlineResult: true,
          ),
        ),
      ),
      desktop: () => ResizableSplitView(
        initialRatio: initialSplitRatio,
        minRatio: 0.3,
        maxRatio: 0.7,
        onRatioChanged: onSplitRatioChanged,
        left: _RequestPane(
          controller: controller,
          urlController: urlController,
          bodyController: bodyController,
          showInlineResult: false,
        ),
        right: _ResponsePane(controller: controller),
      ),
    );
  }
}

class _RequestPane extends StatelessWidget {
  const _RequestPane({
    required this.controller,
    required this.urlController,
    required this.bodyController,
    required this.showInlineResult,
  });

  final HttpComposerController controller;
  final TextEditingController urlController;
  final TextEditingController bodyController;
  final bool showInlineResult;

  @override
  Widget build(BuildContext context) {
    final l10n = context.ispectL10n;
    final result = controller.result;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _RequestHeaderCard(
                controller: controller,
                urlController: urlController,
              ),
              const Gap(16),
              _KeyValueSection(
                title: l10n.composerHeaders,
                addLabel: l10n.composerAddHeader,
                rows: controller.headers,
                onAdd: controller.addHeader,
                onRemove: controller.removeHeaderAt,
              ),
              const Gap(12),
              _KeyValueSection(
                title: l10n.composerQueryParameters,
                addLabel: l10n.composerAddParameter,
                rows: controller.queryParams,
                onAdd: controller.addQueryParam,
                onRemove: controller.removeQueryParamAt,
              ),
              const Gap(12),
              _ComposerSection(
                title: l10n.composerBody,
                child: _BodyEditor(
                  controller: controller,
                  bodyController: bodyController,
                ),
              ),
              if (showInlineResult && result != null) ...[
                const Gap(20),
                _ResultView(result: result),
              ],
            ],
          ),
        ),
        _ComposerFooter(controller: controller),
      ],
    );
  }
}

class _ResponsePane extends StatelessWidget {
  const _ResponsePane({required this.controller});

  final HttpComposerController controller;

  @override
  Widget build(BuildContext context) {
    final result = controller.result;
    if (result == null) {
      return _CenteredMessage(
        icon: Icons.inbox_rounded,
        message: context.ispectL10n.composerResponsePlaceholder,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ResultView(
            result: result,
            previewMaxLines: _previewLinesFor(constraints.maxHeight),
          ),
        ],
      ),
    );
  }

  static int _previewLinesFor(double paneHeight) {
    const lineHeight = ISpectInputStyle.fontSize * 1.4;
    const chromeHeight = 140.0;
    return ((paneHeight - chromeHeight) / lineHeight).floor().clamp(
          _kInlinePreviewMaxLines,
          400,
        );
  }
}

class _ComposerFooter extends StatelessWidget {
  const _ComposerFooter({required this.controller});

  final HttpComposerController controller;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: context.ispectSubtleBorderColor),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.validationError != null) ...[
                  _ValidationText(error: controller.validationError!),
                  const Gap(12),
                ],
                _SendButton(controller: controller),
              ],
            ),
          ),
        ),
      );
}

class _RequestHeaderCard extends StatelessWidget {
  const _RequestHeaderCard({
    required this.controller,
    required this.urlController,
  });

  final HttpComposerController controller;
  final TextEditingController urlController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.ispectL10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _MethodPill(controller: controller),
            if (controller.senders.length > 1) ...[
              const Gap(8),
              Expanded(child: _ClientPill(controller: controller)),
            ],
          ],
        ),
        const Gap(10),
        ISpectTextField(
          controller: urlController,
          hintText: l10n.composerUrlHint,
          keyboardType: TextInputType.url,
          prefixIcon: Icon(
            Icons.link_rounded,
            size: 18,
            color:
                context.appTheme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          suffixIcon: controller.url.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  splashRadius: 18,
                  visualDensity: VisualDensity.compact,
                  color: context.appTheme.colorScheme.onSurface
                      .withValues(alpha: 0.5),
                  onPressed: () {
                    urlController.clear();
                    controller.setUrl('');
                  },
                ),
          onChanged: controller.setUrl,
        ),
      ],
    );
  }
}

class _MethodPill extends StatelessWidget {
  const _MethodPill({required this.controller});

  final HttpComposerController controller;

  @override
  Widget build(BuildContext context) => _SelectPill<String>(
        value: controller.method,
        items: _httpMethods,
        labelOf: (method) => method,
        accentOf: (method) =>
            JsonColors.methodColorFor(method, Theme.of(context).brightness) ??
            context.ispectPrimaryColor,
        onSelected: controller.setMethod,
      );
}

class _ClientPill extends StatelessWidget {
  const _ClientPill({required this.controller});

  final HttpComposerController controller;

  @override
  Widget build(BuildContext context) {
    final senders = controller.senders;
    return _SelectPill<String>(
      value: controller.selectedSenderId ?? senders.first.id,
      items: [for (final sender in senders) sender.id],
      labelOf: (id) => senders.firstWhere((s) => s.id == id).label,
      leading: Icons.dns_rounded,
      isExpanded: true,
      onSelected: controller.selectSender,
    );
  }
}

class _SelectPill<T> extends StatelessWidget {
  const _SelectPill({
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onSelected,
    this.accentOf,
    this.leading,
    this.isExpanded = false,
  });

  final T value;
  final List<T> items;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;
  final Color Function(T value)? accentOf;
  final IconData? leading;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.appTheme.colorScheme.onSurface;
    final labelColor = accentOf?.call(value) ?? onSurface;
    final leadingIcon = leading;

    final label = Text(
      labelOf(value),
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: labelColor,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );

    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(context.ispectCardColor),
        elevation: const WidgetStatePropertyAll(8),
        padding:
            const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
        shape: WidgetStatePropertyAll(
          ISpectSquircle.border(
            side: BorderSide(color: context.ispectSubtleBorderColor),
          ),
        ),
      ),
      menuChildren: [
        for (final item in items)
          _SelectMenuItem<T>(
            label: labelOf(item),
            color: accentOf?.call(item),
            selected: item == value,
            onPressed: () => onSelected(item),
          ),
      ],
      builder: (context, menu, _) => ISpectBorderedSurface(
        onTap: () => menu.isOpen ? menu.close() : menu.open(),
        backgroundColor: context.ispectCardColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: 16,
                color: onSurface.withValues(alpha: 0.6),
              ),
              const Gap(8),
            ],
            if (isExpanded) Expanded(child: label) else label,
            const Gap(8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectMenuItem<T> extends StatelessWidget {
  const _SelectMenuItem({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final primary = context.ispectPrimaryColor;
    return MenuItemButton(
      onPressed: onPressed,
      trailingIcon:
          selected ? Icon(Icons.check_rounded, size: 18, color: primary) : null,
      child: Text(
        label,
        style: TextStyle(
          color: color ?? context.appTheme.colorScheme.onSurface,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _ComposerSection extends StatelessWidget {
  const _ComposerSection({
    required this.title,
    required this.child,
    this.count,
  });

  final String title;
  final Widget child;
  final int? count;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, count: count),
          ISpectBorderedSurface(
            backgroundColor: context.ispectCardColor,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: child,
          ),
        ],
      );
}

class _KeyValueSection extends StatelessWidget {
  const _KeyValueSection({
    required this.title,
    required this.addLabel,
    required this.rows,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final String addLabel;
  final List<ComposerKeyValue> rows;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title),
          _SlimAddButton(label: addLabel, onTap: onAdd),
        ],
      );
    }
    return _ComposerSection(
      title: title,
      count: rows.length,
      child: _KeyValueEditor(
        rows: rows,
        addLabel: addLabel,
        onAdd: onAdd,
        onRemove: onRemove,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final badgeCount = count;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          _SectionTitle(title),
          if (badgeCount != null && badgeCount > 0) ...[
            const Gap(8),
            _CountBadge(count: badgeCount),
          ],
        ],
      ),
    );
  }
}

class _SlimAddButton extends StatelessWidget {
  const _SlimAddButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = context.ispectPrimaryColor;
    return ISpectBorderedSurface(
      onTap: onTap,
      backgroundColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.add_rounded, size: 18, color: primary),
          const Gap(8),
          Text(
            label,
            style: TextStyle(color: primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.appTheme.colorScheme.onSurface;
    return DecoratedBox(
      decoration: ISpectSquircle.decoration(
        color: onSurface.withValues(alpha: 0.06),
        radius: ISpectConstants.standardBorderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(
          '$count',
          style: TextStyle(
            color: onSurface.withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _BodyEditor extends StatelessWidget {
  const _BodyEditor({required this.controller, required this.bodyController});

  final HttpComposerController controller;
  final TextEditingController bodyController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.ispectL10n;
    final kind = controller.bodyKind;
    final editor = switch (kind) {
      ComposerBodyKind.none => null,
      ComposerBodyKind.json || ComposerBodyKind.text => ISpectTextField(
          controller: bodyController,
          minLines: 4,
          maxLines: 12,
          onChanged: controller.setBodyText,
        ),
      ComposerBodyKind.formUrlEncoded => _KeyValueEditor(
          rows: controller.formFields,
          addLabel: l10n.composerAddField,
          onAdd: controller.addFormField,
          onRemove: controller.removeFormFieldAt,
        ),
      ComposerBodyKind.multipart => _MultipartEditor(controller: controller),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BodyKindSelector(
          selected: kind,
          onSelected: controller.setBodyKind,
        ),
        if (editor != null) ...[const Gap(12), editor],
      ],
    );
  }
}

class _BodyKindSelector extends StatelessWidget {
  const _BodyKindSelector({required this.selected, required this.onSelected});

  final ComposerBodyKind selected;
  final ValueChanged<ComposerBodyKind> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final kind in ComposerBodyKind.values)
            _ChoicePill(
              label: _bodyKindLabel(kind),
              selected: kind == selected,
              onTap: () => onSelected(kind),
            ),
        ],
      );

  static String _bodyKindLabel(ComposerBodyKind kind) => switch (kind) {
        ComposerBodyKind.none => 'None',
        ComposerBodyKind.json => 'JSON',
        ComposerBodyKind.text => 'Text',
        ComposerBodyKind.formUrlEncoded => 'Form',
        ComposerBodyKind.multipart => 'Multipart',
      };
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = context.ispectPrimaryColor;
    return ISpectBorderedSurface(
      onTap: onTap,
      backgroundColor:
          selected ? primary.withValues(alpha: 0.14) : Colors.transparent,
      borderColor: selected ? primary.withValues(alpha: 0.45) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[
            Icon(Icons.check_rounded, size: 15, color: primary),
            const Gap(4),
          ],
          Text(
            label,
            style: TextStyle(
              color: selected
                  ? primary
                  : context.appTheme.colorScheme.onSurface
                      .withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MultipartEditor extends StatelessWidget {
  const _MultipartEditor({required this.controller});

  final HttpComposerController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.ispectL10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KeyValueEditor(
          rows: controller.multipartFields,
          addLabel: l10n.composerAddField,
          onAdd: controller.addMultipartField,
          onRemove: controller.removeMultipartFieldAt,
        ),
        for (var i = 0; i < controller.multipartFiles.length; i++)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.attach_file_rounded),
            title: Text(controller.multipartFiles[i].file.filename),
            subtitle: Text(controller.multipartFiles[i].field),
            trailing: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => controller.removeFileAt(i),
            ),
          ),
        if (controller.canAttachFiles)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.composerAttachFile),
              onPressed: () => controller.attachFile('file'),
            ),
          ),
      ],
    );
  }
}

class _KeyValueEditor extends StatelessWidget {
  const _KeyValueEditor({
    required this.rows,
    required this.addLabel,
    required this.onAdd,
    required this.onRemove,
  });

  final List<ComposerKeyValue> rows;
  final String addLabel;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.ispectL10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows.length; i++)
          Padding(
            key: ObjectKey(rows[i]),
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: rows[i].key,
                    style: ISpectInputStyle.textStyle(context),
                    decoration: ispectInputDecoration(
                      context,
                      hintText: l10n.composerKeyHint,
                    ),
                    onChanged: (value) => rows[i].key = value,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: rows[i].value,
                    style: ISpectInputStyle.textStyle(context),
                    decoration: ispectInputDecoration(
                      context,
                      hintText: l10n.composerValueHint,
                    ),
                    onChanged: (value) => rows[i].value = value,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => onRemove(i),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add_rounded),
            label: Text(addLabel),
            onPressed: onAdd,
          ),
        ),
      ],
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.controller});

  final HttpComposerController controller;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: controller.isSending ? null : controller.send,
        icon: controller.isSending
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.send_rounded),
        label: Text(context.ispectL10n.composerSend),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          shape: ISpectSquircle.border(),
        ),
      );
}

class _ValidationText extends StatelessWidget {
  const _ValidationText({required this.error});

  final ComposerValidation error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.ispectL10n;
    final color = context.appTheme.colorScheme.error;
    final message = switch (error) {
      ComposerValidation.urlRequired => l10n.composerErrorUrlRequired,
      ComposerValidation.urlInvalid => l10n.composerErrorUrlInvalid,
      ComposerValidation.jsonInvalid => l10n.composerErrorInvalidJson,
      ComposerValidation.noClient => l10n.composerErrorNoClient,
    };
    return Row(
      children: [
        Icon(Icons.error_outline_rounded, size: 18, color: color),
        const Gap(8),
        Expanded(child: Text(message, style: TextStyle(color: color))),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.result,
    this.previewMaxLines = _kInlinePreviewMaxLines,
  });

  final NetworkReplayResult result;
  final int previewMaxLines;

  @override
  Widget build(BuildContext context) {
    final l10n = context.ispectL10n;
    final status = result.statusCode;
    final jsonData = _jsonViewerData(result);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              _SectionTitle(l10n.composerResponse),
              const Spacer(),
              _StatusChip(status: status),
              if (result.durationMs != null) ...[
                const Gap(8),
                Text(
                  '${result.durationMs} ms',
                  style: TextStyle(
                    color: context.appTheme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (jsonData != null)
          _JsonResultCard(
            data: jsonData,
            preview: _pretty(result.body),
            maxLines: previewMaxLines,
          )
        else
          ISpectBorderedSurface(
            backgroundColor: context.ispectCardColor,
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              result.isError && status == null
                  ? result.error.toString()
                  : _pretty(result.body),
              style: ISpectInputStyle.textStyle(context),
            ),
          ),
      ],
    );
  }

  static Map<String, dynamic>? _jsonViewerData(NetworkReplayResult result) {
    if (result.isError && result.statusCode == null) return null;
    final body = result.body;
    if (body is Map) return Map<String, dynamic>.from(body);
    if (body is List) return {'content': body};
    return null;
  }

  static String _pretty(Object? body) {
    if (body == null) return '';
    if (body is Map || body is List) {
      return const JsonEncoder.withIndent('  ').convert(body);
    }
    return body.toString();
  }
}

class _JsonResultCard extends StatelessWidget {
  const _JsonResultCard({
    required this.data,
    required this.preview,
    required this.maxLines,
  });

  final Map<String, dynamic> data;
  final String preview;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final primary = context.ispectPrimaryColor;
    return ISpectBorderedSurface(
      onTap: () => JsonScreen(data: data).push(context),
      backgroundColor: context.ispectCardColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preview,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: ISpectInputStyle.textStyle(context),
          ),
          const Gap(10),
          Row(
            children: [
              Icon(Icons.data_object_rounded, size: 16, color: primary),
              const Gap(6),
              Text(
                context.ispectL10n.composerViewJson,
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, size: 18, color: primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final int? status;

  @override
  Widget build(BuildContext context) {
    final isError = status == null;
    final color = isError
        ? context.appTheme.colorScheme.error
        : JsonColors.statusColor(status);
    return DecoratedBox(
      decoration: ISpectSquircle.decoration(
        color: color.withValues(alpha: 0.12),
        radius: ISpectConstants.standardBorderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          isError ? 'ERR' : '$status',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: (context.appTheme.textTheme.titleSmall ?? const TextStyle())
            .copyWith(fontWeight: FontWeight.w600),
      );
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final muted = context.appTheme.colorScheme.onSurface.withValues(alpha: 0.5);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: muted),
            const Gap(12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
