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
  String url;
  String query = "?request_type=";
  String curAlg = '';
  List algorithms = [];
  List curAlgParams = [];
  List imus = [];
  Map paramsToSet = {};
  Map dataBuffer = {};
  Ref ref;
  Map checkpointDataBuffer = {};
  Map dataTypes = {};
  String? filename;
  File? outputFile;
  bool stop = true;
  bool createdFile = false;
  bool saveFile = true;
  bool shouldInitBuffers = false;
  int iterationNumber = 0;
  bool headersInitialized = false;
  bool printedHeaders = false;
  bool connectionSuccess = false;
  final int bufferSize = 500;
  int curBufferSize = 0;
  final int writeLength = 100;
  Mutex m = Mutex();
  List<List> rows = [];
  int cyclicIterationNumber = -1;
  int initializedChartControllers = 0;
  int dataTypesCount = 0;
  final stopWatch = Stopwatch();

  RequestHandler(this.url, this.ref) {
    Timer.periodic(const Duration(milliseconds: 50), updateDataSource);
  }

  void setServerAddress(String serverAddress) {
    url = serverAddress;
  }

  void connectionSuccessful(bool success) {
    connectionSuccess = success;
  }

  bool isConnected() {
    return connectionSuccess;
  }

  void increaseControllerCount() {
    initializedChartControllers += 1;
  }

  void setParamsMap(Map params) {
    paramsToSet = params;
  }

  void setQuery(String query) {
    this.query = "?request_type=$query";
  }

  void startStopDataCollection({bool stop=true}) {
    this.stop = stop;
    outputFile = null;
  }

  Future<Map> getDecodedData() async {
    var data = await getData(Uri.parse(url + query));
    return jsonDecode(data);
  }

  Future<bool> getAlgList() async {
    query = '?request_type=algorithms';
    Map data = await getDecodedData();
    algorithms = data['algorithms'];

    return true;
  }

  // Future<bool> getImus() async {
  //   query = '?request_type=get_imus';
  //   Map data = await getDecodedData();
  //   imus = data['imus'];
  //   ref.read(imusListProvider).imus = imus;
  //
  //   return true;
  // }

  Future<bool> getAlgParams() async {
    query = '?request_type=get_params';
    Map data = await getDecodedData();
    curAlgParams = data['params'];

    return true;
  }

  Future<bool> getCurAlg() async {
    query = '?request_type=get_cur_alg';
    Map data = await getDecodedData();
    curAlg = data['cur_alg'];

    return true;
  }

  Future<bool> getDataTypes() async {
    query = '?request_type=get_data_types';
    Map data = await getDecodedData();
    dataTypes = data['data_types'];

    ref.read(dataTypesProvider).updateDict(dataTypes);
    return true;
  }

  Map provideRawData(String imu) {
    return checkpointDataBuffer[imu];
  }

  void initBuffersAndTypesCounter() {
    dataBuffer = {};
    checkpointDataBuffer = {};
    dataTypes.forEach((key, value) {
      dataTypesCount += value.length as int;
    });

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

  Future setCurAlg() async {
    var body = json.encode(ref.read(chosenAlgorithmProvider).chosenAlg);
    await setServerParams(Uri.parse('${url}?request_type=set_cur_alg'), body);
    // setQuery(curAlg);
    return;
  }

  void updateDataSource(Timer timer) async {
    if(imus.isEmpty) {
      return;
    }

    if(algorithms.isEmpty) {
      await getAlgList();
      notifyListeners();
    }

    if(curAlgParams.isEmpty) {
      await getAlgParams();
      notifyListeners();
    }

    if(curAlg == '') {
      await getCurAlg();
      notifyListeners();
    }

    if(dataTypes.isEmpty) {
      await getDataTypes();
      // notifyListeners();
    }

    if(query == '?request_type=set_params') {
      var body = json.encode(paramsToSet);
      await setServerParams(Uri.parse(url+query), body);
      setQuery(curAlg);
      return;
    }

    if(dataBuffer.isEmpty || shouldInitBuffers) {
      initBuffersAndTypesCounter();
      shouldInitBuffers = false;
    }

    if(stop) {
      stopWatch.stop();
      stopWatch.reset();
      return;
    }

    query = '?request_type=$curAlg';
    var data = await getData(Uri.parse(url + query));
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
            // if(checkpointDataBuffer[imu][type].q.length == bufferSize) {
            //   if(chartControllers[imu]?[type] != null) {
            //     chartControllers[imu]?[type]?.updateDataSource(
            //         addedDataIndex: checkpointDataBuffer[imu][type].q.length - 1,
            //         updatedDataIndexes: List.generate(checkpointDataBuffer[imu][type].q.length - 2, (index) => index + 1),
            //         removedDataIndex: 0);
            //   }
            //
            // }
            // else {
            //   chartControllers[imu]?[type]?.updateDataSource(
            //       addedDataIndex: checkpointDataBuffer[imu][type].q.length - 1);
            // }
          }
        }
      });
    }

    // cyclicIterationNumber = (cyclicIterationNumber + 1) % bufferSize;
    if(filename != null) { //Should write output to disk
      await writeData();
    }

    // else {
    //   String csv = const ListToCsvConverter().convert([[row]]);
    //   outputFile?.writeAsString('$csv\n', mode: FileMode.append);
    // }
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
        // print('q length: ${dataDeque.q.length}');
      });
      row.add(stopWatch.elapsedMilliseconds / 1000);
    });



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

  Future connectToIMUs(Map<String, List<TextFieldClass>> addedIMUs) async {
    Map<String, List<String>> addedIMUSStrings = {
      'imus': addedIMUs['imus']!.map((e) => e.imuMac).toList(),
      'feedbacks': addedIMUs['feedbacks']!.map((e) => e.imuMac).toList()
    };
    // imus = addedIMUSStrings['imus']!;
    var body = json.encode(addedIMUSStrings);
    // var body = json.encode({'imus': ['8889989'], 'feedbacks': []});
    print('server url: $url');
    return await setServerParams(Uri.parse('$url?request_type=set_imus'), body);
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
    print('imu count: $imuCount');
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
  return RequestHandler('http://127.0.0.1:8080/', ref);
});

final chosenAlgorithmProvider = ChangeNotifierProvider((ref) {
  return AlgListManager();
});