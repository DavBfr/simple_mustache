// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implicit_dynamic_map_literal

import 'package:simple_mustache/simple_mustache.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {});

  group('Basic', () {
    test('Variable', () {
      final output =
          Mustache(map: <String, dynamic>{'var': 'bob'}).convert('_{{var}}_');
      expect(output, equals('_bob_'));
    });

    test('Comment', () {
      final output =
          Mustache(map: <String, dynamic>{}).convert('_{{! i am a comment }}_');
      expect(output, equals('__'));
    });
  });

  group('Section', () {
    test('Map', () {
      final output = Mustache(map: <String, dynamic>{
        'section': {'var': 'bob'}
      }).convert('{{#section}}_{{var}}_{{/section}}');
      expect(output, equals('_bob_'));
    });

    test('List', () {
      final output = Mustache(map: <String, dynamic>{
        'section': [
          {'var': 'bob'},
          {'var': 'jim'}
        ]
      }).convert('{{#section}}_{{var}}_{{/section}}');
      expect(output, equals('_bob__jim_'));
    });

    test('Empty List', () {
      final output = Mustache(map: <String, dynamic>{'section': <dynamic>[]})
          .convert('{{#section}}_{{var}}_{{/section}}');
      expect(output, equals(''));
    });
    test('False', () {
      final output = Mustache(map: <String, dynamic>{'section': false})
          .convert('{{#section}}_{{var}}_{{/section}}');
      expect(output, equals(''));
    });
    test('Invalid value', () {
      final output = Mustache(map: <String, dynamic>{'section': 42, 'var': 21})
          .convert('{{#section}}_{{var}}_{{/section}}');
      expect(output, equals('_21_'));
    });

    test('True', () {
      final output = Mustache(map: <String, dynamic>{'section': true})
          .convert('{{#section}}_ok_{{/section}}');
      expect(output, equals('_ok_'));
    });
  });

  group('Filters', () {
    test('simple filter', () {
      final output = Mustache(
        map: <String, dynamic>{
          'nine_eleven': 1000212400000,
        },
        filters: {
          'date': (dynamic val) =>
              DateTime.fromMillisecondsSinceEpoch(val).toUtc()
        },
      ).convert('{{  nine_eleven|date }}');
      expect(output, equals('2001-09-11 12:46:40.000Z'));
    });

    test('Multiple filters', () {
      final output = Mustache(
        map: <String, dynamic>{
          'nine_eleven': 1000212400,
        },
        filters: {
          'ms': (dynamic val) => val * 1000,
          'date': (dynamic val) =>
              DateTime.fromMillisecondsSinceEpoch(val).toUtc()
        },
      ).convert('{{  nine_eleven|ms|date }}');
      expect(output, equals('2001-09-11 12:46:40.000Z'));
    });

    test('Undefined filter', () {
      final output = Mustache(
        map: <String, dynamic>{'val': 42},
        // filters: {},
      ).convert('{{ val|date }}');
      expect(output, equals('42'));
    });
  });

  group('Recovery', () {
    test('Undefined value', () {
      final output = Mustache(
        map: <String, dynamic>{'val': 42},
      ).convert('{{ val }} {{ vvv }}');
      expect(output, equals('42 vvv'));
    });

    test('Undefined value callback', () {
      final output = Mustache(
        map: <String, dynamic>{'val': 42},
        replace: (key) => '~',
      ).convert('{{ val }} {{ vvv }}');
      expect(output, equals('42 ~'));
    });
  });
}
