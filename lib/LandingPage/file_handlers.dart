import 'dart:convert';
import 'dart:io';


// Asynchronously get a file from the file system at the specified file path
Future<File> getFile(String filePath) async {
  var file = File(filePath); // Create a new File object with the specified file path
  if(!await file.exists()) { // Check if the file exists on the file system
    await file.create(recursive: true); // If the file does not exist, create it and any missing parent directories
    Map m = {}; // Create an empty Map to use as the default JSON data
    await file.writeAsString(prettyJson(m)); // Write the default JSON data to the file
  }

  return file; // Return the File object
}

// Synchronously get a file from the file system at the specified file path
File getFileSync(String filePath) {
  var file = File(filePath); // Create a new File object with the specified file path
  if(!file.existsSync()) { // Check if the file exists on the file system
    file.createSync(recursive: true); // If the file does not exist, create it and any missing parent directories
    Map m = {}; // Create an empty Map to use as the default JSON data
    file.writeAsStringSync(prettyJson(m)); // Write the default JSON data to the file
  }

  return file; // Return the File object
}

// Asynchronously get the JSON data from a file
Future<Map<String, dynamic>> getJsonConfig(File file) async {
  String jsonString = await file.readAsString(); // Read the contents of the file as a string
  Map<String, dynamic> jsonData = jsonDecode(jsonString); // Decode the JSON string into a Map
  return jsonData; // Return the Map object
}

// Synchronously get the JSON data from a file
Map<String, dynamic> getJsonConfigSync(File file) {
  String jsonString = file.readAsStringSync(); // Read the contents of the file as a string
  Map<String, dynamic> jsonData = jsonDecode(jsonString); // Decode the JSON string into a Map
  return jsonData; // Return the Map object
}

// Asynchronously edit a JSON file
Future<bool> editJsonFile(String filePath, String name,
    {Map newConfiguration=const {}, bool delete = false}) async {
  File file = await getFile(filePath); // Get the File object for the specified file path
  Map jsonData = await getJsonConfig(file); // Get the JSON data from the file
  if(!delete) { // If not deleting, update the JSON data for the specified name with the new configuration data
    jsonData[name] = newConfiguration;
  } else { // If deleting, remove the specified name from the JSON data
     jsonData.remove(name);
  }

  String updatedJsonString = prettyJson(jsonData); // Encode the updated JSON data as a string
  await file.writeAsString(updatedJsonString); // Write the updated JSON data to the file
  return true; // Return true to indicate success
}

// Synchronously edits the JSON configuration data in a file
bool editJsonFileSync(String filePath, String name,
    {Map newConfiguration=const {}, bool delete = false}) {
  File file = getFileSync(filePath); // Gets the file object for the specified file path
  Map jsonData = getJsonConfigSync(file); // Gets the JSON data from the file
  if(!delete) { // Checks if the 'delete' flag is false
    jsonData[name] = newConfiguration;// Adds or updates the specified JSON configuration
  } else {
    jsonData.remove(name);// Removes the specified JSON configuration
  }

  String updatedJsonString = prettyJson(jsonData);// Converts the updated JSON data to a formatted string
  file.writeAsStringSync(updatedJsonString);// Writes the updated JSON data to the f
  return true;
}

String prettyJson(dynamic json) {// Returns a formatted string of a JSON object
  var spaces = ' ' * 4;
  var encoder = JsonEncoder.withIndent(spaces);
  return encoder.convert(json);
}
