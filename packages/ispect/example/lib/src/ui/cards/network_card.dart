import 'package:flutter/material.dart';

class NetworkCard extends StatelessWidget {
  final bool enableHttp;
  final bool httpSendSuccess;
  final bool httpSendErrors;
  final bool enableWs;
  final bool enableFileUploads;
  final ValueChanged<bool> onEnableHttpChanged;
  final ValueChanged<bool> onHttpSendSuccessChanged;
  final ValueChanged<bool> onHttpSendErrorsChanged;
  final ValueChanged<bool> onEnableWsChanged;
  final ValueChanged<bool> onEnableFileUploadsChanged;

  const NetworkCard({
    super.key,
    required this.enableHttp,
    required this.httpSendSuccess,
    required this.httpSendErrors,
    required this.enableWs,
    required this.enableFileUploads,
    required this.onEnableHttpChanged,
    required this.onHttpSendSuccessChanged,
    required this.onHttpSendErrorsChanged,
    required this.onEnableWsChanged,
    required this.onEnableFileUploadsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionGroup(
      title: 'Network',
      icon: Icons.wifi,
      children: [
        _checkbox('HTTP Requests', enableHttp, onEnableHttpChanged),
        _checkbox('HTTP Success', httpSendSuccess, onHttpSendSuccessChanged),
        _checkbox('HTTP Errors', httpSendErrors, onHttpSendErrorsChanged),
        _checkbox('WebSocket', enableWs, onEnableWsChanged),
        _checkbox(
            'File Uploads', enableFileUploads, onEnableFileUploadsChanged),
      ],
    );
  }

  Widget _checkbox(String label, bool value, ValueChanged<bool> onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

class _ActionGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _ActionGroup(
      {required this.title, required this.icon, required this.children});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
