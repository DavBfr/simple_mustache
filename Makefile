# Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
# All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

FLUTTER?=$(realpath $(dir $(realpath $(dir $(shell which flutter)))))
FLUTTER_BIN=$(FLUTTER)/bin/flutter
DART_BIN=$(FLUTTER)/bin/dart
DART_SRC=$(shell find . -name '*.dart')

all: format pubspec.lock

format: format-dart

format-dart: $(DART_SRC)
	dart format --fix $^

clean:
	git clean -fdx -e .vscode

node_modules:
	npm install lcov-summary

pubspec.lock: pubspec.yaml
	$(DART_BIN) pub get

test: node_modules pubspec.lock
	dart test --coverage=.coverage
	$(DART_BIN) pub global run coverage:format_coverage --packages=.packages -i .coverage --report-on lib --lcov --out lcov.info
	cat lcov.info | node_modules/.bin/lcov-summary

publish: format analyze clean
	test -z "$(shell git status --porcelain)"
	find . -name pubspec.yaml -exec sed -i -e 's/^dependency_overrides:/_dependency_overrides:/g' '{}' ';'
	$(DART_BIN) pub publish -f
	find . -name pubspec.yaml -exec sed -i -e 's/^_dependency_overrides:/dependency_overrides:/g' '{}' ';'
	git tag $(shell grep version pubspec.yaml | sed 's/version\s*:\s*/v/g')

.pana:
	$(DART_BIN) pub global activate pana
	touch $@

fix: $(DART_SRC)
	$(DART_BIN) fix

analyze: .pana
	$(DART_BIN) pub global run pana --no-warning --source path .

.PHONY: format format-dart clean publish test fix analyze
