// ignore_for_file: avoid_print
/// A script for maintaining assets.
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_style/dart_style.dart';
import 'package:ziggurat/ziggurat.dart' hide Command;

import 'common.dart';

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
    buffer
      ..writeln('const ${reference.variableName} = AssetReference(')
      ..write("'${reference.reference.name.replaceAll(r'\', '/')}', "
          '${reference.reference.type}, '
          "encryptionKey: '${reference.reference.encryptionKey}',);");
  }
  final formatter = DartFormatter();
  final code = formatter.format(buffer.toString());
  File(store.filename).writeAsStringSync(code);
}

/// A command for creating a new assets file.
class CreateCommand extends Command<void> {
  @override
  String get description => 'Create a new assets store.';

  @override
  String get name => 'create';

  @override
  void run() {
    final jsonFile = getJsonFile();
    if (!validFile(jsonFile)) {
      return;
    }
    final dartFilename = getText(
      message: 'Dart filename:',
      defaultValue: 'lib/assets.dart',
    );
    final destination = getText(
      message: 'Directory where encrypted files should be stored:',
      defaultValue: 'assets',
    );
    final comment = getText(
      message: 'File comment:',
      defaultValue: 'Game assets.',
    );
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
  @override
  String get description => 'Add a file.';

  @override
  String get name => 'file';

  @override
  void run() {
    final jsonFile = getJsonFile();
    if (!validFile(jsonFile)) {
      return;
    }
    final source = File(
      getText(
        message: 'Source filename:',
      ),
    );
    final variableName = getVariableName();
    if (!validVariableName(variableName)) {
      return;
    }
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
        comment: getComment(),
      )
      ..dump(jsonFile);
    assetStoreToDart(store);
    print('Done.');
  }
}

/// A command for adding directories to an [AssetStore].
class DirectoryCommand extends Command<void> {
  @override
  String get description => 'Add a directory.';

  @override
  String get name => 'directory';

  @override
  void run() {
    final jsonFile = getJsonFile();
    if (!validFile(jsonFile)) {
      return;
    }
    final source = Directory(getText(message: 'Source directory name:'));
    final variableName = getVariableName();
    if (!validVariableName(variableName)) {
      return;
    }
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
        comment: getComment(),
      )
      ..dump(jsonFile);
    assetStoreToDart(store);
    print('Done.');
  }
}

/// A command for changing the variable name of an asset.
class RenameCommand extends Command<void> {
  @override
  String get description => 'Change asset variable name';
  @override
  String get name => 'rename';

  /// Run the command.
  @override
  void run() {
    final jsonFile = getJsonFile();
    if (!validFile(jsonFile)) {
      return;
    }
    final oldVariableName = getText(message: 'Old variable name:');
    final store = AssetStore.fromFile(jsonFile);
    for (final asset in store.assets) {
      if (asset.variableName == oldVariableName) {
        store.assets.removeWhere(
          (final element) => element.variableName == oldVariableName,
        );
        store.assets.add(
          AssetReferenceReference(
            variableName: getVariableName(),
            reference: asset.reference,
            comment: asset.comment,
          ),
        );
        store.dump(jsonFile);
        assetStoreToDart(store);
        return print('Done.');
      }
    }
    print('No entry with the variable name $oldVariableName found.');
  }
}

/// A command for changing the comment for an [AssetReferenceReference].
class CommentCommand extends Command<void> {
  @override
  String get description => 'Change asset comment';

  @override
  String get name => 'comment';

  @override
  void run() {
    final jsonFile = getJsonFile();
    if (!validFile(jsonFile)) {
      return;
    }
    final variableName = getText(message: 'Variable to change:');
    final store = AssetStore.fromFile(jsonFile);
    for (final reference in store.assets) {
      if (reference.variableName == variableName) {
        store.assets.removeWhere(
          (final element) => element.variableName == variableName,
        );
        store.assets.add(
          AssetReferenceReference(
            variableName: reference.variableName,
            reference: reference.reference,
            comment: getText(
              message: 'New comment:',
              defaultValue: reference.comment ?? '',
            ),
          ),
        );
        store.dump(jsonFile);
        assetStoreToDart(store);
        return print('Done.');
      }
    }
    print('Error: Could not find an entry with the name $variableName.');
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
    final jsonFile = getJsonFile();
    if (!validFile(jsonFile)) {
      return;
    }
    final variableName = getText(message: 'Variable name:');
    final store = AssetStore.fromFile(jsonFile);
    for (final reference in store.assets) {
      if (reference.variableName == variableName) {
        if (reference.reference.type == AssetType.collection) {
          Directory(reference.reference.name).deleteSync(recursive: true);
        } else {
          File(reference.reference.name).deleteSync();
        }
        store.assets.remove(reference);
        store.dump(jsonFile);
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
    final jsonFile = getJsonFile();
    if (!validFile(jsonFile)) {
      return;
    }
    final store = AssetStore.fromFile(jsonFile);
    print('--- ${jsonFile.path} ---');
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
    final jsonFile = getJsonFile();
    if (!validFile(jsonFile)) {
      return;
    }
    final store = AssetStore.fromFile(jsonFile);
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
    ..addCommand(RenameCommand())
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
