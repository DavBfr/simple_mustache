import 'package:simple_mustache/simple_mustache.dart';

void main() {
  // Create a mustache converter
  final m = Mustache(
    map: <String, dynamic>{
      'name': 'David',
    },
  );

  // Convert a template
  final output = m.convert('Hello, my name is {{ name }}.');
  print(output);

  // Create a more complicated mustache converter
  final m1 = Mustache(
    map: <String, dynamic>{
      'events': <Map>[
        <String, dynamic>{
          'name': 'Event 1',
          'date': DateTime.fromMillisecondsSinceEpoch(-1893200147000),
        },
        <String, dynamic>{
          'name': 'Event 2',
          'date': DateTime.fromMillisecondsSinceEpoch(1893200147000),
        },
      ],
    },
    filters: {
      'dt': (dynamic d) => d is DateTime ? d.year : 'Invalid data',
    },
  );

  // Convert a template
  print(m1.convert(
      'List of events:\n{{# events }}  {{ name }}, year: {{ date | dt }}\n{{/ events }}'));
}
