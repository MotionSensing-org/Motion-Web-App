import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_project/LandingPage/requests.dart';
import 'package:iot_project/consts.dart';
import 'package:mutex/mutex.dart';



class TextFieldClass{
  TextEditingController controller = TextEditingController(); // Creates a TextEditingController object.
  String imuMac; // Declares a String variable named "imuMac".

  TextFieldClass({required this.controller, this.imuMac=exampleImuMac}); // Constructor for the TextFieldClass that initializes the controller and imuMac variables.
}

class Deque {
  List q = []; // Declares an empty List.
  int maxSize; // Declares an integer variable named "maxSize".
  Deque({required this.maxSize}); // Constructor for the Deque class that initializes the maxSize variable.
  void add(List l) { // Defines a method named "add" that takes a List argument named "l".
    q.addAll(l); // Adds all the elements of "l" to the List "q".
    if(q.length > maxSize) { // Checks if the length of the List "q" is greater than the value of "maxSize".
      q = q.skip(q.length - maxSize).toList(); // If the length of "q" is greater than "maxSize", remove the excess elements from "q" and update its value.
    }
  }

  void clear() { // Defines a method named "clear".
    q.clear(); // Clears the List "q".
  }
}

class RequestHandler extends ChangeNotifier { // Defines a class named "RequestHandler" that extends the ChangeNotifier class.
  String curAlg = ''; // Declares a String variable named "curAlg" and initializes it with an empty string.
  List algorithms = []; // Declares an empty List named "algorithms".
  List curAlgParams = []; // Declares an empty List named "curAlgParams".
  List imus = []; // Declares an empty List named "imus".
  Map paramsToSet = {}; // Declares an empty Map named "paramsToSet".
  Ref ref; // Declares a variable named "ref".
  Map dataTypes = {}; // Declares an empty Map named "dataTypes".
  String? filename; // Declares an optional String variable named "filename".
  File? outputFile; // Declares an optional File variable named "outputFile".
  bool stop = true; // Declares a boolean variable named "stop" and initializes it to "true".
  int iterationNumber = 0; // Declares an integer variable named "iterationNumber" and initializes it to 0.
  bool connectionSuccess = false; // Declares a boolean variable named "connectionSuccess" and initializes it to "false".
  Mutex m = Mutex(); // Declares a Mutex object named "m".
  List<List> rows = []; // Declares an empty List named "rows".
  int cyclicIterationNumber = -1; // Declares an integer variable named "cyclicIterationNumber" and initializes it to -1.
  int dataTypesCount = 0; // Declares an integer variable named "dataTypesCount" and initializes it to 0.
  Map batteries = {}; // Declares an empty Map named "batteries".

  RequestHandler(this.ref) { // Constructor for the RequestHandler class that takes a "ref" argument and initializes it.
    Timer.periodic(const Duration(seconds: 3), keepAliveBackendConnection); // Calls the keepAliveBackendConnection method every 3 seconds using the Timer.periodic method.
    Timer.periodic(const Duration(seconds: 5), updateBatteries); // Calls the updateBatteries method every 5 seconds using the Timer.periodic method.
  }

