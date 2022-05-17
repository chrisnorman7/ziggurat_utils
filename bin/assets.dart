// ignore_for_file: avoid_print
/// A script for maintaining assets.
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_style/dart_style.dart';
import 'package:ziggurat/ziggurat.dart' show AssetType;
import 'package:ziggurat_sounds/ziggurat_sounds.dart';

/// Dump the asset store [store] as Dart code.
void assetStoreToDart(final AssetStore store) {
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
    buffer.writeln('const ${reference.variableName} = AssetReference('
        "'${reference.reference.name.replaceAll(r'\', '/')}', "
        '${reference.reference.type}, '
        "encryptionKey: '${reference.reference.encryptionKey}',);");
  }
  final formatter = DartFormatter();
  final code = formatter.format(buffer.toString());
  File(store.filename).writeAsStringSync(code);
}

/// A command for creating a new assets file.
class CreateCommand extends Command<void> {
  /// Create the command.
  CreateCommand() {
    argParser.addOption(
      'comment',
      abbr: 'c',
      help: 'The comment to go at the top of the resulting Dart file',
    );
  }
  @override
  String get description => 'Create a new assets store.';

  @override
  String get name => 'create';

  @override
  void run() {
    final results = argResults!;
    final rest = results.rest;
    if (rest.length != 3) {
      return print('Usage: ${runner?.executableName} <json-filename> '
          '<dart-filename> <destination-directory>');
    }
    final jsonFile = File(rest.first);
    final dartFilename = rest[1];
    final destination = rest.last;
    final comment = results['comment'] as String?;
    final store = AssetStore(
      filename: dartFilename,
      destination: destination,
      assets: [],
      comment: comment,
    )..dump(jsonFile);
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
      ..addOption(
        'variable',
        abbr: 'v',
        mandatory: true,
        help: 'The variable name to use.',
      )
      ..addOption(
        'comment',
        abbr: 'c',
        help: 'The comment to show above the reference.',
      );
  }

  @override
  String get description => 'Add a file.';

  @override
  String get name => 'file';

  @override
  void run() {
    final results = argResults!;
    final rest = results.rest;
    if (rest.length != 2) {
      return print(
        'Usage: ${runner?.executableName} <json-file> <source-file>',
      );
    }
    final jsonFile = File(rest.first);
    if (jsonFile.existsSync() == false) {
      return print('Error: Json file ${jsonFile.path} does not exist.');
    }
    final source = File(rest.last);
    final variableName = results['variable'] as String;
    if (source.existsSync() == false) {
      return print('Error: Source file ${source.path} does not exist.');
    }
    final store = AssetStore.fromFile(jsonFile);
    for (final asset in store.assets) {
      if (asset.variableName == variableName) {
        return print('Error: There is already a variable named $variableName.');
      }
    }
    store
      ..importFile(
        source: source,
        variableName: variableName,
        comment: results['comment'] as String?,
      )
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
      ..addOption(
        'variable',
        abbr: 'v',
        mandatory: true,
        help: 'The variable name to use.',
      )
      ..addOption(
        'comment',
        abbr: 'c',
        help: 'The comment to show above the reference.',
      );
  }

  @override
  String get description => 'Add a directory.';

  @override
  String get name => 'directory';

  @override
  void run() {
    final results = argResults!;
    final rest = results.rest;
    if (rest.length != 2) {
      return print(
        'Usage: ${runner?.executableName} <json-file> <source-directory>',
      );
    }
    final jsonFile = File(rest.first);
    if (jsonFile.existsSync() == false) {
      return print('Error: Json file ${jsonFile.path} does not exist.');
    }
    final source = Directory(rest.last);
    final variableName = results['variable'] as String;
    if (source.existsSync() == false) {
      return print('Error: Source file ${source.path} does not exist.');
    }
    final store = AssetStore.fromFile(jsonFile);
    for (final asset in store.assets) {
      if (asset.variableName == variableName) {
        return print('Error: There is already a variable named $variableName.');
      }
    }
    store
      ..importDirectory(
        source: source,
        variableName: variableName,
        comment: results['comment'] as String?,
      )
      ..dump(jsonFile);
    assetStoreToDart(store);
    print('Done.');
  }
}

