class ISpectifyDateTimeFormatter {
  const ISpectifyDateTimeFormatter(this.date);

  final DateTime? date;

  String get timeAndSeconds {
    if (date == null) return '';

    final minutesPadded = '${date!.minute}'.padLeft(2, '0');
    final secondsPadded = '${date!.second}'.padLeft(2, '0');

    return '${date!.hour}:$minutesPadded:$secondsPadded | ${date!.millisecond}ms';
  }

  String get yearMonthDayAndTime {
    if (date == null) return '';

    return '${date!.year}-${date!.month}-${date!.day} | $timeAndSeconds';
  }

  String get format {
    if (date == null) return '';

    return yearMonthDayAndTime;
  }
}
