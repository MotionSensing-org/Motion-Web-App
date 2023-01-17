import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'requests.dart';
import 'dart:convert';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:async';
import 'dart:collection';
import 'package:csv/csv.dart';

const narrowWidth = 650;
const shortHeight = 650;


class TextFieldClass{
  TextEditingController controller = TextEditingController();
  String imuMac;

  TextFieldClass({required this.controller, this.imuMac='88:6B:0F:E1:D8:68'});
}

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
  String? filename;
  File? outputFile;
  bool stop = true;
  bool createdFile = false;
  bool saveFile = true;
  bool shouldInitBuffers = false;
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

  void initBuffers() {
    dataBuffer = {};
    checkpointDataBuffer = {};
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

  void updateDataSource(Timer timer) async {
    List row = [];
    List headers = [];

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

    // if(imus.isEmpty) {
    //   await getImus();
    //   notifyListeners();
    // }

    if(curAlg == '') {
      await getCurAlg();
      notifyListeners();
    }

    if(dataTypes.isEmpty) {
      await getDataTypes();
      notifyListeners();
    }



    if(query == '?request_type=set_params') {
      var body = json.encode(paramsToSet);
      await setParams(Uri.parse(url+query), body);
      setQuery(curAlg);
      return;
    }

    if(dataBuffer.isEmpty || shouldInitBuffers) {
      initBuffers();
      shouldInitBuffers = false;
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
          if(decodedData[imu] == null) {
            continue;
          }

          headers.add(type);
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
            if (kDebugMode) {
              print(e);
            }
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

  Future connectToIMUs(Map<String, List<TextFieldClass>> addedIMUs) async {
    Map<String, List<String>> addedIMUSStrings = {
      'imus': addedIMUs['imus']!.map((e) => e.imuMac).toList(),
      'feedbacks': addedIMUs['feedbacks']!.map((e) => e.imuMac).toList()
    };
    // imus = addedIMUSStrings['imus']!;
    var body = json.encode(addedIMUSStrings);
    // var body = json.encode({'imus': ['8889989'], 'feedbacks': []});
    return await setParams(Uri.parse('$url?request_type=set_imus'), body);
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
  return RequestHandler('http://127.0.0.1:5000/', ref);
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
    dataTypes = ref.watch(dataTypesProvider).types;
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

    return SfCartesianChart(
      title: ChartTitle(
          text: widget.dataType,
          textStyle: const TextStyle(
            color: Colors.black,
            fontSize: 10
          )
      ),
      legend: Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
        position: LegendPosition.bottom,
      ),
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
  final int _key = 1;
  Color highlightedBorder = Colors.lightBlueAccent.shade100;
  late List algorithms;
  String? dropdownValue='';
  Map dataTypes = {};
  List tapped = [];
  List types = [];

  Widget createStack(BuildContext context, BoxConstraints constraints) {
    var height = constraints.maxHeight;
    var width = constraints.maxWidth;
    bool isShort = ref.watch(shortTallProvider).isShort(context);
    bool isNarrow = ref.watch(shortTallProvider).isNarrow(context);

    return Stack(
      alignment: Alignment.center,
      children: List.generate(tapped.length, (i) {
        double largeChartHeight = (isShort || isNarrow ? height * 0.9 : height * 0.6);
        double chartHeight = (isShort || isNarrow ? height * 0.1 : height * 0.4);
        double chartWidth = (isShort || isNarrow ? width * 0.2 : width / tapped.length);
        double chartLeft = tapped[i] ? 0 : (i * chartWidth);

        return AnimatedPositioned(
          top: tapped[i] ? 0 : largeChartHeight,
          bottom: tapped[i] ? chartHeight : 0,
          // height: tapped[i] ? 0.75 * height : 0.25 * height,
          left: chartLeft,
          // right: tapped[i] ? 0 : ((tapped.length - i - 1) * width / tapped.length),
          width: tapped[i] ? width : chartWidth,
          duration: const Duration(milliseconds: 700),
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
            child: AnimatedCrossFade(
              crossFadeState: (!isNarrow && !isShort) || tapped[i]
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Tooltip(
                message: types[i],
                child: Card(
                  color: Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(Icons.show_chart_rounded),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Text(types[i]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              secondChild: Card(
                color: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DataChart(imu: widget.imu, dataType: types[i], key: ValueKey(_key)),
                ),
              ),
              duration: const Duration(milliseconds: 500),
              reverseDuration: const Duration(milliseconds: 50),
              firstCurve: Curves.easeIn,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    dataTypes = ref.watch(dataTypesProvider).types;
    if(types.isEmpty && dataTypes.isNotEmpty) {
      types = dataTypes.keys.toList();
      tapped = List.generate(types.length, (index) => false);
    }

    return LayoutBuilder(
      builder: createStack,
    );
  }
}
