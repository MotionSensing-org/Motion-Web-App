import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_project/LandingPage/providers.dart';
import 'dart:core';
import '../data_chart.dart';

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
  Map dataTypes = {};

  @override
  Widget build(BuildContext context) {
    dataTypes = ref.watch(dataTypesProvider).types;
    var rawDataSource = ref.watch(dataProvider).provideRawData(widget.imu);
    List series = [];
    List<String> labels = [];

    for(var subType in dataTypes[widget.dataType]) {
      series.add(
          rawDataSource[subType].q
      );
      labels.add(subType);
    }

    return BaseDataChart(linesData: series, labels: labels, title: widget.dataType,);
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
  List canSwitchToChart = [];
  List types = [];

  Widget createStack(BuildContext context, BoxConstraints constraints) {
    var height = constraints.maxHeight;
    var width = constraints.maxWidth;
    bool isShort = ref.watch(shortTallProvider).isShort(context);
    bool isNarrow = ref.watch(shortTallProvider).isNarrow(context);

    return SizedBox(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(tapped.length, (i) {
          double largeChartHeight = (isShort || isNarrow ? height * 0.9 : height * 0.65);
          double chartHeight = (isShort || isNarrow ? height * 0.1 : height * 0.35);
          double chartWidth = (isShort || isNarrow ? width * 0.2 : width / tapped.length);
          double chartLeft = tapped[i] ? 0 : (i * chartWidth);

          return AnimatedPositioned(
            onEnd: () {
              setState(() {
                if(tapped[i]) {
                  canSwitchToChart[i] = true;
                }
              });
            },
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
                      if(!tapped[j]) {
                        canSwitchToChart[j] = false;
                      }
                    } else {
                      tapped[j] = false;
                      canSwitchToChart[j] = false;
                    }
                  }
                });
              },
              child: Card(
                color: Colors.black.withOpacity(0.7),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                child: Center(
                  child: AnimatedCrossFade(
                    crossFadeState: (!isNarrow && !isShort) || canSwitchToChart[i]
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Visibility(
                      visible: !canSwitchToChart[i],
                      child: Tooltip(
                        message: types[i],
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.fill,
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(2.0),
                                    child: Icon(Icons.show_chart_rounded ,color: Colors.white,),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Text(types[i], style: const TextStyle(color: Colors.white),),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    secondChild: Visibility(
                      visible: canSwitchToChart[i] || (!isNarrow && !isShort),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: DataChart(imu: widget.imu, dataType: types[i], key: ValueKey(_key)),
                      ),
                    ),
                    duration: const Duration(milliseconds: 500),
                    reverseDuration: const Duration(milliseconds: 50),
                    firstCurve: Curves.easeIn,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    dataTypes = ref.watch(dataTypesProvider).types;
    if(types.isEmpty && dataTypes.isNotEmpty) {
      types = dataTypes.keys.toList();
      tapped = List.generate(types.length, (index) => false);
      canSwitchToChart = List.generate(tapped.length, (i) => false);
    }

    return LayoutBuilder(
      builder: createStack,
    );
  }
}
