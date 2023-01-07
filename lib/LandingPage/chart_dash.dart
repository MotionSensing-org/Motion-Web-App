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

    query = '?request_type=$curAlg';

    var data = await getData(Uri.parse(url + query));
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

    mainChart ??= DataChart(imu: widget.imu, dataType: types[0], key: ValueKey(_key), isMainChart: true, mainChartColor: Colors.white,);
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
                              duration: const Duration(milliseconds: 400),
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
                                          mainChart = DataChart(
                                            imu: widget.imu,
                                            dataType: types[i],
                                            key: ValueKey(_key),
                                            isMainChart: true,
                                            mainChartColor: Colors.white,);
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
