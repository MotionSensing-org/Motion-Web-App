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
  TextEditingController controller = TextEditingController();
  String imuMac;

  TextFieldClass({required this.controller, this.imuMac=exampleImuMac});
}

class Deque {
  List q = [];
  int maxSize;
  Deque({required this.maxSize});
  void add(List l) {
    q.addAll(l);
    if(q.length > maxSize) {
      q = q.skip(q.length - maxSize).toList();
    }
  }

  void clear() {
    q.clear();
  }
}

class RequestHandler extends ChangeNotifier {
  String curAlg = '';
  List algorithms = [];
  List curAlgParams = [];
  List imus = [];
  Map paramsToSet = {};
  Ref ref;
  Map dataTypes = {};
  String? filename;
  File? outputFile;
  bool stop = true;
  int iterationNumber = 0;
  bool connectionSuccess = false;
  Mutex m = Mutex();
  List<List> rows = [];
  int cyclicIterationNumber = -1;
  int dataTypesCount = 0;

  RequestHandler(this.ref) {
    Timer.periodic(const Duration(seconds: 4), keepAliveBackendConnection);
  }

  Future<void> keepAliveBackendConnection(Timer timer) async {
    if(connectionSuccess && ref.read(dataProvider).stop) {
      await getData(query: 'keepalive');
    }
  }

  void clearOutputFileName() {
    notifyListeners();
  }

  void connectionSuccessful(bool success) {
    connectionSuccess = success;
  }

  bool isConnected() {
    return connectionSuccess;
  }

  void setParamsMap(Map params) {
    paramsToSet = params;
  }

  Future<Map> getDecodedData(String query) async {
    var data = await getData(query: query);
    return jsonDecode(data);
  }

  Future<bool> getAlgList() async {
    Map data = await getDecodedData('algorithms');
    algorithms = data['algorithms'];
    notifyListeners();
    return true;
  }

  Future<bool> getAlgParams() async {
    Map data = await getDecodedData('get_params');
    curAlgParams = data['params'];
    notifyListeners();
    return true;
  }

  Future<bool> getCurAlg() async {
    Map data = await getDecodedData('get_cur_alg');
    curAlg = data['cur_alg'];
    notifyListeners();
    return true;
  }

  Future<bool> getDataTypes() async {
    Map data = await getDecodedData('get_data_types');
    dataTypes = data['data_types'];
    ref.read(dataProvider).dataTypes = dataTypes;

    ref.read(dataTypesProvider).updateDict(dataTypes);
    return true;
  }

  Future setCurAlg() async {
    var body = json.encode(ref.read(chosenAlgorithmProvider).chosenAlg);
    await writeToServer(query: 'set_cur_alg', body: body);
    return;
  }

  Future setAlgParams() async {
    var body = json.encode(paramsToSet);
    await writeToServer(query: 'set_params', body: body);
    return;
  }

  Future connectToIMUs(Map<String, List<TextFieldClass>> addedIMUs) async {
    Map<String, List<String>> addedIMUSStrings = {
      'imus': addedIMUs['imus']!.map((e) => e.imuMac).toList(),
      'feedbacks': addedIMUs['feedbacks']!.map((e) => e.imuMac).toList()
    };
    var body = json.encode(addedIMUSStrings);
    return await writeToServer(query: 'set_imus', body: body);
  }
}

class DataProvider extends ChangeNotifier {
  List imus = [];
  Map dataBuffer = {};
  Map checkpointDataBuffer = {};
  Map dataTypes = {};
  Ref ref;
  String? filename;
  bool stop = true;
  bool shouldInitBuffers = false;
  final int bufferSize = 500;
  Mutex m = Mutex();
  final stopWatch = Stopwatch();
  late Timer t;

  DataProvider(this.ref) {
    t = Timer.periodic(const Duration(milliseconds: 40), updateDataSource);
  }

  @override
  void dispose() {
    t.cancel();
    super.dispose();
  }

  void startStopDataCollection({bool stop=true}) {
    this.stop = stop;
  }

  Map provideRawData(String imu) {
    return checkpointDataBuffer[imu];
  }

