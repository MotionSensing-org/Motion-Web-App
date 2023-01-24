import 'package:http/http.dart';

Future setServerParams(url, body) async {
  Response response = await post(url,
      headers: {"Content-Type": "application/json"},
      body: body);
  return response.body;
}

Future getData(url) async {
  Response response = await get(url);
  return response.body;
}
