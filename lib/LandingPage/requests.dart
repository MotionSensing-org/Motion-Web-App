import 'dart:io';

import 'package:http/http.dart';

import '../consts.dart';

Future writeToServer({required String query, required String body}) async {
  const String queryPrefix = '?request_type=';
  final String url = '$backendUrl/$queryPrefix$query';
  Response response = await post(Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: body);
  return response.body;
}

Future getData({required String query}) async {
  const String queryPrefix = '?request_type=';
  final String url = '$backendUrl/$queryPrefix$query';
  Response response = await get(Uri.parse(url));
  return response.body;
}

Future getDataStream() async {
  const String url = '$backendUrl/stream';
  Response response = await get(Uri.parse(url));
  return response.body;
}

void writeLineToFile(String filePath, String line) {
  File file = File(filePath);

  // Open the file in write mode and append the line
  file.writeAsStringSync('$line\n', mode: FileMode.append);
}

Future<String> getPythonScriptPath() async {
  var files = await Directory.current.list(recursive: true).toList();

  for (var file in files) {
    String path = file.path;
    String name = path.split('\\').last;
    if (file is File && name == 'app.py') {
      String filePath = './scripy_path.txt';
      writeLineToFile(filePath, path);
      return path;
    }
  }

  return '';

  // return 'C:\\Users\\odztm\\PycharmProjects\\flaskProject\\app.py';
}