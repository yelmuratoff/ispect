import 'package:ispectify/ispectify.dart';

/// `GoodLog` - This class contains the basic structure of the log.
class GoodLog extends ISpectifyData {
  GoodLog(
    String super.message,
  ) : super(
          key: ISpectifyLogType.good.key,
          title: ISpectifyLogType.good.key,
        );
}

/// `AnalyticsLog` - This class contains the analytics log.
class AnalyticsLog extends ISpectifyData {
  AnalyticsLog(
    String super.message, {
    String? analytics,
  }) : super(
          key: ISpectifyLogType.analytics.key,
          title: analytics ?? ISpectifyLogType.analytics.key,
        );
}

/// `RouteLog` - This class contains the route log.
class RouteLog extends ISpectifyData {
  RouteLog(
    String super.message, {
    this.transitionId,
  }) : super(
          key: ISpectifyLogType.route.key,
          title: ISpectifyLogType.route.key,
        );

  final int? transitionId;
}

/// `ProviderLog` - This class contains the provider log.
class ProviderLog extends ISpectifyData {
  ProviderLog(
    String super.message,
  ) : super(
          key: ISpectifyLogType.provider.key,
          title: ISpectifyLogType.provider.key,
        );
}

/// `PrintLog` - This class contains the print log.
class PrintLog extends ISpectifyData {
  PrintLog(String super.message)
      : super(
          key: ISpectifyLogType.print.key,
          title: ISpectifyLogType.print.key,
        );
}
