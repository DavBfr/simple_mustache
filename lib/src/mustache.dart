// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// implements a part of the specification: https://mustache.github.io/mustache.5.html

import 'dart:convert';

/// The filter to apply to a variable
typedef MustacheFilter = dynamic Function(dynamic value);

/// Mustache-like converter
///
/// given a string like:
/// ```dart
/// var s = 'Hello {{ name }}, how are you?';
/// ```
/// this class can replace `{{ name }}` with the corresponding value
/// in the map:
/// ```dart
/// var m = Mustache({'name': 'David'});
/// m.convert(s);
/// ```
/// will return `Hello David, how are you?`
class Mustache extends Converter<String, String> {
  /// Create a [Mustache] instance that can replace strings
  /// according to [map] and [filters]
  Mustache({
    this.map = const <String, dynamic>{},
    this.filters = const <String, MustacheFilter>{},
    this.debug = false,
  })  : assert(map != null),
        assert(filters != null),
        assert(debug != null);

  /// Variable replacement map
  /// used to replace `{{ key }}` with the corresponding `value`
  final Map<String, dynamic> map;

  /// Filters to apply to the map
  /// used to apply filters. This string `{{ key | date }}` will be replaced
  /// with `filters['date'](value)`
  final Map<String, MustacheFilter> filters;

  /// Wether or not to display debug information instead of
  /// the actual replacement
  final bool debug;

  final _mustache =
      RegExp(r'({{\s*([#/^!]?) *([\w\d_]*)\s*\|?\s*([\w\d\s_\|]*)}})');

  final _filter = RegExp(r'([\w\d_]+)\s*\|?\s*');

  dynamic _applyFilters(dynamic value, List<String> _filters) {
    if (_filters.isEmpty) {
      return value;
    }

    for (final filter in _filters) {
      assert(filters.containsKey(filter), 'filter $filter not found');
      value = filters[filter](value);
      assert(() {
        if (debug) {
          value = '$filter($value)';
        }
        return true;
      }());
    }

    return value;
  }

  @override
  String convert(String input) {
    final output = StringBuffer();
    var start = 0;
    var eat = false;
    var eatField = '';
    final context = <String, dynamic>{};
    var inputLoop = 0;
    var array = <dynamic>[];
    final _map = <String, dynamic>{};
    _map.addAll(map);

    while (true) {
      final me = _mustache.allMatches(input, start);
      if (me.isEmpty) {
        break;
      }
      final m = me.first;

      final modifier = m.group(2);
      final field = m.group(3);
      final _filters = <String>[];

      if (m.group(4).isNotEmpty) {
        for (final n in _filter.allMatches(m.group(4))) {
          _filters.add(n.group(1));
        }
      }

      // comment tag
      if (modifier == '!') {
        output.write(input.substring(start, m.start));
        start = m.end;
        continue;
      }

      // end tag
      if (modifier == '/') {
        if (!eat) {
          output.write(input.substring(start, m.start));
          if (array.isNotEmpty) {
            start = inputLoop;
            _map.clear();
            _map.addAll(context);
            _map.addAll(array.first);
            array.removeAt(0);
            continue;
          }
          _map.clear();
          _map.addAll(context);
        }
        if (eatField == field) {
          eat = false;
          eatField = '';
        }

        start = m.end;
        continue;
      }

      if (eat) {
        start = m.end;
        continue;
      }

      // start tag
      if (modifier == '#') {
        output.write(input.substring(start, m.start));
        if (_map.containsKey(field)) {
          dynamic value = _map[field];
          if (value is bool) {
            eat = !value;
          } else {
            eat = false;
          }
          if (value is Map) {
            value = <dynamic>[value];
          }
          if (value is List) {
            if (value.isEmpty) {
              eat = true;
              eatField = field;
              start = m.end;
              continue;
            }
            context.clear();
            context.addAll(_map);
            array = <dynamic>[...value];
            _map.clear();
            _map.addAll(context);
            _map.addAll(array.first);
            array.removeAt(0);
            inputLoop = m.end;
          }
        } else {
          eat = true;
        }
        eatField = field;
        start = m.end;
        continue;
      }

      // inverted start tag
      if (modifier == '^') {
        output.write(input.substring(start, m.start));
        if (_map.containsKey(field)) {
          final dynamic value = _map[field];
          if (value is bool) {
            eat = value;
          } else {
            eat = true;
          }
        }
        eatField = field;
        start = m.end;
        continue;
      }

      assert(_map.containsKey(field), 'field $field not found');
      output.write(input.substring(start, m.start));
      dynamic value = _applyFilters(_map[field], _filters);
      assert(() {
        if (debug) {
          value = '[$field]($value)';
        }
        return true;
      }());
      output.write(value);
      start = m.end;
    }

    output.write(input.substring(start));
    return output.toString();
  }
}
