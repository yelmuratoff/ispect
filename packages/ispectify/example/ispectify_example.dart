import 'dart:convert';

import 'package:ansicolor/ansicolor.dart';
import 'package:ispectify/src/enums/log_level.dart';
import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/models/log_data.dart';

void main() {
  final logger = Logger(name: 'ispectify');

  logger.success('Success message');
  logger.info('Info message');
  logger.warning('Warning message');
  logger.error('Error message');
  logger.critical('Critical message');
  logger.debug('Debug message');
  logger.log('Log message');
  logger.log(
    'Event message',
    data: LogData(
      key: 'analytics',
      title: 'Amplitude',
      pen: AnsiPen()..xterm(226),
      level: LogLevel.info,
    ),
  );

  const encoder = JsonEncoder.withIndent('  ');
  final prettyData = encoder.convert(
    {
      "id": 12345,
      "name": "John Doe",
      "email": "john.doe@example.com",
      "isVerified": true,
      "roles": ["admin", "editor"],
      "profile": {
        "age": 29,
        "location": {"city": "San Francisco", "state": "CA", "country": "USA"},
        "preferences": {"theme": "dark", "notifications": true, "language": "en-US"}
      },
      "lastLogin": "2024-12-23T15:45:00Z",
      "purchaseHistory": [
        {"orderId": 98765, "product": "Laptop", "price": 1200.99, "date": "2024-11-20"},
        {"orderId": 87654, "product": "Smartphone", "price": 799.49, "date": "2024-10-15"}
      ]
    },
  );
  logger.log(
    prettyData,
    data: LogData(
      key: 'json',
      title: 'JSON Data',
      pen: AnsiPen()..xterm(226),
      level: LogLevel.info,
    ),
  );
}
