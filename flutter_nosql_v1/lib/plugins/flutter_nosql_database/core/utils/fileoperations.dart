import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

Future<File> _localFile(String filePath) async {
  final path = await _localPath;
  return File("$path/$filePath");
}

Future<Map<String, dynamic>?> readFile(String filePath) async {
  try {
    File file = await _localFile(filePath);
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
    File file = await _localFile(filePath);
    String jsonString = jsonEncode(jsonData);

    if (!await file.exists()) {
      await file.create();
    }
    await file.writeAsString(jsonString);
    return true;
  } catch (e) {
    throw "Error writing JSON file: $e";
  }
}

Future<bool> deleteFile(String filePath) async {
  try {
    File file = await _localFile(filePath);
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

Future<bool> cleanFile(String filePath) async {
  try {
    File file = await _localFile(filePath);
    if (await file.exists()) {
      await file.writeAsString("");
      return true;
    } else {
      throw Exception("File not found");
    }
  } catch (e) {
    throw "Error reading JSON file: $e";
  }
}

Future<bool> checkStoragePermissions() async {
  PermissionStatus storagePermission = await Permission.storage.status;

  if (!storagePermission.isGranted) {
    PermissionStatus status = await Permission.manageExternalStorage.request();

    return status.isGranted;
  }

  return true;
}
