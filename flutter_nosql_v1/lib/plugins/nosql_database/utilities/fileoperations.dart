import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

Future<File> get _localFile async {
  final path = await _localPath;
  return File('$path/counter.txt');
}

Future<Map<String, dynamic>?> readFile(String filePath) async {
  try {
    File file = await _localFile;
    if (await file.exists()) {
      String contents = await file.readAsString();
      Map<String, dynamic> jsonData = jsonDecode(contents);
      return jsonData;
    } else {
      throw Exception("File not found");
    }
  } catch (e) {
    throw "Error reading JSON file: $e";
  }
}

Future<bool> writeFile(String filePath, Map<dynamic, dynamic> jsonData) async {
  try {
    File file = await _localFile;
    String jsonString = jsonEncode(jsonData);
    await file.writeAsString(jsonString);

    return true;
  } catch (e) {
    throw "Error writing JSON file: $e";
  }
}

Future<bool> deleteFile(String filePath) async {
  try {
    File file = await _localFile;
    if (await file.exists()) {
      await file.delete();
      return true;
    } else {
      throw Exception("File not found");
    }
  } catch (e) {
    throw "Error reading JSON file: $e";
  }
}
