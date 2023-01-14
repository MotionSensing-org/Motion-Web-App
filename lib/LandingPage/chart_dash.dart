import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'requests.dart';
import 'dart:convert';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:async';
import 'dart:collection';
import 'package:csv/csv.dart';

const narrowWidth = 680;

class RawData {
  int timeStep;
  double value;

  RawData(this.timeStep, this.value);
  set setTimeStep(int t) {
    timeStep = t;
  }
}

// if(saveFile) {
//   var status = await Permission.storage.status;
//   if (!status.isGranted) {
//     await Permission.storage.request();
//   }
//
//   if (await Permission.storage.request().isGranted) {
//     try {
//       var outputFile = await setOutputFileName('test');
//
//       row.add(imu);
//       row.addAll(rawDataList);
//       String csv = const ListToCsvConverter().convert([row]);
//       outputFile.writeAsString(csv);
//     } catch (e) {
//       print(e);
//     }
//   }
//
// }

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
  final int bufferSize = 500;

  RequestHandler(this.url, this.ref) {
    Timer.periodic(const Duration(milliseconds: 100), updateDataSource);
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

  Future<bool> getImus() async {
    query = '?request_type=get_imus';
    Map data = await getDecodedData();
    imus = data['imus'];

    return true;
  }

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

    return true;
  }

  void updateData(String query) async {
    setQuery(query);
    switch (query) {
      case 'algorithms':
        getAlgList();
        break;
      case 'raw_data':
        break;
    }
  }

  Map provideRawData(String imu) {
    return checkpointDataBuffer[imu];
  }

  void updateDataSource(Timer timer) async {
    List row = [];
    List headers = [];

    if(algorithms.isEmpty) {
      await getAlgList();
      notifyListeners();
    }

    if(curAlgParams.isEmpty) {
      await getAlgParams();
      notifyListeners();
    }

    if(imus.isEmpty) {
      await getImus();
      notifyListeners();
    }

    if(curAlg == '') {
      await getCurAlg();
      notifyListeners();
    }

    if(dataTypes.isEmpty) {
      await getDataTypes();
      notifyListeners();
    }

    if(dataBuffer.isEmpty) {
      for (var imu in imus) {
        dataBuffer[imu] = {};
        dataTypes.forEach((key, value) {
          for (var type in value) {
            dataBuffer[imu][type] =
                Queue.from([for (var i = 0; i < bufferSize; i++) RawData(i, 0)]);
          }
        });
      }

      dataBuffer.forEach((imu, imuData) {
        checkpointDataBuffer[imu] = {};
        dataBuffer[imu].forEach((dataType, data) {
          checkpointDataBuffer[imu][dataType] = data.toList();
        });
      });
    }

    if(query == '?request_type=set_params') {
      var body = json.encode(paramsToSet);
      await setParams(Uri.parse(url+query), body);
      setQuery(curAlg);
      return;
    }

    if(stop) {
      return;
    }

    query = '?request_type=$curAlg';

    var data = await getData(Uri.parse(url + query));
    var decodedData = jsonDecode(data);
    for (var imu in imus) {
      row.add(imu);
      headers.add('IMU');
      dataTypes.forEach((key, value) async {
        for (var type in value) {
          headers.add(type);
          var strList = decodedData[imu][type]
              .toString()
              .replaceAll(RegExp(r'[\[\],]'), '')
              .split(' ')
              .toList();
          // print('$type\n$strList');
          var rawDataList = strList
              .map((x) => RawData(strList.indexOf(x), double.parse(x)))
              .toList();
          for (int k = 0; k < rawDataList.length; k++) {
            rawDataList[k].setTimeStep = k;
          }
          // print(strList);
          // print(type);
          dataBuffer[imu][type].addAll(rawDataList);
          row.add(strList.last);

          while (dataBuffer[imu][type].length > 500) {
            dataBuffer[imu][type].removeFirst();
          }
        }
      });

      if(!ref.read(playPauseProvider).pause) {
        dataBuffer.forEach((imu, imuData) {
          dataBuffer[imu].forEach((dataType, data) {
            checkpointDataBuffer[imu][dataType] = data.toList();
          });
        });
      }
    }

    if(filename != null) { //Should write output to disk
      if (outputFile == null) { //Output file was not created yet
        var status = await Permission.storage.status;

        if (!status.isGranted) {
          await Permission.storage.request();
        }

        if (await Permission.storage.request().isGranted) {
          try {
            outputFile = await File(filename!).create(recursive: true);
            String csv = const ListToCsvConverter().convert([headers, row]);
            row.clear();
            outputFile?.writeAsString('$csv\n');
          } catch (e) {
            // print(e);
          }
        }
      } else {
        String csv = const ListToCsvConverter().convert([row]);
        outputFile?.writeAsString('$csv\n', mode: FileMode.append);
      }
    }

    // else {
    //   String csv = const ListToCsvConverter().convert([[row]]);
    //   outputFile?.writeAsString('$csv\n', mode: FileMode.append);
    // }

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

class IMUManager extends ChangeNotifier {
  List<String> imus = [];
  List<String> feedbacks = [];

  void addIMU(String imu, {bool isFeedback = false}) {
    if(isFeedback) {
      feedbacks.add(imu);
    } else {
      imus.add(imu);
    }
    print(imus);
    print(feedbacks);
  }

  List<String> getIMUs({bool isFeedback=false}) {
    if(isFeedback) {
      return List.from(feedbacks);
    }

    return List.from(imus);
  }
}

final imusProvider = ChangeNotifierProvider((ref) {
  return IMUManager();
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

class DataChart extends ConsumerStatefulWidget{
  final String imu;
  final String dataType;
  final bool isMainChart;
  final Color mainChartColor;
  @override
  ConsumerState<DataChart> createState() => _DataChart();
  const DataChart({Key? key, required this.imu, required this.dataType,  this.isMainChart=false,  this.mainChartColor=Colors.white}) : super(key: key);
}

class _DataChart extends ConsumerState<DataChart> {
  // final TooltipBehavior _tooltipBehavior = TooltipBehavior(enable: true);
  final _zoomPanBehavior =
  ZoomPanBehavior(enableMouseWheelZooming: true, enablePanning: true);
  Map dataTypes = {};

  @override
  Widget build(BuildContext context) {
    dataTypes = ref.watch(requestAnswerProvider).dataTypes;
    var rawDataSource = ref.watch(requestAnswerProvider).provideRawData(widget.imu);
    List<ChartSeries<dynamic, dynamic>> series = [];
    for(var subType in dataTypes[widget.dataType]) {
      series.add(
          SplineSeries(
              dataSource: rawDataSource[subType].toList(),
              name: subType,
              enableTooltip: true,
              animationDuration: 0,
              xValueMapper: (dynamic rD, _) => rD.timeStep,
              yValueMapper: (dynamic rD, _) => rD.value
          )
      );
    }

    if(widget.isMainChart) {
      return Card(
        // elevation: 20,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        color: widget.mainChartColor,
        child: SfCartesianChart(
          title: ChartTitle(
              text: widget.dataType
          ),
          legend: Legend(isVisible: true),
          zoomPanBehavior: _zoomPanBehavior,
          // tooltipBehavior: _tooltipBehavior,
          series: series,
          primaryXAxis:
          NumericAxis(edgeLabelPlacement: EdgeLabelPlacement.shift),
        ),
      );
    }

    return SfCartesianChart(
      title: ChartTitle(
          text: widget.dataType
      ),
      legend: Legend(isVisible: true),
      zoomPanBehavior: _zoomPanBehavior,
      // tooltipBehavior: _tooltipBehavior,
      series: series,
      primaryXAxis:
      NumericAxis(edgeLabelPlacement: EdgeLabelPlacement.shift),
    );
  }
}

class ChartDash extends ConsumerStatefulWidget{
  final String imu;
  const ChartDash({required this.imu, super.key});

  @override
  ConsumerState<ChartDash> createState() => _ChartDash();
}

class _ChartDash extends ConsumerState<ChartDash> {
  DataChart? mainChart;
  int _key = 1;
  Color highlightedBorder = Colors.lightBlueAccent.shade100;
  late List algorithms;
  String? dropdownValue='';
  Map dataTypes = {};
  List tapped = [];
  List types = [];

  Widget createStackOrList(BuildContext context, BoxConstraints constraints) {
    var height = constraints.maxHeight;
    var width = constraints.maxWidth;

    if(MediaQuery.of(context).size.width > narrowWidth) {
      return Stack(
        children: List.generate(tapped.length, (i) {
          return AnimatedPositioned(
            top: tapped[i] ? 0 : height * 0.65,
            bottom: tapped[i] ? height * 0.35 : 0,
            // height: tapped[i] ? 0.75 * height : 0.25 * height,
            left: tapped[i] ? 0 : (i * width / tapped.length),
            // right: tapped[i] ? 0 : ((tapped.length - i - 1) * width / tapped.length),
            width: tapped[i] ? width : width / tapped.length,
            duration: const Duration(milliseconds: 900),
            curve: Curves.fastOutSlowIn,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  for(int j = 0; j < tapped.length; j++) {
                    if(j == i) {
                      tapped[j] = !tapped[j];
                    } else {
                      tapped[j] = false;
                    }
                  }

                  // if(tapped[i]) {
                  //   bringToTheTopOfStack(i);
                  // }
                });
              },
              child: Card(
                color: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Expanded(child: DataChart(imu: widget.imu, dataType: types[i], key: ValueKey(_key))),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      );
    }

    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      var size = min(constraints.maxWidth, constraints.maxHeight);
      return ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemCount: types.length,
          itemBuilder: (BuildContext context, int index) {
            return Container(
              width: size,
              height: size,
              child: Card(
                color: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Expanded(child: DataChart(imu: widget.imu, dataType: types[index], key: ValueKey(_key))),
                    ],
                  ),
                ),
              ),
            );
          }
      );
    });

  }

  @override
  Widget build(BuildContext context) {
    dataTypes = ref.watch(requestAnswerProvider).dataTypes;
    if(types.isEmpty && dataTypes.isNotEmpty) {
      types = dataTypes.keys.toList();
      tapped = List.generate(types.length, (index) => false);
    }

    return LayoutBuilder(
      builder: createStackOrList,
    );
  }
}
