

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
            ISpectifyActionItem(
            onTap: (_) async {
              await Navigator.push(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (_) => AppDataPage(
                    iSpectify: widget.iSpectify,
                  ),
                  settings: RouteSettings(
                    name: 'AppDataPage',
                    arguments: {
                      'iSpectify': widget.iSpectify,
                    },
                  ),
                ),
              );
            },
            title: context.ispectL10n.viewAndManageData,
            icon: Icons.data_usage_sharp,
          ),
```
