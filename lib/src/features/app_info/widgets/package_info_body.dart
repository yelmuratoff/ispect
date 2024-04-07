part of '../app.dart';

class PackageInfoBody extends StatelessWidget {
  const PackageInfoBody({
    super.key,
    this.packageInfo,
  });

  final PackageInfo? packageInfo;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Package info',
              style: context.ispectTheme.textTheme.bodyMedium?.copyWith(
                color: context.ispectTheme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: _PackageInfoBody(
                packageInfo: packageInfo,
              ),
            ),
          ),
        ],
      );
}

class _PackageInfoBody extends StatelessWidget {
  const _PackageInfoBody({
    required PackageInfo? packageInfo,
  }) : _packageInfo = packageInfo;

  final PackageInfo? _packageInfo;

  @override
  Widget build(BuildContext context) {
    if (_packageInfo == null) {
      return const SizedBox();
    }
    final pi = _packageInfo;
    return pi != null
        ? Column(
            children: [
              KeyValueLine(
                k: 'App name:',
                v: pi.appName,
              ),
              KeyValueLine(
                k: 'Version:',
                v: pi.version,
              ),
              KeyValueLine(
                k: 'Build number:',
                v: pi.buildNumber,
              ),
              KeyValueLine(
                k: 'Package name:',
                v: pi.packageName,
              ),
            ],
          )
        : const SizedBox();
  }
}
