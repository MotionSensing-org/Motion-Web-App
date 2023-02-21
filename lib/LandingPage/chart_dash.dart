import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_project/LandingPage/providers.dart';
import 'dart:core';
import '../data_chart.dart';

// Define a class called DataChart that extends ConsumerStatefulWidget.
class DataChart extends ConsumerStatefulWidget{
  final String imu;
  final String dataType;
  final bool isMainChart;
  final Color mainChartColor;
  
  // Override the createState method to return an instance of _DataChart.
  @override
  ConsumerState<DataChart> createState() => _DataChart();
  
  // Define a constructor for the DataChart class.
  const DataChart({Key? key, required this.imu, required this.dataType,  this.isMainChart=false,  this.mainChartColor=Colors.white}) : super(key: key);
}

// Define a private class called _DataChart that extends ConsumerState.
class _DataChart extends ConsumerState<DataChart> {
  // Define a map called dataTypes.
  Map dataTypes = {};

  // Override the build method to return a BaseDataChart.
  @override
  Widget build(BuildContext context) {
    // Retrieve the dataTypes map from dataTypesProvider using ref.watch.
    dataTypes = ref.watch(dataTypesProvider).types;
    
    // Retrieve the raw data for the specified IMU using dataProvider.
    var rawDataSource = ref.watch(dataProvider).provideRawData(widget.imu);
    
    // Create an empty list called series.
    List series = [];
    
    // Create an empty list called labels.
    List<String> labels = [];

    // Loop through each subType in the dataTypes[widget.dataType] list.
    for(var subType in dataTypes[widget.dataType]) {
      // Add the q property of the current subType to the series list.
      series.add(rawDataSource[subType].q);
      
      // Add the current subType to the labels list.
      labels.add(subType);
    }

    // Return a BaseDataChart widget with the specified properties.
    return BaseDataChart(linesData: series, labels: labels, title: widget.dataType,);
  }
}

// Define a class called ChartDash that extends ConsumerStatefulWidget.
class ChartDash extends ConsumerStatefulWidget{
  final String imu;
  
  // Define a constructor for the ChartDash class.
  const ChartDash({required this.imu, Key? key}) : super(key: key);

  // Override the createState method to return an instance of _ChartDash.
  @override
  ConsumerState<ChartDash> createState() => _ChartDash();
}

// Define a private class called _ChartDash that extends ConsumerState.
class _ChartDash extends ConsumerState<ChartDash> {
  // Declare a DataChart called mainChart.
  DataChart? mainChart;
  
  // Declare an integer called _key with a value of 1.
  final int _key = 1;
  
  // Declare a Color called highlightedBorder with a value of Colors.lightBlueAccent.shade100.
  Color highlightedBorder = Colors.lightBlueAccent.shade100;
  
  // Declare a list called algorithms.
  late List algorithms;
  
  // Declare a String called dropdownValue with a value of an empty string.
  String? dropdownValue='';
  
  // Declare a map called dataTypes.
  Map dataTypes = {};
  
  // Declare a list called tapped with an empty array.
  List tapped = [];
  
  // Declare a list called canSwitchToChart with an empty array.
  List canSwitchToChart = [];
  
  // Declare a list called types with an empty array.
  List types = [];
  
  /*a widget that displays a stack of charts,where the user can switch 
  between different chart types by tapping on each chart.*/
  
  /*The createStack function takes two parameters:
  a BuildContext and a BoxConstraints. It returns a Widget that
  contains a SizedBox with the given constraints and
  a Stack of charts that are created using the List.generate method.
  Each chart is an AnimatedPositioned widget that animates its position and size
  based on whether it is tapped or not. */

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
                                    child: SelectableText(types[i], style: const TextStyle(color: Colors.white),),
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

  /*The build function is called whenever the widget is built or rebuilt. It initializes types, tapped,
  and canSwitchToChart variables with values obtained from dataTypesProvider. 
  It then creates the stack of charts by calling the createStack function.*/
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
