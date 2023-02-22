import 'dart:ui';
import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_project/LandingPage/providers.dart';
import 'animated_indexed_stack.dart';
import 'chart_dash.dart';

/*
Create a chart dashboard widget with different features such as battery icons, IMU colors, and control button sizes.
It also provides support for animating these widgets.(It indicates the level of the battery of each IMUS and indicate us if their battery is low by
sending an alert to the screen when it is under a certain value of battery)
*/

//ignore: must_be_immutable
class ChartDashRoute extends ConsumerStatefulWidget {
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
  Map batteryIcons = {
    0: const Icon(
      Icons.battery_0_bar,
      color: Colors.red,
    ),
    15: const Icon(
      Icons.battery_1_bar,
      color: Colors.red,
    ),
    30: const Icon(
      Icons.battery_2_bar,
      color: Colors.red,
    ),
    50: const Icon(
      Icons.battery_3_bar,
      color: Colors.green,
    ),
    70: const Icon(
      Icons.battery_4_bar,
      color: Colors.green,
    ),
    80: const Icon(
      Icons.battery_5_bar,
      color: Colors.green,
    ),
    90: const Icon(
      Icons.battery_6_bar,
      color: Colors.green,
    ),
    100: const Icon(
      Icons.battery_full,
      color: Colors.green,
    ),
  };

  @override
  void initState() {
    _playPauseAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> displayItems = [];
    List<Widget> algParams = [];
    List<Widget> batteriesWidgets = [];
    Map batteries = ref.watch(requestAnswerProvider).batteries;
    List imus = ref.watch(imusListProvider).imus,
    feedbacks = ref.watch(imusListProvider).feedbacks;
    List<Widget> notifications = [];
    bool isShort = ref.watch(shortTallProvider).isShort(context);
    bool isNarrow = ref.watch(shortTallProvider).isNarrow(context);
    bool showFeedback = ref.watch(dataProvider).feedbackActive;
    if (batteries.isNotEmpty) {
      for (var element in imus + feedbacks) {
        List batteryVals = batteryIcons.keys.toList();
        int batteryKey = 0;
        for (int i = 0; i < batteryVals.length - 1; i++) {
          if (batteries[element] == null) {
            break;
          } else if (batteries[element] > batteryVals[i] &&
              batteries[element] <= batteryVals[i + 1]) {
            batteryKey = batteryVals[i + 1];
            if (batteries[element] <= 30) {
              notifications.add(
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text('Sensor ${element.toString().substring(12)} '
                        'has low battery (${batteries[element]}%)',
                      style: Theme.of(context).textTheme.bodyText1,),
                  ),
              );
            }
            break;
          } else {
            batteryKey = batteryVals[i];
          }
        }

        batteriesWidgets.add(Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.all(Radius.circular(10))),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            element.toString().substring(12),
                            style: const TextStyle(color: Colors.black),
                          )),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Tooltip(
                          message: '${batteries[element]}%',
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              RotatedBox(
                                quarterTurns: 1,
                                child: batteryIcons[batteryKey],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
      }
    }

