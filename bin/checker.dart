import 'dart:io';

import 'package:checker/checker.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

List<String> _patterns = [];
List<String> _target = [];
List<String> _skipFile = [];
List<String> _skipFolder = [];
void main(List<String> args) async {
  if (args.contains('-d')) {
    kDebugMode = true;
  }

  var checkConfig = join(Directory.current.path, 'check.yaml');

  await _readSettingsFromYaml(File(checkConfig));

  _printSettingsFound();

  if (_patterns.isEmpty) {
    print(
        '\u001b[31mError: No pattern provided. Please provide a valid pattern.\x1B[0m');

    exit(1);
  }

  final codeGuard = CodeGuard(
    patterns: _patterns,
    targetFileTypes: _target,
    explicitIgnoreSubType: _skipFile,
    explicitIgnoreFolder: _skipFolder,
  );

  final files = await codeGuard.getFilesFromDirectory(
      entities: await Directory.current.list().toList());

  for (var file in files) {
    codeGuard.matches.addAll(await codeGuard.findMatches(file: file));
  }

  if (codeGuard.matches.isNotEmpty) {
    for (var element in codeGuard.matches) {
      print('\u001b[31m$element\x1B[0m');
    }
    exitCode = 1;
  } else {
    print('\u001b[32mSuccess, no matches found!\x1B[0m');
  }
}

Future<void> _readSettingsFromYaml(File yaml) async {
  if (await yaml.exists()) {
    var fileContent = await yaml.readAsString();

    var doc = loadYaml(fileContent);

    final patternsYaml = doc['patterns'] ?? [];
    final targetYaml = doc['target'] ?? [];
    final skipFileYaml = doc['skipFile'] ?? [];
    final skipFolderYaml = doc['skipFolder'] ?? [];

    _patterns = (patternsYaml as List).map((item) => item.toString()).toList();
    _target = (targetYaml as List).map((item) => item.toString()).toList();
    _skipFile = (skipFileYaml as List).map((item) => item.toString()).toList();
    _skipFolder =
        (skipFolderYaml as List).map((item) => item.toString()).toList();
  } else {
    print(
        '\u001b[31mError: No check.yaml file found. Please provide a check.yaml file in your project root.\x1B[0m');
    exit(1);
  }
}

_printSettingsFound() {
  print('');
  print('\u001b[36mLooking for these patterns: \u001b[33m$_patterns\x1B[0m');
  if (_target.isNotEmpty)
    print('\u001b[36mFiltering files by filetypes: \u001b[33m$_target\x1B[0m');
  if (_skipFile.isNotEmpty)
    print(
        '\u001b[36mIgnoring corresponding subtypes: \u001b[33m$_skipFile\x1B[0m');
  if (_skipFolder.isNotEmpty)
    print('\u001b[36mIgnoring folders: \u001b[33m$_skipFolder\x1B[0m');
  print('');
}
