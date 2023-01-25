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
    Colors.white,
    Colors.blue.shade300,
    Colors.green.shade300,
    Colors.yellow.shade300,
    Colors.purple.shade300,
    Colors.red.shade300,
    Colors.pink.shade300,
    Colors.brown.shade300,
    Colors.grey.shade300,
    Colors.black,
  ];
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
    var minY  =listMin(List.generate(yAxisValues.length, (index) {
      return listMin(yAxisValues[index]);
    }));
    var maxY = listMax(List.generate(yAxisValues.length, (index) {
      return listMax(yAxisValues[index]);
    }));

    return Column(
      // mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
            flex: 2,
            fit: FlexFit.loose,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                widget.title,
                style: const TextStyle(color: Colors.white),
              ),
            )
        ),
        Expanded(
          flex: 9,
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 10.0,
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false,)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false,)),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        // interval: (maxY-minY) / 10,
                        reservedSize: 60,
                          showTitles: true,
                          getTitlesWidget: (double val, TitleMeta t) {
                            return Tooltip(
                                message: val.toStringAsFixed(3),
                                child: Text(
                                  val.toStringAsFixed(3),
                                  style: const TextStyle(color: Colors.white),
                                )
                            );
                          }
                      )
                  ),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double val, _) {
                          return FittedBox(fit: BoxFit.scaleDown, child: Text(val.toInt().toString(), style: const TextStyle(color: Colors.white),));
                        }
                      )
                  )
                ),
                minY: minY,
                maxY: maxY,
                lineBarsData: lineBarsData,
              ),
              swapAnimationDuration: const Duration(milliseconds: 2),
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
                                  style: const TextStyle(color: Colors.white),
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