/// A command for changing the comment for an [AssetReferenceReference].
class CommentCommand extends Command<void> {
  /// Create an instance.
  CommentCommand() {
    argParser.addOption(
      'comment',
      abbr: 'c',
      help: 'The new comment (defaults to none).',
    );
  }
  @override
  String get description => 'Change asset comment';

  @override
  String get name => 'comment';

  @override
  void run() {
    final results = argResults!;
    final rest = results.rest;
    if (rest.length != 2) {
      return print(
        'Usage: ${runner?.executableName} <json-file> <variableName>',
      );
    }
    final file = File(rest.first);
    if (file.existsSync() == false) {
      return print('Error: Json file ${file.path} does not exist.');
    }
    final variableName = rest.last;
    final store = AssetStore.fromFile(file);
    for (var i = 0; i < store.assets.length; i++) {
      final reference = store.assets[i];
      if (reference.variableName == variableName) {
        store.assets.remove(reference);
        store.assets.insert(
          i,
          AssetReferenceReference(
            variableName: reference.variableName,
            reference: reference.reference,
            comment: results['comment'] as String?,
          ),
        );
        store.dump(file);
        assetStoreToDart(store);
        return print('Done.');
      }
      print('Error: Could not find an entry with the name $variableName.');
    }
  }
}

/// A command to remove entries from a [AssetStore] instance.
class RmCommand extends Command<void> {
  @override
  String get description => 'Remove an entry.';

  @override
  String get name => 'rm';

  @override
  void run() {
    final rest = argResults!.rest;
    if (rest.length != 2) {
      return print(
        'Usage: ${runner?.executableName} <json-file> <variableName>',
      );
    }
    final file = File(rest.first);
    if (file.existsSync() == false) {
      return print('Error: Json file ${file.path} does not exist.');
    }
    final variableName = rest.last;
    final store = AssetStore.fromFile(file);
    for (final reference in store.assets) {
      if (reference.variableName == variableName) {
        if (reference.reference.type == AssetType.collection) {
          Directory(reference.reference.name).deleteSync(recursive: true);
        } else {
          File(reference.reference.name).deleteSync();
        }
        store.assets.remove(reference);
        store.dump(file);
        assetStoreToDart(store);
        return print('Done.');
      }
    }
    print('No entries found with the name $variableName.');
  }
}

/// A command for listing the contents of a [AssetStore] instance.
class LsCommand extends Command<void> {
  @override
  String get description => 'List contents.';

  @override
  String get name => 'ls';

  @override
  void run() {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      return print('Usage: ${runner?.executableName} <json-file>');
    }
    final file = File(rest.first);
    if (file.existsSync() == false) {
      return print('Error: Json file ${file.path} does not exist.');
    }
    final store = AssetStore.fromFile(file);
    print('--- ${file.path} ---');
    if (store.assets.isEmpty) {
      return print('No assets to show.');
    }
    for (final reference in store.assets) {
      final type = reference.reference.type == AssetType.file ? 'F' : 'D';
      print('${reference.variableName} ($type): ${reference.comment}');
    }
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

Future<void> main(final List<String> args) async {
  final command = CommandRunner<void>(
      'assets',
      'Create and edit asset stores.\n\n'
          'You must first create an asset store with the `create` command:\n'
          '  `assets create assets.json bin/assets.dart -c "Assets for the game."`')
    ..addCommand(CreateCommand())
    ..addCommand(FileCommand())
    ..addCommand(DirectoryCommand())
    ..addCommand(CommentCommand())
    ..addCommand(LsCommand())
    ..addCommand(RmCommand())
    ..addCommand(RegenerateCommand());
  try {
    await command.run(args);
  } on UsageException catch (e) {
    print(e);
  }
}
