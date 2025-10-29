import 'package:ispectify/ispectify.dart';

/// `GoodLog` - This class contains the basic structure of the log.
class GoodLog extends ISpectLogData {
  GoodLog(
    String super.message,
  ) : super(
          key: ISpectLogType.good.key,
          title: ISpectLogType.good.key,
        );
}

/// `AnalyticsLog` - This class contains the analytics log.
class AnalyticsLog extends ISpectLogData {
  AnalyticsLog(
    String super.message, {
    String? analytics,
  }) : super(
          key: ISpectLogType.analytics.key,
          title: analytics ?? ISpectLogType.analytics.key,
        );
}

/// `RouteLog` - This class contains the route log.
class RouteLog extends ISpectLogData {
  RouteLog(
    String super.message, {
    this.transitionId,
  }) : super(
          key: ISpectLogType.route.key,
          title: ISpectLogType.route.key,
        );

  final String? transitionId;
}

/// `ProviderLog` - This class contains the provider log.
class ProviderLog extends ISpectLogData {
  ProviderLog(
    String super.message,
  ) : super(
          key: ISpectLogType.provider.key,
          title: ISpectLogType.provider.key,
        );
}

/// `PrintLog` - This class contains the print log.
class PrintLog extends ISpectLogData {
  PrintLog(String super.message)
      : super(
          key: ISpectLogType.print.key,
          title: ISpectLogType.print.key,
        );
}