  Future<void> keepAliveBackendConnection(Timer timer) async {
  // This function sends a 'keepalive' query to the server to ensure that the connection is still active.
  // It is called periodically at a set interval specified by the Timer.
  if(connectionSuccess && ref.read(dataProvider).stop) {
    await getData(query: 'keepalive');
  }
}

void clearOutputFileName() {
  // This function clears the output file name by notifying the listeners.
  notifyListeners();
}

void connectionSuccessful(bool success) {
  // This function updates the connection status based on the provided boolean value.
  connectionSuccess = success;
}

bool isConnected() {
  // This function returns the current connection status.
  return connectionSuccess;
}

void setParamsMap(Map params) {
  // This function sets the parameters to be sent to the server.
  paramsToSet = params;
}

Future<Map> getDecodedData(String query) async {
  // This function sends a query to the server and returns the decoded response as a Map object.
  var data = await getData(query: query);
  return jsonDecode(data);
}

Future<bool> getAlgList() async {
  // This function retrieves the list of available algorithms from the server and updates the local copy.
  // It also notifies the listeners of any changes.
  Map data = await getDecodedData('algorithms');
  algorithms = data['algorithms'];
  notifyListeners();
  return true;
}

Future<bool> getAlgParams() async {
  // This function retrieves the parameters for the current algorithm from the server and updates the local copy.
  // It also notifies the listeners of any changes.
  Map data = await getDecodedData('get_params');
  curAlgParams = data['params'];
  notifyListeners();
  return true;
}

Future<bool> updateBatteries(Timer timer) async {
  // This function retrieves the battery information from the server and updates the local copy.
  // It also notifies the listeners of any changes.
  if(connectionSuccess && !ref.read(dataProvider).stop) {
    Map data = await getDecodedData('get_batteries');
    batteries = data['batteries'];
    // print(batteries);
    notifyListeners();
  }
  return true;
}

Future<bool> getCurAlg() async {
  // This function retrieves the current algorithm from the server and updates the local copy.
  // It also notifies the listeners of any changes.
  Map data = await getDecodedData('get_cur_alg');
  curAlg = data['cur_alg'];
  notifyListeners();
  return true;
}

Future<bool> getDataTypes() async {
  // This function retrieves the available data types from the server and updates the local copy.
  // It also notifies the listeners of any changes.
  Map data = await getDecodedData('get_data_types');
  dataTypes = data['data_types'];
  ref.read(dataProvider).dataTypes = dataTypes;
  ref.read(dataTypesProvider).updateDict(dataTypes);
  return true;
}

Future setCurAlg() async {
  // This function sets the current algorithm on the server using the chosen algorithm.
  var body = json.encode(ref.read(chosenAlgorithmProvider).chosenAlg);
  await writeToServer(query: 'set_cur_alg', body: body);
  return;
}

Future setAlgParams() async {
  // This function sets the algorithm parameters on the server using the current parameter values.
  var body = json.encode(paramsToSet);
  await writeToServer(query: 'set_params', body: body);
  return;
}

Future connectToIMUs(Map<String, List<TextFieldClass>> addedIMUs) async {
  // Convert added IMUs to map of strings
  Map<String, List<String>> addedIMUSStrings = {
    'imus': addedIMUs['imus']!.map((e) => e.imuMac).toList(),
    'feedbacks': addedIMUs['feedbacks']!.map((e) => e.imuMac).toList()
  };
  // Convert map to JSON and send to server
  var body = json.encode(addedIMUSStrings);
  return await writeToServer(query: 'set_imus', body: body);
}

class DataProvider extends ChangeNotifier {
  List imus = []; // List of connected IMUs
  Map dataBuffer = {}; // Buffer for storing data
  Map checkpointDataBuffer = {}; // Checkpoint buffer for storing data
  Map dataTypes = {}; // Map of data types for each IMU
  Ref ref; // Reference to Provider
  String? filename; // Name of file to save data to
  bool stop = true; // Flag for whether to collect data
  bool feedbackActive = false; // Flag for whether feedback is active
  bool shouldInitBuffers = false; // Flag for whether to initialize buffers
  final int bufferSize = 500; // Max size of buffer
  Mutex m = Mutex(); // Mutex for data access
  final stopWatch = Stopwatch(); // Stopwatch for timing data collection
  late Timer t; // Timer for collecting data

  DataProvider(this.ref) {
    // Set up timer for collecting data
    t = Timer.periodic(const Duration(milliseconds: 40), updateDataSource);
  }

  @override
  void dispose() {
    t.cancel(); // Cancel timer when disposing of DataProvider
    super.dispose();
  }

  void startStopDataCollection({bool stop=true}) {
    this.stop = stop; // Set stop flag for data collection
  }

  Map provideRawData(String imu) {
    return checkpointDataBuffer[imu]; // Get checkpoint buffer for specific IMU
  }

