// ignore_for_file: avoid_print
/// A script for maintaining assets.
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_style/dart_style.dart';
import 'package:ziggurat_sounds/ziggurat_sounds.dart';

/// Dump the asset store [store] as Dart code.
void assetStoreToDart(AssetStore store) {
  final buffer = StringBuffer()
    ..writeln('/// Automatically generated. Do not edit by hand.');
  if (store.comment != null) {
    buffer.writeln('/// ${store.comment}');
  }
  if (store.assets.isNotEmpty) {
    buffer.writeln("import 'package:ziggurat/ziggurat.dart';");
  }
  for (final reference in store.assets) {
    if (reference.comment != null) {
      buffer.writeln('/// ${reference.comment}');
    }
    buffer.writeln('final ${reference.variableName} = AssetReference('
        "'${reference.reference.name.replaceAll(r'\', '/')}', "
        '${reference.reference.type}, '
        "encryptionKey: '${reference.reference.encryptionKey}');");
  }
  final formatter = DartFormatter();
  final code = formatter.format(buffer.toString());
  File(store.filename).writeAsStringSync(code);
}

/// A command for creating a new assets file.
class CreateCommand extends Command<void> {
  /// Create the command.
  CreateCommand() {
    argParser
      ..addOption('comment',
          abbr: 'c',
          help: 'The comment to go at the top of the resulting Dart file');
  }
  @override
  String get description => 'Create a new assets store.';

  @override
  String get name => 'create';

  @override
  void run() {
    final results = argResults!;
    final rest = results.rest;
    if (rest.length != 2) {
      return print(
          'Usage: ${runner?.executableName} <json-filename> <dart-filename>');
    }
    final jsonFile = File(rest.first);
    final dartFilename = rest.last;
    final comment = results['comment'] as String?;
    final store = AssetStore(dartFilename, comment: comment)..dump(jsonFile);
    print('Created asset store at ${jsonFile.path}.');
    assetStoreToDart(store);
    print('Created dart file ${store.filename}.');
  }
}

/// A command for adding files to an [AssetStore].
class FileCommand extends Command<void> {
  /// Create the command.
  FileCommand() {
    argParser
      ..addOption('variable',
          abbr: 'v', mandatory: true, help: 'The variable name to use.')
      ..addOption('source',
          abbr: 's', mandatory: true, help: 'The source file to import.')
      ..addOption('destination',
          abbr: 'd',
          mandatory: true,
          help: 'The destination directory for the encrypted file.')
      ..addOption('comment',
          abbr: 'c', help: 'The comment to show above the reference.');
  }

  @override
  String get description => 'Add a file.';

  @override
  String get name => 'file';

  @override
  void run() {
    final results = argResults!;
    final rest = results.rest;
    if (rest.length != 1) {
      return print('Usage: ${runner?.executableName} <json-file>');
    }
    final jsonFile = File(rest.first);
    if (jsonFile.existsSync() == false) {
      return print('Error: Json file ${jsonFile.path} does not exist.');
    }
    final source = File(results['source'] as String);
    final destination = Directory(results['destination'] as String);
    final variableName = results['variable'] as String;
    if (source.existsSync() == false) {
      return print('Error: Source file ${source.path} does not exist.');
    }
    if (destination.existsSync() == false) {
      return print(
          'Error: Destination directory ${destination.path} does not exist.');
    }
    final store = AssetStore.fromFile(jsonFile);
    for (final asset in store.assets) {
      if (asset.variableName == variableName) {
        return print('Error: There is already a variable named $variableName.');
      }
    }
    store
      ..importFile(
          file: source,
          directory: destination,
          variableName: variableName,
          comment: results['comment'] as String?)
      ..dump(jsonFile);
    assetStoreToDart(store);
    print('Done.');
  }
}

/// A command for adding directories to an [AssetStore].
class DirectoryCommand extends Command<void> {
  /// Create the command.
  DirectoryCommand() {
    argParser
      ..addOption('variable',
          abbr: 'v', mandatory: true, help: 'The variable name to use.')
      ..addOption('source',
          abbr: 's', mandatory: true, help: 'The source directory to import.')
      ..addOption('destination',
          abbr: 'd',
          mandatory: true,
          help: 'The destination directory for the encrypted files.')
      ..addOption('comment',
          abbr: 'c', help: 'The comment to show above the reference.');
  }

  @override
  String get description => 'Add a directory.';

  @override
  String get name => 'directory';

  @override
  void run() {
    final results = argResults!;
    final rest = results.rest;
    if (rest.length != 1) {
      return print('Usage: ${runner?.executableName} <json-file>');
    }
    final jsonFile = File(rest.first);
    if (jsonFile.existsSync() == false) {
      return print('Error: Json file ${jsonFile.path} does not exist.');
    }
    final source = Directory(results['source'] as String);
    final destination = Directory(results['destination'] as String);
    final variableName = results['variable'] as String;
    if (source.existsSync() == false) {
      return print('Error: Source file ${source.path} does not exist.');
    }
    if (destination.existsSync() == false) {
      return print(
          'Error: Destination directory ${destination.path} does not exist.');
    }
    final store = AssetStore.fromFile(jsonFile);
    for (final asset in store.assets) {
      if (asset.variableName == variableName) {
        return print('Error: There is already a variable named $variableName.');
      }
    }
    store
      ..importDirectory(
          directory: source,
          destination: destination,
          variableName: variableName,
          comment: results['comment'] as String?)
      ..dump(jsonFile);
    assetStoreToDart(store);
    print('Done.');
  }
}

/// A command to regenerate Dart code.
class RegenerateCommand extends Command<void> {
  @override
  String get description => 'Regenerate Dart code.';

  @override
  String get name => 'regenerate';

  @override
  void run() {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      return print('Usage: ${runner?.executableName} <json-filename>');
    }
    final file = File(rest.first);
    final store = AssetStore.fromFile(file);
    assetStoreToDart(store);
    print('Done.');
  }
}

Future<void> main(List<String> args) async {
  final command = CommandRunner<void>(
      'assets',
      'Create and edit asset stores.\n\n'
          'You must first create an asset store with the `create` command:\n'
          '  `assets create assets.json bin/assets.dart -c "Assets for the game."`')
    ..addCommand(CreateCommand())
    ..addCommand(FileCommand())
    ..addCommand(DirectoryCommand())
    ..addCommand(RegenerateCommand());
  try {
    await command.run(args);
  } on UsageException catch (e) {
    print(e);
  }
}