    widget.properties.forEach((key, value) {
      if (key == 'alg_name') {
        algParams.add(Padding(
          padding: const EdgeInsets.all(8.0),
          child: SelectableText(
            value,
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ));
      } else if (key == 'output_file' && value != null) {
        String nameWithoutPath = value.split('\\').last;
        algParams.add(Padding(
          padding: const EdgeInsets.all(8.0),
          child: SelectableText(
            'Output file:\n$nameWithoutPath',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ));
        // ref.read(requestAnswerProvider).filename = value;
      } else if (value != null) {
        algParams.add(Padding(
          padding: const EdgeInsets.all(8.0),
          child: SelectableText('$key: $value',
              style: Theme.of(context).textTheme.bodyText1),
        ));
      }
    });

    displayItems.addAll([
      Card(
        color: Colors.black.withOpacity(0.5),
        elevation: Theme.of(context).cardTheme.elevation,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
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
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))),
          child: TextButton(
            child: const Text(
              'Stop',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              widget.properties['output_file'] = null;
              ref.read(dataProvider).startStopDataCollection(stop: true);
              await Future.delayed(const Duration(milliseconds: 100));
              ref.read(requestAnswerProvider).connectionSuccess = false;
              ref.read(backendProcessHandler).closeBackendProcess();
              if (mounted) {
                Navigator.of(context)
                    .popUntil((route) => route.settings.name == 'setup_route');
              }
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
                borderRadius: const BorderRadius.all(Radius.circular(20))),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedIndexedStack(
                  duration: const Duration(milliseconds: 500),
                  index: chosenIMUIndex,
                  children: List.generate(imus.length, (index) {
                    return LayoutBuilder(builder:
                        (BuildContext context, BoxConstraints constraints) {
                      return Stack(alignment: Alignment.center, children: [
                        Positioned(
                          child: Icon(
                            Icons.show_chart,
                            color: Colors.black.withOpacity(0.3),
                            size: constraints.maxWidth /
                                (isShort || isNarrow ? 4 : 10),
                          ),
                        ),
                        Visibility(
                            visible: chosenIMUIndex == index,
                            // maintainState: true,
                            child: ChartDash(
                              imu: imus[index],
                            ))
                      ]);
                    });
                  })),
            )),
      ),
    );

    /*
    imuToggleButtons: a list of toggle buttons that represents a list of IMUs.
    The widget has the following structure:
    -Each toggle button is a GestureDetector widget that responds to tap events.
    -Each toggle button has an AnimatedContainer widget with a black background
     and rounded corners that changes its opacity based on whether it's currently selected or not.
    -Each toggle button also has an icon (sensors) and a text label that displays the name of the corresponding IMU.
    */
    Widget imuToggleButtons = ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.all(Radius.circular(10))),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: ListView.builder(
                    scrollDirection: isShort ? Axis.vertical : Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: imus.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: GestureDetector(
                            child: Tooltip(
                              message: imus[index],
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                decoration: BoxDecoration(
                                    color: (chosenIMUIndex == index)
                                        ? Colors.black.withOpacity(0.7)
                                        : Colors.black.withOpacity(0.5),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(20))),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Flexible(
                                        fit: FlexFit.loose,
                                        child: FittedBox(
                                          fit: BoxFit.fill,
                                          child: Icon(
                                            Icons.sensors,
                                            color: _connectedIMUColor,
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        fit: FlexFit.loose,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          child: FittedBox(
                                            fit: BoxFit.fill,
                                            child: Text(
                                              imus[index]
                                                  .toString()
                                                  .substring(12),
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
                            }),
                      );
                    }),
              ),
            )),
      ),
    );

    /*
      A list of Flexible widgets, containing buttons with different functionalities
      and the feedback active message that appears when a feedback is set to on.
      -The first button shows a Tooltip with the message "Settings" when hovered over,
       and when clicked, it opens a drawer using Scaffold.of(context).openDrawer().
      -The second button shows a badge with a count of notifications,
       and when clicked, it displays an AlertDialog with a list of notifications.
      -The third button toggles between a play and pause icon, and when clicked,
       it updates a playPauseProvider state using ref.read(playPauseProvider).playPause().
      The AnimatedContainer widget is used for each button to create a smooth animation when the button size changes.
      The animation is triggered when the button is clicked.
    */
    List<Widget> controlList = [
      Flexible(
        flex: 1,
        fit: FlexFit.loose,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Builder(builder: (context) {
            return Tooltip(
              message: 'Settings',
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AnimatedContainer(
                    onEnd: () {
                      setState(() {
                        controlButtonSizes[0] = 60;
                      });
                    },
                    alignment: Alignment.center,
                    width: controlButtonSizes[0],
                    height: controlButtonSizes[0],
                    duration: const Duration(milliseconds: 100),
                    color: Colors.black.withOpacity(0.7),
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: IconButton(
                          onPressed: () {
                            setState(() {
                              controlButtonSizes[0] += 10;
                            });
                            Scaffold.of(context).openDrawer();
                          },
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white,
                          )),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
      Flexible(
        flex: 1,
        fit: FlexFit.loose,
        child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Badge(
              badgeContent: Text('${notifications.length}',
                style: Theme.of(context).textTheme.bodyText1,
              ),
              showBadge: notifications.isNotEmpty,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AnimatedContainer(
                    onEnd: () {
                      setState(() {
                        controlButtonSizes[1] = 60;
                      });
                    },
                    alignment: Alignment.center,
                    width: controlButtonSizes[1],
                    height: controlButtonSizes[1],
                    duration: const Duration(milliseconds: 100),
                    color: Colors.black.withOpacity(0.7),
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: IconButton(
                        icon: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) => BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: AlertDialog(
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: notifications,
                                    ),
                                  )
                              )
                          );
                          setState(() {
                            controlButtonSizes[1] += 10;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            )),
      ),
      Flexible(
          flex: 1,
          fit: FlexFit.loose,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  onEnd: () {
                    setState(() {
                      controlButtonSizes[2] = 60;
                    });
                  },
                  alignment: Alignment.center,
                  width: controlButtonSizes[2],
                  height: controlButtonSizes[2],
                  duration: const Duration(milliseconds: 100),
                  color: Colors.black.withOpacity(0.7),
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: IconButton(
                      icon: AnimatedIcon(
                          color: Colors.white,
                          icon: AnimatedIcons.pause_play,
                          progress: _playPauseAnimationController),
                      onPressed: () {
                        setState(() {
                          controlButtonSizes[2] += 10;
                        });
                        ref.read(playPauseProvider).playPause();
                        if (ref.read(playPauseProvider).pause) {
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
          )),
      Flexible(
          child: Visibility(
              visible: showFeedback,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: const BorderRadius.all(Radius.circular(10))
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Feedback is active',
                          style: TextStyle(color: Colors.green),),
                      ),
                    ),
                  ),
                ),
              )
          )
      ),
    ];

    Widget dash = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  children: batteriesWidgets,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(flex: 6, child: chartsForDisplay),
                Flexible(
                  flex: 1,
                  child: Visibility(
                    visible: isShort,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(fit: FlexFit.loose, child: imuToggleButtons),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            flex: 1,
            child: Visibility(
              visible: !isShort,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(fit: FlexFit.loose, child: imuToggleButtons),
                  ],
                ),
              ),
            ),
          ),
          Flexible(
            flex: 1,
            fit: FlexFit.loose,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: controlList,
              ),
            ),
          )
          // const Flexible(
          //     fit: FlexFit.loose,
          //     child: Padding(
          //       padding: EdgeInsets.symmetric(vertical: 2.0),)
          // )
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
              image: AssetImage('assets/images/bg.png')),
          dash,
          // Positioned(
          //   bottom: 0,
          //   left: 0,
          //   child: Padding(
          //     padding: const EdgeInsets.all(16.0),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: controlButtonList,
          //     ),
          //   ),
          // )
        ],
      ),
    );
  }
}
