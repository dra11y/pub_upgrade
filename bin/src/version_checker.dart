import 'dart:convert';
import 'dart:io';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

class VersionChecker {
  final client = HttpClient();

  Future<void> checkVersions() async {
    final file = File('pubspec.yaml');
    final content = await file.readAsString();
    final pubspec = Pubspec.parse(content);
    bool allLatest = true;
    for (final dependency in [
      ...pubspec.dependencies.entries,
      ...pubspec.devDependencies.entries,
    ]) {
      final name = dependency.key;
      final dep = dependency.value;
      if (dep is HostedDependency) {
        stdout.write('Checking $name ... ');
        final latest = await getLatestVersion(name);
        final version = Version.parse(latest);
        if (dep.version.allows(version)) {
          print('OK');
          continue;
        }
        allLatest = false;
        print('latest $name: $latest, declared: ${dep.version}');
      }
    }

    if (allLatest) {
      print('All latest!');
    }

    client.close();
  }

  Future<String> getLatestVersion(String packageName) async {
    final request = await client
        .getUrl(Uri.parse('https://pub.dev/api/packages/$packageName'));
    final response = await request.close();
    if (response.statusCode == HttpStatus.ok) {
      final body = await response.transform(utf8.decoder).join();
      final data = json.decode(body);
      return data['latest']['version'];
    }
    throw Exception('Could not get version for $packageName.');
  }
}
