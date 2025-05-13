part of '../app_info_screen.dart';

class DeviceInfoBody extends StatelessWidget {
  const DeviceInfoBody({
    super.key,
    this.data,
  });

  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Device info',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Column(
              children: data?.entries
                      .map(
                        (e) => KeyValueLine(
                          k: e.key,
                          v: e.value.toString(),
                        ),
                      )
                      .toList() ??
                  [],
            ),
          ),
        ],
      );
}
