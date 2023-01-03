import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'requests.dart';
import 'dart:convert';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:async';
import 'dart:collection';

class RawData {
  int timeStep;
  double value;

  RawData(this.timeStep, this.value);
  set setTimeStep(int t) {
    timeStep = t;
  }
}

// IMU request types:
//   "raw_data"
// TODO: add algorithm requests
class RequestHandler extends ChangeNotifier {
  String url;
  String query = "?request_type=";
  List algorithms = [];
  List curAlgParams = [];
  List imus = [];
  Map paramsToSet = {};
  Map dataBuffer = {};
  Ref ref;
  Map checkpointDataBuffer = {};
  Map dataTypes = {};
  final int bufferSize = 500;

  RequestHandler(this.url, this.ref) {
    getAlgList();
    // dataBuffer["ACC0-X"] =
    //     Queue.from([for (var i = 0; i < bufferSize; i++) RawData(i, 0)]);
    // dataBuffer["ACC0-Y"] =
    //     Queue.from([for (var i = 0; i < bufferSize; i++) RawData(i, 0)]);
    // dataBuffer["ACC0-Z"] =
    //     Queue.from([for (var i = 0; i < bufferSize; i++) RawData(i, 0)]);
    //
    // dataBuffer["GYRO0-X"] =
    //     Queue.from([for (var i = 0; i < bufferSize; i++) RawData(i, 0)]);
    // dataBuffer["GYRO0-Y"] =
    //     Queue.from([for (var i = 0; i < bufferSize; i++) RawData(i, 0)]);
    // dataBuffer["GYRO0-Z"] =
    //     Queue.from([for (var i = 0; i < bufferSize; i++) RawData(i, 0)]);
    //
    // dataBuffer.forEach((key, value) {
    //   checkpointDataBuffer[key] = value.toList();
    // });

    Timer.periodic(const Duration(milliseconds: 100), updateDataSource);
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
    if(algorithms.isEmpty) {
      getAlgList();
      notifyListeners();
    }

    if(curAlgParams.isEmpty) {
      getAlgParams();
      notifyListeners();
    }

    if(imus.isEmpty) {
      getImus();
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

      // for (var type in dataTypes) {
      //   dataBuffer[type] =
      //       Queue.from([for (var i = 0; i < bufferSize; i++) RawData(i, 0)]);
      // }

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
      setQuery('raw_data');
      return;
    }

    query = '?request_type=raw_data';

    var data = await getData(Uri.parse(url + query));
    // var types = ['ACC', 'GYRO'];
    // var axis = ['X', 'Y', 'Z'];
    var decodedData = jsonDecode(data);
    for (var imu in imus) {
      dataTypes.forEach((key, value) {
        for (var type in value) {
          var strList = decodedData[imu][type]
              .toString()
              .replaceAll(RegExp(r'[\[\],]'), '')
              .split(' ')
              .toList();
          var rawDataList = strList
              .map((x) => RawData(strList.indexOf(x), double.parse(x)))
              .toList();
          for (int k = 0; k < rawDataList.length; k++) {
            rawDataList[k].setTimeStep = k;
          }

          dataBuffer[imu][type].addAll(rawDataList);
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

    notifyListeners();

    // for (int i = 0; i < 2; i++) {
    //   for (int j = 0; j< 3; j++) {
    //     var strList = decodedData['0']['${types[i]}-${axis[j]}']
    //         .toString()
    //         .replaceAll(RegExp(r'[\[\],]'), '')
    //         .split(' ')
    //         .toList();
    //     var rawDataList = strList
    //         .map((x) => RawData(strList.indexOf(x), double.parse(x)))
    //         .toList();
    //     for (int k = 0; k < rawDataList.length; k++) {
    //       rawDataList[k].setTimeStep = k;
    //     }
    //
    //     dataBuffer['${types[i]}-${axis[j]}'].addAll(rawDataList);
    //     while (dataBuffer['${types[i]}-${axis[j]}'].length > 500) {
    //       dataBuffer['${types[i]}-${axis[j]}'].removeFirst();
    //     }
    //   }
    //
    //   if(!ref.read(playPauseProvider).pause) {
    //     dataBuffer.forEach((key, value) {
    //       checkpointDataBuffer[key] = value.toList();
    //     });
    //   }
    //
    //   notifyListeners();
    // }
  }
}

class PlayPause extends ChangeNotifier {
  bool pause = false;

  void playPause() {
    pause = !pause;
    notifyListeners();
  }
}

// class ChartCheckBox extends ChangeNotifier {
//   bool _isCheckedAcclX = true;
//   bool _isCheckedAcclY = true;
//   bool _isCheckedAcclZ = true;
//   bool _isCheckedGyroX = false;
//   bool _isCheckedGyroY = false;
//   bool _isCheckedGyroZ = false;
//
//   bool atLeastOneChecked() {
//     return _isCheckedAcclX ||  _isCheckedAcclY || _isCheckedAcclZ
//         || _isCheckedGyroX || _isCheckedGyroY || _isCheckedGyroZ;
//   }
//
//   void checkUncheck(String chartType) {
//     switch(chartType) {
//       case 'ACC0-X': {
//         _isCheckedAcclX = !_isCheckedAcclX;
//       }
//       break;
//
//       case 'ACC0-Y': {
//         _isCheckedAcclY = !_isCheckedAcclY;
//       }
//       break;
//
//       case 'ACC0-Z': {
//         _isCheckedAcclZ = !_isCheckedAcclZ;
//       }
//       break;
//
//       case 'GYRO0-X': {
//         _isCheckedGyroX = !_isCheckedGyroX;
//       }
//       break;
//
//       case 'GYRO0-Y': {
//         _isCheckedGyroY = !_isCheckedGyroY;
//       }
//       break;
//
//       case 'GYRO0-Z': {
//         _isCheckedGyroZ = !_isCheckedGyroZ;
//       }
//     }
//
//     notifyListeners();
//   }
// }

class AlgListManager extends ChangeNotifier {
  String chosenAlg = '';

  void setChosenAlg(String alg) {
    chosenAlg = alg;
    notifyListeners();
  }
}

// final checkBoxProvider = ChangeNotifierProvider((ref) {
//   return ChartCheckBox();
// });

final playPauseProvider = ChangeNotifierProvider((ref) {
  return PlayPause();
});

final requestAnswerProvider = ChangeNotifierProvider((ref) {
  return RequestHandler('http://127.0.0.1:5000/', ref);
});

final chosenAlgorithmProvider = ChangeNotifierProvider((ref) {
  return AlgListManager();
});

class DataChart extends ConsumerWidget {
  // final TooltipBehavior _tooltipBehavior = TooltipBehavior(enable: true);
  final _zoomPanBehavior =
  ZoomPanBehavior(enableMouseWheelZooming: true, enablePanning: true);
  final String imu;
  final String dataType;
  Map dataTypes = {};
  DataChart({Key? key, required this.imu, required this.dataType}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    dataTypes = ref.watch(requestAnswerProvider).dataTypes;
    var rawDataSource = ref.watch(requestAnswerProvider).provideRawData(imu);
    List<ChartSeries<dynamic, dynamic>> series = [];
    for(var subType in dataTypes[dataType]) {
      series.add(
          SplineSeries(
              dataSource: rawDataSource[subType].toList(),
              name: subType,
              enableTooltip: true,
              // onRendererCreated: (ChartSeriesController controller) {
              //   _chartSeriesController = controller;
              // },
              animationDuration: 0,
              xValueMapper: (dynamic rD, _) => rD.timeStep,
              yValueMapper: (dynamic rD, _) => rD.value
          )
      );
    }

    return Card(
      // elevation: 20,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      color: Colors.white,
      child: SfCartesianChart(
        title: ChartTitle(
            text: dataType
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
}

class ChartDash extends ConsumerStatefulWidget{
  final String imu;
  ChartDash({required this.imu, super.key});

  @override
  ConsumerState<ChartDash> createState() => _ChartDash();
}

class _ChartDash extends ConsumerState<ChartDash> {
  DataChart? mainChart;
  int _key = 1;
  List<Color> _dynamicBorders = [];
  Color highlightedBorder = Colors.lightBlueAccent.shade100;
  late List algorithms;
  String? dropdownValue='';
  Map dataTypes = {};

  Color getColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return Colors.blue;
    }
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    dataTypes = ref.watch(requestAnswerProvider).dataTypes;
    List types = dataTypes.keys.toList();
    if(_dynamicBorders.isEmpty) {
      _dynamicBorders = [for(int i = 0; i < types.length; i++) Colors.transparent];
      _dynamicBorders[0] = highlightedBorder;
    }

    mainChart ??= DataChart(imu: widget.imu, dataType: types[0], key: ValueKey(_key),);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: Colors.lightBlue,
          child: Column(
            // color: Colors.lightBlueAccent,
              children: [
                // Text(widget.imu),
                Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Flexible(
                          flex: 2,
                          child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 800),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return ScaleTransition(scale: animation, child: child);
                              },
                              child: mainChart
                          )
                      ),
                      Flexible(
                        flex: 1,
                        child: Card(
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                          elevation: 20,
                          color: Colors.lightBlueAccent,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
                                //PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                              },),
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  for(int i = 0; i< types.length; i++) GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _key = (_key == 2 ? 1 : 2);
                                          mainChart = DataChart(imu: widget.imu, dataType: types[i], key: ValueKey(_key));
                                          for (int j = 0; j < types.length; j++){
                                            if (j == i){
                                              _dynamicBorders[j] = highlightedBorder;
                                            } else {
                                              _dynamicBorders[j] = Colors.transparent;
                                            }
                                          }

                                        });
                                      },
                                      child: Column(
                                        children: [
                                          Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.all(16.0),
                                                child: AnimatedContainer(
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 6,
                                                            color: _dynamicBorders[i]
                                                        ) ,
                                                        borderRadius: const BorderRadius.all(Radius.circular(20)),
                                                        color: Colors.white
                                                    ),
                                                    duration: const Duration(milliseconds: 800),
                                                    child: DataChart(imu: widget.imu, dataType: types[i], key: ValueKey(_key))
                                                ),
                                              )
                                          ),
                                        ],
                                      )
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              )]
          )
        );
      },
    );
  }
}
