class ISpectifyDateTimeFormatter {
  const ISpectifyDateTimeFormatter(this.date);

  final DateTime? date;

  String get timeAndSeconds {
    if (date == null) return '';

    final hoursPadded = '${date!.hour}'.padLeft(2, '0');
    final minutesPadded = '${date!.minute}'.padLeft(2, '0');
    final secondsPadded = '${date!.second}'.padLeft(2, '0');

    return '$hoursPadded:$minutesPadded:$secondsPadded | ${date!.millisecond}ms';
  }

  String get fullTime {
    if (date == null) return '';

    final monthPadded = '${date!.month}'.padLeft(2, '0');
    final dayPadded = '${date!.day}'.padLeft(2, '0');

    return '$dayPadded.$monthPadded.${date?.year} | $timeAndSeconds';
  }

  String get format {
    if (date == null) return '';

    return fullTime;
  }
}
