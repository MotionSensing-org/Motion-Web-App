import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_project/LandingPage/requests.dart';
import 'package:mutex/mutex.dart';

const narrowWidth = 650;
const shortHeight = 650;


class TextFieldClass{
  TextEditingController controller = TextEditingController();
  String imuMac;

  TextFieldClass({required this.controller, this.imuMac='88:6B:0F:E1:D8:68'});
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
  String url = '';
  String query = "?request_type=";
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

  RequestHandler(this.ref);

  void setServerAddress(String serverAddress) {
    url = serverAddress;
    ref.read(dataProvider).setServerAddress(url);
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

  void setQuery(String query) {
    this.query = "?request_type=$query";
  }

  Future<Map> getDecodedData() async {
    var data = await getData(Uri.parse(url + query));
    return jsonDecode(data);
  }

  Future<bool> getAlgList() async {
    query = '?request_type=algorithms';
    Map data = await getDecodedData();
    algorithms = data['algorithms'];
    notifyListeners();
    return true;
  }

  Future<bool> getAlgParams() async {
    query = '?request_type=get_params';
    Map data = await getDecodedData();
    curAlgParams = data['params'];
    notifyListeners();
    return true;
  }

  Future<bool> getCurAlg() async {
    query = '?request_type=get_cur_alg';
    Map data = await getDecodedData();
    curAlg = data['cur_alg'];
    ref.read(dataProvider).curAlg = curAlg;
    notifyListeners();
    return true;
  }

  Future<bool> getDataTypes() async {
    query = '?request_type=get_data_types';
    Map data = await getDecodedData();
    dataTypes = data['data_types'];
    ref.read(dataProvider).dataTypes = dataTypes;

    ref.read(dataTypesProvider).updateDict(dataTypes);
    return true;
  }

  Future setCurAlg() async {
    var body = json.encode(ref.read(chosenAlgorithmProvider).chosenAlg);
    await setServerParams(Uri.parse('$url?request_type=set_cur_alg'), body);
    return;
  }

  Future setAlgParams() async {
    var body = json.encode(paramsToSet);
    await setServerParams(Uri.parse(url+query), body);
    return;
  }

  Future connectToIMUs(Map<String, List<TextFieldClass>> addedIMUs) async {
    Map<String, List<String>> addedIMUSStrings = {
      'imus': addedIMUs['imus']!.map((e) => e.imuMac).toList(),
      'feedbacks': addedIMUs['feedbacks']!.map((e) => e.imuMac).toList()
    };
    var body = json.encode(addedIMUSStrings);
    return await setServerParams(Uri.parse('$url?request_type=set_imus'), body);
  }
}

class DataProvider extends ChangeNotifier {
  late String url;
  String curAlg = '';
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
    t = Timer.periodic(const Duration(milliseconds: 20), updateDataSource);
  }

  @override
  void dispose() {
    t.cancel();
    super.dispose();
  }

  void setServerAddress(String serverAddress) {
    url = serverAddress;
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

    var data = await getData(Uri.parse('$url?request_type=$curAlg'));
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

  void setChosenAlg(String alg) {
    chosenAlg = alg;
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
  return AlgListManager();
});

final dataProvider = ChangeNotifierProvider((ref) {
  return DataProvider(ref);
});