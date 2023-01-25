import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

double listMin(List l) {
  if(l.isEmpty) {
    return 0;
  }
  double curMin = l[0];
  for(int i = 0; i < l.length; i++) {
    curMin = curMin > l[i] ? l[i] : curMin;
  }

  return curMin;
}

double listMax(List l) {
  if(l.isEmpty) {
    return 0;
  }
  double curMax = l[0];
  for(int i = 0; i < l.length; i++) {
    curMax = curMax < l[i] ? l[i] : curMax;
  }

  return curMax;
}

//ignore: must_be_immutable
class BaseDataChart extends StatefulWidget {
  BaseDataChart({super.key, this.labels=const [], this.title='', required this.linesData});
  final String title;
  List<String> labels = [];
  List linesData;
  @override
  State<BaseDataChart> createState() => _BaseDataChartState();
}

class _BaseDataChartState extends State<BaseDataChart> {
  List<Color> lineColors = [
    Colors.black,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.red,
    Colors.grey
  ];
  Color lineColor = Colors.grey;
  late List<bool> showLines;
  List<LineChartBarData> lineBarsData = [];
  bool shouldAssignLineColors = true;
  List<double> labelOpacities = [];

  @override
  void initState() {
    showLines = List.generate(widget.linesData.length, (index) => true);
    labelOpacities = List.generate(widget.labels.length, (index) => 1.0);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    lineBarsData = List.generate(widget.linesData.length, (index) {
      return LineChartBarData(
          color: lineColors[index],
          spots: List.generate(widget.linesData[index].length, (dataIndex) => FlSpot(dataIndex.toDouble(), widget.linesData[index][dataIndex])),
          isCurved: true,
          dotData: FlDotData(show: false),
          show: showLines[index]
      );
    });

    List yAxisValues = [];
    for(int i = 0; i < widget.linesData.length; i++) {
      if(showLines[i]) {
        yAxisValues.add(widget.linesData[i]);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
            flex: 1,
            fit: FlexFit.loose,
            child: Text(
              widget.title,
              style: const TextStyle(color: Colors.black),
            )
        ),
        Expanded(
          flex: 9,
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 10.0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: LineChart(
                LineChartData(
                  minY: listMin(List.generate(yAxisValues.length, (index) {
                    return listMin(yAxisValues[index]);
                  })),
                  maxY: listMax(List.generate(yAxisValues.length, (index) {
                    return listMax(yAxisValues[index]);
                  })),
                  lineBarsData: lineBarsData,
                ),
                swapAnimationDuration: const Duration(milliseconds: 2),
              ),
            ),
          ),
        ),
        Flexible(
          flex: 1,
          fit: FlexFit.loose,
          child: Visibility(
              visible: widget.labels.isNotEmpty,
              child: Align(
                alignment: Alignment.center,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    children: List.generate(widget.labels.length, (index) {
                      return Opacity(
                        opacity: labelOpacities[index],
                        child: TextButton(onPressed: () {
                          setState(() {
                            labelOpacities[index] =
                            (labelOpacities[index] == 1.0) ? 0.4 : 1.0;
                            showLines[index] = !showLines[index];
                          });
                        }, child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                                fit: FlexFit.loose,
                                child: Text(
                                  widget.labels[index],
                                  style: const TextStyle(color: Colors.black),
                                )
                            ),
                            Flexible(
                              fit: FlexFit.loose,
                              child: Icon(Icons.show_chart_rounded, color: lineColors[index],),
                            )
                          ],
                        )),
                      );
                    }),
                  ),
                ),
              )
          ),
        )
      ],
    );
  }
}
