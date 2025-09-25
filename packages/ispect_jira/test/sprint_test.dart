import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_jira/src/jira/models/sprint.dart';

void main() {
  group('JiraSprint', () {
    test('should parse sprint with camelCase date keys', () {
      final map = {
        'id': 1,
        'self': 'https://example.atlassian.net/rest/agile/1.0/sprint/1',
        'name': 'Sprint 1',
        'startDate': '2023-01-01T00:00:00.000Z',
        'endDate': '2023-01-15T23:59:59.999Z',
        'state': 'active',
        'goal': 'Complete user stories',
      };

      final sprint = JiraSprint.fromMap(map);

      expect(sprint.id, 1);
      expect(sprint.name, 'Sprint 1');
      expect(sprint.startDate, DateTime.parse('2023-01-01T00:00:00.000Z'));
      expect(sprint.endDate, DateTime.parse('2023-01-15T23:59:59.999Z'));
      expect(sprint.state, 'active');
      expect(sprint.goal, 'Complete user stories');
    });

    test('should parse sprint with snake_case date keys', () {
      final map = {
        'id': 2,
        'self': 'https://example.atlassian.net/rest/agile/1.0/sprint/2',
        'name': 'Sprint 2',
        'start_date': '2023-02-01T00:00:00.000Z',
        'end_date': '2023-02-15T23:59:59.999Z',
        'state': 'closed',
        'goal': 'Bug fixes',
      };

      final sprint = JiraSprint.fromMap(map);

      expect(sprint.id, 2);
      expect(sprint.name, 'Sprint 2');
      expect(sprint.startDate, DateTime.parse('2023-02-01T00:00:00.000Z'));
      expect(sprint.endDate, DateTime.parse('2023-02-15T23:59:59.999Z'));
      expect(sprint.state, 'closed');
      expect(sprint.goal, 'Bug fixes');
    });

    test('should parse sprint with null dates', () {
      final map = {
        'id': 3,
        'self': 'https://example.atlassian.net/rest/agile/1.0/sprint/3',
        'name': 'Sprint 3',
        'state': 'future',
        'goal': 'New features',
      };

      final sprint = JiraSprint.fromMap(map);

      expect(sprint.id, 3);
      expect(sprint.name, 'Sprint 3');
      expect(sprint.startDate, isNull);
      expect(sprint.endDate, isNull);
      expect(sprint.state, 'future');
      expect(sprint.goal, 'New features');
    });

    test('should prefer camelCase over snake_case when both are present', () {
      final map = {
        'id': 4,
        'self': 'https://example.atlassian.net/rest/agile/1.0/sprint/4',
        'name': 'Sprint 4',
        'startDate': '2023-03-01T00:00:00.000Z', // camelCase
        'start_date':
            '2023-03-02T00:00:00.000Z', // snake_case (should be ignored)
        'endDate': '2023-03-15T23:59:59.999Z', // camelCase
        'end_date':
            '2023-03-16T23:59:59.999Z', // snake_case (should be ignored)
        'state': 'active',
        'goal': 'Mixed case test',
      };

      final sprint = JiraSprint.fromMap(map);

      expect(sprint.startDate, DateTime.parse('2023-03-01T00:00:00.000Z'));
      expect(sprint.endDate, DateTime.parse('2023-03-15T23:59:59.999Z'));
    });

    test('should serialize to map with camelCase date keys', () {
      final sprint = JiraSprint(
        id: 1,
        self: 'https://example.atlassian.net/rest/agile/1.0/sprint/1',
        name: 'Sprint 1',
        startDate: DateTime.parse('2023-01-01T00:00:00.000Z'),
        endDate: DateTime.parse('2023-01-15T23:59:59.999Z'),
        state: 'active',
        goal: 'Complete user stories',
      );

      final map = sprint.toMap();

      expect(map['id'], 1);
      expect(map['name'], 'Sprint 1');
      expect(map['startDate'], '2023-01-01T00:00:00.000Z');
      expect(map['endDate'], '2023-01-15T23:59:59.999Z');
      expect(map['state'], 'active');
      expect(map['goal'], 'Complete user stories');
    });
  });
}
