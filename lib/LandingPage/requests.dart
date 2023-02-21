import 'dart:io'; 
import 'package:http/http.dart';  
import '../consts.dart'; 

Future writeToServer({required String query, required String body}) async {  // Defining a function that will send a POST request to the server
  const String queryPrefix = '?request_type=';  // Declaring a constant variable with a string value
  final String url = '$backendUrl/$queryPrefix$query';  // Creating a string that represents the complete URL for the server request
  Response response = await post(Uri.parse(url),  // Sending a POST request to the server
      headers: {"Content-Type": "application/json"},  // Specifying the headers of the request
      body: body);  // Including the body of the request in the POST request
  return response.body;  // Returning the response body from the server
}

Future getData({required String query}) async {  // Defining a function that will send a GET request to the server
  const String queryPrefix = '?request_type=';  // Declaring a constant variable with a string value
  final String url = '$backendUrl/$queryPrefix$query';  // Creating a string that represents the complete URL for the server request
  Response response = await get(Uri.parse(url));  // Sending a GET request to the server
  return response.body;  // Returning the response body from the server
}

Future getDataStream() async {  // Defining a function that will send a GET request to the server to get a data stream
  const String url = '$backendUrl/stream';  // Creating a string that represents the complete URL for the server request
  Response response = await get(Uri.parse(url));  // Sending a GET request to the server
  return response.body;  // Returning the response body from the server
}

Future<String> getPythonScriptPath() async {  // Defining a function that will return the path of a Python script
  var files = await Directory.current.list(recursive: true).toList();  // Getting a list of files in the current directory and all subdirectories

  for (var file in files) {  // Looping through each file in the list
    String path = file.path;  // Getting the path of the file
    String name = path.split('\\').last;  // Getting the name of the file by splitting the path at the backslashes and taking the last element
    if (file is File && name == 'app.py') {  // Checking if the file is a Python script named 'app.py'
      return path;  // Returning the path of the Python script
    }
  }

  return '';  // Returning an empty string if no Python script is found

  // return 'C:\\Users\\odztm\\PycharmProjects\\flaskProject\\app.py';  
