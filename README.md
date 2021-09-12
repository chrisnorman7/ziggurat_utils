# ziggurat_utils

This package provides various utilities for use with the [ziggurat]([URL](https://pub.dev/packages/ziggurat)) package.

## Usage

First, activate the package so you can use the scripts:

```shell
pub global activate ziggurat_utils
```

Next, see below for the scripts provided by this package.

## Contents

### data2json

The `data2json` utility allows you to convert any file to pure dart code. This is useful if you want to hard code music into the code of your program so it doesn't not to be loaded from disk.

### Usage

```shell
Convert data files into code via json.

It is first necessary to create a file:
  `data2json create music.json -c "Music to be loaded from code."`

Then you can add files to the collection with the `add command`.

Usage: data2json <command> [arguments]

Global options:
-h, --help    Print this usage information.

Available commands:
  add       Add a file to a data file.
  comment   Change the comment for an entry.
  compile   Convert a JSON file to Dart code.
  create    Create a new data file.
  ls        List files in a data file.
  remove    Remove a file.

Run "data2json help <command>" for more information about a command.
```

## vault

This utility allows you to encrypt multiple audio files into a single file and generate Dart code which lets you easily access those files from within your own code, without having to worry about file names or the encryption key.

### Usage

```shell
Create and edit vault files.

You must first create a vault file with the `create` command:
  `vault create vault.json -c "Sounds for the game."`

Usage: vault <command> [arguments]

Global options:
-h, --help    Print this usage information.

Available commands:
  comment   Change or clear the comment for a file or folder.
  compile   Create an encrypted vault file and corresponding Dart code.
  create    Create a new vault file.
  file      Add a file.
  folder    Add a folder.
  ls        List files.
  remove    Remove a file or folder.

Run "vault help <command>" for more information about a command.
```
