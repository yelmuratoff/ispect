import 'package:ispectify/ispectify.dart';

class GoodLog extends ISpectLogData {
  GoodLog(
    String super.message, {
    String? title,
  }) : super(
          key: ISpectLogType.good.key,
          title: title ?? ISpectLogType.good.key,
        );
}

class AnalyticsLog extends ISpectLogData {
  AnalyticsLog(
    String super.message, {
    String? analytics,
    String? title,
  }) : super(
          key: ISpectLogType.analytics.key,
          title: analytics ?? title ?? ISpectLogType.analytics.key,
        );
}

class RouteLog extends ISpectLogData {
  RouteLog(
    String super.message, {
    this.transitionId,
    String? title,
  }) : super(
          key: ISpectLogType.route.key,
          title: title ?? ISpectLogType.route.key,
          additionalData: transitionId != null
              ? <String, dynamic>{
                  TraceKeys.correlationId: transitionId,
                  TraceKeys.category: TraceCategoryIds.navigation,
                }
              : <String, dynamic>{
                  TraceKeys.category: TraceCategoryIds.navigation,
                },
        );

  final String? transitionId;
}

class ProviderLog extends ISpectLogData {
  ProviderLog(
    String super.message, {
    String? title,
  }) : super(
          key: ISpectLogType.provider.key,
          title: title ?? ISpectLogType.provider.key,
        );
}

class PrintLog extends ISpectLogData {
  PrintLog(
    String super.message, {
    String? title,
  }) : super(
          key: ISpectLogType.print.key,
          title: title ?? ISpectLogType.print.key,
        );
}
