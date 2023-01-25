import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_project/LandingPage/providers.dart';
import 'animated_indexed_stack.dart';
import 'chart_dash.dart';

class ChartDashRoute extends ConsumerStatefulWidget{
  Map properties;
  ChartDashRoute({Key? key, required this.properties}) : super(key: key);

  @override
  ConsumerState<ChartDashRoute> createState() => _ChartDashRoute();
}

class _ChartDashRoute extends ConsumerState<ChartDashRoute>
    with SingleTickerProviderStateMixin {
  Color selectedImuColor = Colors.green;
  Color notSelectedImuColor = Colors.grey;
  Map chartDashboards = {};
  int chosenIMUIndex = 0;
  static const Color _connectedIMUColor = Colors.green;
  late final AnimationController _playPauseAnimationController;
  List<double> controlButtonSizes = [60, 60, 60];

  @override
  void initState() {
    _playPauseAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> displayItems = [];
    List<Widget> algParams = [];
    List imus = ref.watch(imusListProvider).imus;
    bool isShort = ref.watch(shortTallProvider).isShort(context);
    bool isNarrow = ref.watch(shortTallProvider).isNarrow(context);

    widget.properties.forEach((key, value) {
      if(key == 'alg_name') {
        algParams.add(Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ));
      } else if(key == 'output_file' && value != null) {
        String nameWithoutPath = value.split('\\').last;
        algParams.add(Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Output file:\n$nameWithoutPath',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ));
        // ref.read(requestAnswerProvider).filename = value;
      } else if(value != null) {
        algParams.add(Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
              '$key: $value',
              style: Theme.of(context).textTheme.bodyText1
          ),
        ));
      }
    });

    displayItems.addAll([
      Card(
        color: Colors.black.withOpacity(0.3),
        elevation: Theme.of(context).cardTheme.elevation,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        child: Column(
          children: algParams,
        ),
      ),
    ]);

    displayItems.addAll([
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          color: Colors.red,
          elevation: Theme.of(context).cardTheme.elevation,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          child: TextButton(
            child: const Text(
              'Stop',
              style: TextStyle(
                  color: Colors.white
              ),
            ),
            onPressed: () {
              widget.properties['output_file'] = null;
              ref.read(requestAnswerProvider).startStopDataCollection(stop: true);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      )
    ]);

    Widget chartsForDisplay = ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.all(Radius.circular(20))
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedIndexedStack(
                  duration: const Duration(milliseconds: 500),
                  index: chosenIMUIndex,
                  children: List.generate(imus.length, (index) {
                    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                      return Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              child: Icon(
                                Icons.show_chart,
                                color: Colors.white,
                                size: constraints.maxWidth
                                    / (isShort || isNarrow ? 4 : 10),
                              ),
                            ),
                            ChartDash(imu: imus[index],)
                          ]
                      );
                    });
                  })
              ),
            )
        ),
      ),
    );

    Widget chartToggleButtons = ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.all(Radius.circular(10))
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },),
                child: ListView.builder(
                    scrollDirection: isShort || isNarrow ? Axis.vertical : Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: imus.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: GestureDetector(
                            child: Tooltip(
                              message: imus[index],
                              child: AnimatedContainer(
                                duration:  const Duration(milliseconds: 500),
                                decoration: BoxDecoration(
                                    color: (chosenIMUIndex == index) ? Colors.white : Colors.white.withOpacity(0.5),
                                    borderRadius: const BorderRadius.all(Radius.circular(20))
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Flexible(
                                        fit: FlexFit.loose,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Icon(
                                            Icons.sensors,
                                            color: _connectedIMUColor,
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        fit: FlexFit.loose,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: FittedBox(
                                            fit: BoxFit.contain,
                                            child: Text(
                                              imus[index].toString().substring(12),
                                              style: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                chosenIMUIndex = index;
                              });
                            }
                        ),
                      );
                    }),
              ),
            )
        ),
      ),
    );

    List<Widget> controlButtonList = [
      Flexible(
        fit: FlexFit.loose,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Builder(
              builder: (context) {
                return Tooltip(
                  message: 'Imu status',
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: AnimatedContainer(
                        onEnd: (){
                          setState(() {
                            controlButtonSizes[0] = 60;
                          });
                        },
                        alignment: Alignment.center,
                        width: controlButtonSizes[0],
                        height: controlButtonSizes[0],
                        duration:  const Duration(milliseconds: 100),
                        color: Colors.black.withOpacity(0.4),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: IconButton(
                              onPressed: () {
                                setState(() {
                                  controlButtonSizes[0] += 10;
                                });
                                Scaffold.of(context).openDrawer();
                              },
                              icon: const Icon(Icons.settings, color: Colors.white,)
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
          ),
        ),
      ),
      Flexible(
        fit: FlexFit.loose,
        child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Center(
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AnimatedContainer(
                    onEnd: (){
                      setState(() {
                        controlButtonSizes[1] = 60;
                      });
                    },
                    alignment: Alignment.center,
                    width: controlButtonSizes[1],
                    height: controlButtonSizes[1],
                    duration:  const Duration(milliseconds: 100),
                    color: Colors.black.withOpacity(0.4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.white,),
                        onPressed: () {
                          setState(() {
                            controlButtonSizes[1] += 10;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            )
        ),
      ),
      Flexible(
          fit: FlexFit.loose,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  onEnd: (){
                    setState(() {
                      controlButtonSizes[2] = 60;
                    });
                  },
                  alignment: Alignment.center,
                  width: controlButtonSizes[2],
                  height: controlButtonSizes[2],
                  duration:  const Duration(milliseconds: 100),
                  color: Colors.black.withOpacity(0.4),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      icon: AnimatedIcon(
                          color: Colors.white,
                          icon: AnimatedIcons.pause_play,
                          progress: _playPauseAnimationController
                      ),
                      onPressed: () {
                        setState(() {
                          controlButtonSizes[2] += 10;
                        });
                        ref.read(playPauseProvider).playPause();
                        if(ref.read(playPauseProvider).pause) {
                          _playPauseAnimationController.forward();
                        } else {
                          _playPauseAnimationController.reverse();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          )
      )
    ];

    Widget regularDash = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        //mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            flex: 6,
            child: chartsForDisplay,
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(fit: FlexFit.loose, child: chartToggleButtons),
                ],
              ),
            ),
          ),
          const Flexible(
              fit: FlexFit.loose,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2.0),)
          )
        ],
      ),
    );

    Widget smallDash = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            flex: 7,
            child: chartsForDisplay,
          ),
          Flexible(
            fit: FlexFit.loose,
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(fit: FlexFit.loose, child: chartToggleButtons),
                  Flexible(
                      fit: FlexFit.loose,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: controlButtonList,
                        ),
                      )
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      drawer: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Drawer(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: displayItems,
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        alignment: Alignment.topCenter,
        children: [
          const Image(
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              image: AssetImage('assets/images/bg.png')
          ),
          isShort || isNarrow ? smallDash : regularDash,
          Positioned(
            bottom: 0,
            left: 0,
            child: Visibility(
                visible: !isShort && !isNarrow,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: controlButtonList,
                  ),
                )
            ),
          )
        ],
      ),
    );
  }
}