  void initBuffersAndTypesCounter() {
    dataBuffer = {};
    checkpointDataBuffer = {};

    for (var imu in imus) {
      dataBuffer[imu] = {};
      checkpointDataBuffer[imu] = {};
      dataTypes.forEach((key, value) {
        for (var type in value) {
          dataBuffer[imu][type] =
              Deque(maxSize: bufferSize);
          checkpointDataBuffer[imu][type] =
              Deque(maxSize: bufferSize);
        }
      });
    }
  }

  void updateDataSource(Timer timer) async {
    if(imus.isNotEmpty && dataTypes.isNotEmpty && shouldInitBuffers) {
      initBuffersAndTypesCounter();
      shouldInitBuffers = false;
    }

    if(stop) {
      stopWatch.stop();
      stopWatch.reset();
      return;
    }

    var data = await getDataStream();
    if(!stopWatch.isRunning) {
      stopWatch.start();
    }

    var decodedData = jsonDecode(data);
    for (var imu in imus) {
      dataTypes.forEach((key, value) async {
        for (var type in value) {
          if(decodedData[imu] == null) {
            continue;
          }

          var strList = decodedData[imu][type]
              .toString()
              .replaceAll(RegExp(r'[\[\],]'), '')
              .split(' ')
              .toList();

          var rawDataList = strList
              .map((x) => double.parse(x))
              .toList();

          dataBuffer[imu][type].add(rawDataList);
          if(!ref.read(playPauseProvider).pause) {
            checkpointDataBuffer[imu][type].add(rawDataList);
          }
        }
      });
    }

    if(filename != null) { //Should write output to disk
      await writeData();
    }

    notifyListeners();
  }

  Future writeData() async {
    if(stop) {
      return;
    }

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
}

class IMUsListProvider extends ChangeNotifier {
  List imus = [];

  void updateList(List imus) {
    this.imus = imus;
    notifyListeners();
  }
}

class DataTypes extends ChangeNotifier {
  Map types = {};

  void updateDict(Map types) {
    this.types = types;
    notifyListeners();
  }
}

class PlayPause extends ChangeNotifier {
  bool pause = false;

  void playPause() {
    pause = !pause;
    notifyListeners();
  }
}

class AlgListManager extends ChangeNotifier {
  String chosenAlg = '';
  Ref ref;
  AlgListManager(this.ref);

  void clearChosenAlg() {
    chosenAlg = '';
    notifyListeners();
  }

  void setChosenAlg(String alg) {
    chosenAlg = alg;
    ref.read(requestAnswerProvider).setCurAlg();
    notifyListeners();
  }
}

class IMUsCounter extends ChangeNotifier {
  int imuCount = 0;
  void inc() {
    imuCount += 1;
    notifyListeners();
  }

  void dec() {
    imuCount -= 1;
    notifyListeners();
  }
}

class ShortTall extends ChangeNotifier {
  bool isShort(BuildContext context) {
    return MediaQuery.of(context).size.height <= shortHeight;
  }

  bool isNarrow(BuildContext context) {
    return MediaQuery.of(context).size.width <= narrowWidth;
  }
}

class BackendProcessHandler extends ChangeNotifier {
  String pythonScriptPath = '';
  late Process process;
  bool running = false;

  Future<void> startBackendProcess() async {
    if(pythonScriptPath.isEmpty) {
      pythonScriptPath = await getPythonScriptPath();
    }

    process = await Process.start(
      'python',
      [pythonScriptPath],
    );
    running = true;
  }

  bool closeBackendProcess() {
    running = false;
    return process.kill();
  }

  @override
  void dispose() {
    process.kill();
    super.dispose();
  }
}

final backendProcessHandler = ChangeNotifierProvider((ref) {
  return BackendProcessHandler();
});

final dataTypesProvider = ChangeNotifierProvider((ref) {
  return DataTypes();
});

final imusListProvider = ChangeNotifierProvider((ref) {
  return IMUsListProvider();
});

final shortTallProvider = ChangeNotifierProvider((ref) {
  return ShortTall();
});

final imusCounter = ChangeNotifierProvider((ref) {
  return IMUsCounter();
});

final playPauseProvider = ChangeNotifierProvider((ref) {
  return PlayPause();
});

final requestAnswerProvider = ChangeNotifierProvider((ref) {
  return RequestHandler(ref);
});

final chosenAlgorithmProvider = ChangeNotifierProvider((ref) {
  return AlgListManager(ref);
});

final dataProvider = ChangeNotifierProvider((ref) {
  return DataProvider(ref);
});