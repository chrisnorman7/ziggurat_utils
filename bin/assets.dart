// ignore_for_file: avoid_print
/// A script for maintaining assets.
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:ziggurat/ziggurat.dart' hide Command;

import 'common.dart';

const uuid = Uuid();
const outputDirectoryKey = 'output-directory';
const codeDirectoryKey = 'code-directory';

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

/// A command to generate assets from a directory.
class GenerateCommand extends Command<void> {
  /// Create an instance.
  GenerateCommand() : super() {
    argParser
      ..addOption(
        outputDirectoryKey,
        abbr: 'o',
        defaultsTo: 'assets',
        help: 'The directory to write assets to',
      )
      ..addOption(
        codeDirectoryKey,
        abbr: 'c',
        defaultsTo: 'lib/src/assets',
        help: 'The directory where generated code will be placed',
      );
  }

  @override
  String get description =>
      'Generate a directory of encrypted assets from an input directory.';

  @override
  String get name => 'generate';

  /// Run the command.
  @override
  void run() {
    final results = argResults!;
    if (results.rest.isEmpty) {
      print('Nothing to do: No input directories provided.');
      return;
    }
    final codeDirectory = Directory(results[codeDirectoryKey] as String);
    if (!codeDirectory.existsSync()) {
      codeDirectory.createSync(recursive: true);
    } else {
      for (final entity in codeDirectory.listSync()) {
        entity.deleteSync(recursive: true);
      }
    }
    final outputDirectory = Directory(results[outputDirectoryKey] as String);
    if (!outputDirectory.existsSync()) {
      outputDirectory.createSync(recursive: true);
    } else {
      for (final entity in outputDirectory.listSync()) {
        entity.deleteSync(recursive: true);
      }
    }
    for (final directoryName in results.rest) {
      final directory = Directory(directoryName);
      if (!directory.existsSync()) {
        print('Directory $directoryName does not exist.');
        continue;
      }
      print('Entering directory $directoryName.');
      for (final subdirectory in directory.listSync().whereType<Directory>()) {
        final store = AssetStore(
          filename: path.join(
            codeDirectory.path,
            '${path.basenameWithoutExtension(subdirectory.path)}.dart',
          ),
          destination:
              path.join(outputDirectory.path, path.basename(subdirectory.path)),
          assets: [],
          comment: subdirectory.path,
        );
        for (final entity in subdirectory.listSync()) {
          final variableName = makeVariableName(
            path.basenameWithoutExtension(entity.path),
          );
          if (entity is File) {
            print('Importing file ${entity.path}.');
            store.importFile(
              source: entity,
              variableName: variableName,
              comment: entity.path,
              relativeTo: Directory.current,
            );
          } else if (entity is Directory) {
            print('Importing directory ${entity.path}.');
            store.importDirectory(
              source: entity,
              variableName: variableName,
              comment: entity.path,
              relativeTo: Directory.current,
            );
          } else {
            throw ArgumentError('Cannot import $entity.');
          }
        }
        assetStoreToDart(store);
        print('Wrote ${store.filename}.');
      }
      print('Leaving directory $directoryName.');
    }
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
    ..addCommand(RegenerateCommand())
    ..addCommand(GenerateCommand());
  try {
    await command.run(args);
  } on UsageException catch (e) {
    print(e);
  }
}
