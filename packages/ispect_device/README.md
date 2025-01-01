

```dart
          ISpectifyActionItem(
            onTap: (_) async {
              await Navigator.push(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (_) => AppInfoPage(
                    iSpectify: widget.iSpectify,
                  ),
                  settings: RouteSettings(
                    name: 'AppInfoPage',
                    arguments: {
                      'iSpectify': widget.iSpectify,
                    },
                  ),
                ),
              );
            },
            title: 'App Info',
            icon: Icons.info_outline_rounded,
          ),
```