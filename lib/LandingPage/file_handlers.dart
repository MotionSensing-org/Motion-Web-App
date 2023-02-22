import 'dart:convert';
import 'dart:io';

Future<File> getFile(String filePath) async {
  var file = File(filePath);
  if(!await file.exists()) {
    await file.create(recursive: true);
    Map m = {};
    await file.writeAsString(prettyJson(m));
  }

  return file;
}

File getFileSync(String filePath) {
  var file = File(filePath);
  if(!file.existsSync()) {
    file.createSync(recursive: true);
    Map m = {};
    file.writeAsStringSync(prettyJson(m));
  }

  return file;
}

Future<Map<String, dynamic>> getJsonConfig(File file) async {
  String jsonString = await file.readAsString();
  Map<String, dynamic> jsonData = jsonDecode(jsonString);
  return jsonData;
}

Map<String, dynamic> getJsonConfigSync(File file) {
  String jsonString = file.readAsStringSync();
  Map<String, dynamic> jsonData = jsonDecode(jsonString);
  return jsonData;
}

Future<bool> editJsonFile(String filePath, String name,
    {Map newConfiguration=const {}, bool delete = false}) async {
  File file = await getFile(filePath);
  Map jsonData = await getJsonConfig(file);
  if(!delete) {
    jsonData[name] = newConfiguration;
  } else {
     jsonData.remove(name);
  }

  String updatedJsonString = prettyJson(jsonData);
  await file.writeAsString(updatedJsonString);
  return true;
}

bool editJsonFileSync(String filePath, String name,
    {Map newConfiguration=const {}, bool delete = false}) {
  File file = getFileSync(filePath);
  Map jsonData = getJsonConfigSync(file);
  if(!delete) {
    jsonData[name] = newConfiguration;
  } else {
    jsonData.remove(name);
  }

  String updatedJsonString = prettyJson(jsonData);
  file.writeAsStringSync(updatedJsonString);
  return true;
}

String prettyJson(dynamic json) {
  var spaces = ' ' * 4;
  var encoder = JsonEncoder.withIndent(spaces);
  return encoder.convert(json);
}