  void initBuffersAndTypesCounter() {
    dataBuffer = {}; // Reset data buffer
    checkpointDataBuffer = {}; // Reset checkpoint buffer

    // Initialize buffers for each IMU and data type
    for (var imu in imus) {
      dataBuffer[imu] = {};
      checkpointDataBuffer[imu] = {};
      dataTypes.forEach((key, value) {
        for (var type in value) {
          dataBuffer[imu][type] = Deque(maxSize: bufferSize);
          checkpointDataBuffer[imu][type] = Deque(maxSize: bufferSize);
        }
      });
    }
  }
}


void updateDataSource(Timer timer) async {
  // Check if imus, dataTypes, and shouldInitBuffers are not empty
  if(imus.isNotEmpty && dataTypes.isNotEmpty && shouldInitBuffers) {
    // Initialize buffers and counters
    initBuffersAndTypesCounter();
    shouldInitBuffers = false;
  }

  // Check if the stop flag is set
  if(stop) {
    // Stop and reset the stopwatch timer and return
    stopWatch.stop();
    stopWatch.reset();
    return;
  }

  // Get data stream and start the stopwatch timer if it is not already running
  var data = await getDataStream();
  if(!stopWatch.isRunning) {
    stopWatch.start();
  }

  // Decode the received data as JSON and check if feedback is active
  var decodedData = jsonDecode(data);
  if (decodedData['feedback_active'] == 'Yes') {
    feedbackActive = true;
    notifyListeners(); // Notify listeners if any
  } else {
    feedbackActive = false;
    notifyListeners(); // Notify listeners if any
  }

  // Loop through each imu in imus and each data type in dataTypes
  for (var imu in imus) {
    dataTypes.forEach((key, value) async {
      for (var type in value) {
        // Check if decoded data for the current imu and data type is null
        if(decodedData[imu] == null) {
          continue;
        }

        // Extract data from the decoded data and add it to the data buffer
        var strList = decodedData[imu][type]
            .toString()
            .replaceAll(RegExp(r'[\[\],]'), '')
            .split(' ')
            .toList();

        var rawDataList = strList
            .map((x) => double.parse(x))
            .toList();

        dataBuffer[imu][type].add(rawDataList);

        // If the pause flag is not set in playPauseProvider, add data to the checkpoint buffer
        if(!ref.read(playPauseProvider).pause) {
          checkpointDataBuffer[imu][type].add(rawDataList);
        }
      }
    });
  }

  // If filename is not null, write the data to a file
  if(filename != null) {
    await writeData();
  }

  notifyListeners(); // Notify listeners if any
}

Future writeData() async {
  if(stop) {
    return;
  }

  // Create a new row of data that contains the data from each buffer and the elapsed time from the stopwatch
  List row = [];
  String csv = '';
  dataBuffer.forEach((imu, types) {
    row.add(imu);
    types.forEach((type, dataDeque) {
      row.add(dataDeque.q.last);
    });
  });
  row.add(stopWatch.elapsedMilliseconds / 1000);

  await m.protect(() async {
    // Write the row of data to a file in CSV format
    var outputFile = File(filename!);
    csv = const ListToCsvConverter().convert([row]);
    try {
      await outputFile.writeAsString('$csv\n', mode: FileMode.append);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  });
}

// A provider class that maintains a list of IMUs and their associated feedbacks
class IMUsListProvider extends ChangeNotifier {
List imus = [];
List feedbacks = [];

// Update the list of IMUs and feedbacks and notify listeners
void updateList(List imus, List feedbacks) {
this.imus = imus;
this.feedbacks = feedbacks;
notifyListeners();
}
}

// A provider class that maintains a dictionary of data types for each IMU
class DataTypes extends ChangeNotifier {
Map types = {};

// Update the dictionary of data types and notify listeners
void updateDict(Map types) {
this.types = types;
notifyListeners();
}
}

// A provider class that maintains a boolean value indicating whether to pause or play data streaming
class PlayPause extends ChangeNotifier {
bool pause = false;

// Toggle the pause value and notify listeners
void playPause() {
pause = !pause;
notifyListeners();
}
}

// A provider class that manages the chosen algorithm
class AlgListManager extends ChangeNotifier {
String chosenAlg = '';
Ref ref;

AlgListManager(this.ref);

// Clear the chosen algorithm and notify listeners
void clearChosenAlg() {
chosenAlg = '';
notifyListeners();
}

// Set the chosen algorithm and notify listeners
void setChosenAlg(String alg) {
chosenAlg = alg;
ref.read(requestAnswerProvider).setCurAlg();
notifyListeners();
}
}

// A provider class that maintains a count of the number of IMUs
class IMUsCounter extends ChangeNotifier {
int imuCount = 0;

// Increment the IMU count and notify listeners
void inc() {
imuCount += 1;
notifyListeners();
}

// Set the IMU count to a specific value and notify listeners
void setImuCount(int n) {
imuCount = n;
}

// Decrement the IMU count and notify listeners
void dec() {
imuCount -= 1;
notifyListeners();
}
}

// A provider class that provides functions to check the height, width and narrowness of a screen
class ShortTall extends ChangeNotifier {

// Check if the height of the screen is less than or equal to a certain height
bool isShort(BuildContext context) {
return MediaQuery.of(context).size.height <= shortHeight;
}

// Get the height of the screen
double getHeight(BuildContext context) {
return MediaQuery.of(context).size.height;
}

// Get the width of the screen
double getWidth(BuildContext context) {
return MediaQuery.of(context).size.width;
}

// Check if the width of the screen is less than or equal to a certain width
bool isNarrow(BuildContext context) {
return MediaQuery.of(context).size.width <= narrowWidth;
}
}

// A ChangeNotifier class that manages a backend process.
class BackendProcessHandler extends ChangeNotifier {
  String pythonScriptPath = '';
  late Process process;
  bool running = false;

  // Starts the backend process.
  Future<void> startBackendProcess() async {
    if (pythonScriptPath.isEmpty) {
      pythonScriptPath = await getPythonScriptPath();
      // print(pythonScriptPath);
    }

    process = await Process.start(
      'python',
      [pythonScriptPath],
    );
    running = true;
  }

  // Closes the backend process.
  bool closeBackendProcess() {
    running = false;
    return process.kill();
  }

  // Disposes the backend process.
  @override
  void dispose() {
    process.kill();
    super.dispose();
  }
}

// A ChangeNotifierProvider for BackendProcessHandler.
final backendProcessHandler = ChangeNotifierProvider((ref) {
  return BackendProcessHandler();
});

// A ChangeNotifier class that manages the data types used in the app.
class DataTypes extends ChangeNotifier {
  Map types = {};

  // Updates the types.
  void updateDict(Map types) {
    this.types = types;
    notifyListeners();
  }
}

// A ChangeNotifierProvider for DataTypes.
final dataTypesProvider = ChangeNotifierProvider((ref) {
  return DataTypes();
});

// A ChangeNotifier class that manages the list of IMUs and feedbacks.
class IMUsListProvider extends ChangeNotifier {
  List imus = [];
  List feedbacks = [];

  // Updates the list of IMUs and feedbacks.
  void updateList(List imus, List feedbacks) {
    this.imus = imus;
    this.feedbacks = feedbacks;
    notifyListeners();
  }
}

// A ChangeNotifierProvider for IMUsListProvider.
final imusListProvider = ChangeNotifierProvider((ref) {
  return IMUsListProvider();
});

// A ChangeNotifier class that determines whether the screen is short or tall.
class ShortTall extends ChangeNotifier {
  bool isShort(BuildContext context) {
    return MediaQuery.of(context).size.height <= shortHeight;
  }

  double getHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  bool isNarrow(BuildContext context) {
    return MediaQuery.of(context).size.width <= narrowWidth;
  }
}

// A ChangeNotifierProvider for ShortTall.
final shortTallProvider = ChangeNotifierProvider((ref) {
  return ShortTall();
});

// A ChangeNotifier class that keeps track of the number of IMUs.
class IMUsCounter extends ChangeNotifier {
  int imuCount = 0;

  // Increments the IMU count.
  void inc() {
    imuCount += 1;
    notifyListeners();
  }

  // Sets the IMU count to a specific value.
  void setImuCount(int n) {
    imuCount = n;
  }

  // Decrements the IMU count.
  void dec() {
    imuCount -= 1;
    notifyListeners();
  }
}

// A ChangeNotifierProvider for IMUsCounter.
final imusCounter = ChangeNotifierProvider((ref) {
  return IMUsCounter();
});

// A ChangeNotifier class that manages the play/pause state of the app.
class PlayPause extends ChangeNotifier {
  bool pause = false;

  // Toggles the play/pause state.
  void playPause() {
    pause = !pause;
    notifyListeners();
  }
}

// A ChangeNotifierProvider for PlayPause.
final playPauseProvider = ChangeNotifierProvider((ref) {
  return PlayPause();
});

// A provider that returns a new instance of RequestHandler
final requestAnswerProvider = ChangeNotifierProvider((ref) {
  return RequestHandler(ref);
});

// A provider that returns a new instance of AlgListManager
final chosenAlgorithmProvider = ChangeNotifierProvider((ref) {
  return AlgListManager(ref);
});

// A provider that returns a new instance of DataProvider
final dataProvider = ChangeNotifierProvider((ref) {
  return DataProvider(ref);
});
