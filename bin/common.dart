/// Provides utility functions.
import 'dart:io';

import 'package:dart_style/dart_style.dart';

/// Get a string of text.
///
/// If the user enters nothing, then [defaultValue] will be used.
String getText({
  required final String message,
  final String defaultValue = '',
}) {
  stdout.write('$message ($defaultValue)');
  final result = stdin.readLineSync() ?? defaultValue;
  if (result.isEmpty) {
    return defaultValue;
  }
  return result;
}

/// Get a JSON filename.
File getJsonFile() => File(
      getText(
        message: 'JSON filename:',
        defaultValue: 'assets.json',
      ),
    );

/// Get a variable name.
String getVariableName() => getText(message: 'Variable name:');

/// Returns `true` if the given [variableName] is valid dart.
bool validVariableName(final String variableName) {
  final code = 'const int $variableName = 5;';
  final formatter = DartFormatter();
  try {
    formatter.format(code);
    return true;
  } on FormatterException {
    // ignore: avoid_print
    print('Invalid variable name: $variableName.');
    return false;
  }
}

/// Return a comment.
String getComment() => getText(message: 'Asset comment:');

/// Return `true` if the given [file] is valid.
bool validFile(
  final File file, {
  final String? message,
}) {
  if (file.existsSync()) {
    return true;
  }
  // ignore: avoid_print
  print(message ?? 'Error: file ${file.path} does not exist.');
  return false;
}

/// Make a variable name from the given [name].
String makeVariableName(final String name) {
  final words = name.split('_');
  final buffer = StringBuffer();
  for (var i = 0; i < words.length; i++) {
    final word = words[i];
    if (i == 0) {
      buffer.write(word);
    } else {
      buffer
        ..write(word.substring(0, 1).toUpperCase())
        ..write(word.substring(1).toLowerCase());
    }
  }
  return buffer.toString();
}
