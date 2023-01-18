import 'dart:ui';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iot_project/LandingPage/chart_dash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'LandingPage/imus_route.dart';
import 'dart:io';



void main() {
  runApp(ProviderScope(child: MyApp()));
}

class CustomRoute extends MaterialPageRoute {
  CustomRoute({ required WidgetBuilder builder, required RouteSettings settings })
      : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return child;
  }
}

//ignore: must_be_immutable
class MyApp extends ConsumerWidget {
  MyApp({super.key});
  Map routes = {};
  Map properties = {};
  Map<String, List<TextFieldClass>> addedIMUs = {'imus': [], 'feedbacks': []};
  List imus = [];
  Route<dynamic> generateRoute(RouteSettings settings) {
    if(settings.name == 'home') {
      return CustomRoute(
          settings: RouteSettings(name: settings.name),
          builder: (context) => ProviderScope(child: MyHomePage(properties: properties, addedIMUs: addedIMUs,))
      );
    } else if(settings.name == 'chart_dash_route') {
      return CustomRoute(
          settings: RouteSettings(name: settings.name),
          builder: (context) => ProviderScope(child: ChartDashRoute(properties: properties))
      );
    }
    return CustomRoute( //name='imus_route'
        settings: RouteSettings(name: settings.name),
        builder: (context) => ProviderScope(child: Builder(
            builder: (context) {
              return IMUsRoute(addedIMUs: addedIMUs, properties: properties,);
            }
        ))
    );
  }
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {


    return MaterialApp(
      title: 'Motion Sensing',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        // primarySwatch: Colors.green,
        expansionTileTheme: ExpansionTileThemeData(
          iconColor: Colors.blue.shade700,
          collapsedIconColor: Colors.white,
          collapsedTextColor: Colors.white,
          textColor: Colors.blue.shade700,
        ),
        textTheme: const TextTheme(
          bodyText1: TextStyle(
              color: Colors.white,
              shadows: [
                Shadow(
                    blurRadius: 5,
                    color: Colors.grey
                )
              ]
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue
        ),
        drawerTheme: DrawerThemeData(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
          backgroundColor: Colors.grey.shade100.withOpacity(0.4)
        ),
        fontFamily: "Arial",
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.grey.shade100.withOpacity(0.4),
        dialogBackgroundColor: Colors.grey.shade100.withOpacity(0.4),
        cardTheme: const CardTheme(
          elevation: 0
        )
      ),
      home: ProviderScope(child: MyHomePage(properties: properties, addedIMUs: addedIMUs,)),
      initialRoute: 'home',
      onGenerateRoute: generateRoute,
    );
  }
}

//ignore: must_be_immutable
class AlgParams extends ConsumerStatefulWidget{
  Map properties;
  AlgParams({super.key, required this.properties});

  @override
  ConsumerState<AlgParams> createState() => _AlgParams();
}

class _AlgParams extends ConsumerState<AlgParams>{
  String? dropdownValue = '';
  Map imuDashboards = {};
  String outputFileForDisplay = '';

  @override
  Widget build(BuildContext context) {
    List curAlgParams = ref.watch(requestAnswerProvider).curAlgParams;
    String currentAlgorithm = ref.watch(chosenAlgorithmProvider).chosenAlg;
    List<Widget> params = [];
    if(widget.properties['output_file'] == null) {
      setState(() {
        outputFileForDisplay = '';
      });
    }

    params.add(
        Text(
          outputFileForDisplay.split('\\').last,
          style: Theme.of(context).textTheme.bodyText1,
        )
    );
    params.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: Card(
                color: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                elevation: Theme.of(context).cardTheme.elevation,
                child: TextButton(
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Select output file',
                      style: TextStyle(
                          color: Colors.grey
                      ),
                    ),
                  ),
                  onPressed: () async {
                    final DateTime now = DateTime.now();
                    String? outputFile = await FilePicker.platform.saveFile(
                        dialogTitle: 'Please select an output file:',
                        fileName: '${now.year}-${now.month}-${now.day}--${now.hour}-${now.minute}-${now.second}',
                        allowedExtensions: ['csv'],
                        type: FileType.custom
                    );

                    if (outputFile != null) {
                      if(!outputFile.contains('.csv')) {
                        outputFile += '.csv';
                      }
                    } //User cancelled the file picker

                    widget.properties['output_file'] = outputFile;
                    setState(() {
                      if(widget.properties['output_file'] != null){
                        outputFileForDisplay = widget.properties['output_file'];
                      }
                    });
                  },
                ),
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: Card(
                color: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                elevation: Theme.of(context).cardTheme.elevation,
                child: TextButton(
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Clear',
                      style: TextStyle(
                          color: Colors.grey
                      ),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      widget.properties['output_file'] = null;
                      outputFileForDisplay = '';
                    });
                  },
                ),
              ),
            ),
          ],
        )
    );

    if(currentAlgorithm != '') {
      for(int i = 0; i < curAlgParams.length ;i++){
        if(curAlgParams[i]['type'] == 'TextBox'){
          if(!widget.properties.containsKey(curAlgParams[i]['param_name'])) {
            widget.properties[curAlgParams[i]['param_name']] = curAlgParams[i]['default_value'];
          }

          params.add(FractionallySizedBox(
            widthFactor: 0.6,
            child: Tooltip(
              message: curAlgParams[i]['param_name'],
              child: Card(
                color: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
                elevation: Theme.of(context).cardTheme.elevation,
                child: TextField(
                  textAlign: TextAlign.center,
                  onChanged: (value){
                    widget.properties[curAlgParams[i]['param_name']] = value;
                  },
                  decoration: InputDecoration(
                    labelText: curAlgParams[i]['param_name'],
                    border: const OutlineInputBorder(),
                    hintText: 'Enter a value. default: ${curAlgParams[i]['default_value']}',
                  ),
                ),
              ),
            ),
          )
          );
        } else {
          if(curAlgParams[i]['type'] == 'CheckList') {
            List values = curAlgParams[i]['values'];
            if(dropdownValue == '') {
              dropdownValue = values[curAlgParams[i]['default_value']];
              widget.properties[curAlgParams[i]['param_name']] = dropdownValue;
            }

            params.add(
              Column(
                children: [
                  Text(
                    curAlgParams[i]['param_name'],
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: DropdownButton(
                          items: [for(int k = 0; k < values.length; k++) DropdownMenuItem<String>(
                            value: values[k],
                            child: Text(values[k]),
                          )],
                          dropdownColor: Colors.grey.shade100.withOpacity(0.6),
                          icon: const Icon(
                            Icons.arrow_downward,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                  blurRadius: 5,
                                  color: Colors.grey
                              )
                            ]
                          ),
                          value: dropdownValue,
                          style: Theme.of(context).textTheme.bodyText1,
                          onChanged: (String? value) {
                            setState(() {
                              dropdownValue = value;
                              widget.properties[curAlgParams[i]['param_name']] = dropdownValue;
                            });
                          }
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: params,
    );
  }
}

//ignore: must_be_immutable
class DashControl extends ConsumerStatefulWidget{
  Map properties;
  DashControl({super.key, required this.properties});

  @override
  ConsumerState<DashControl> createState() => _DashControl();
}

class _DashControl extends ConsumerState<DashControl> {
  late List algorithms;
  String? dropdownValue='';


  @override
  Widget build(BuildContext context) {
    String chosenAlgorithm = ref.watch(chosenAlgorithmProvider).chosenAlg;
    algorithms = ref.watch(requestAnswerProvider).algorithms;
    List<DropdownMenuItem<String>> algorithmsList = [for(int i = 0; i < algorithms.length; i++) DropdownMenuItem<String>(
      value: algorithms[i],
      child: Text(
          algorithms[i],
          style: Theme.of(context).textTheme.bodyText1,
      ),
    )];

    if(dropdownValue == '' && algorithms.isNotEmpty) {
      dropdownValue = algorithms[0];
    } 

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(10))
      ),
      child: FractionallySizedBox(
        widthFactor: 0.6,
        child: ListView(
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                      'Please choose an algorithm:',
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: DropdownButton(
                          items: algorithmsList,
                          dropdownColor: Colors.grey.shade100.withOpacity(0.6),
                          icon: const Icon(
                            Icons.arrow_downward,
                            color: Colors.white,
                              shadows: [
                              Shadow(
                                  blurRadius: 5,
                                  color: Colors.grey
                              )
                            ]
                          ),
                          value: dropdownValue,
                          style: Theme.of(context).textTheme.bodyText1,
                          onChanged: (String? value) {
                            setState(() {
                              dropdownValue = value;
                              widget.properties['alg_name'] = value;
                              ref.read(chosenAlgorithmProvider).setChosenAlg(value!);
                            });
                          }
                      ),
                    ),
                  ),
                ),
                AnimatedCrossFade(
                    crossFadeState: chosenAlgorithm == '' ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 300),
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AlgParams(properties: widget.properties,),
                    )
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const AnimatedIndexedStack({
    Key? key,
    required this.index,
    required this.children,
    this.duration = const Duration(
      milliseconds: 800,
    ),
  }) : super(key: key);

  @override

  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void didUpdateWidget(AnimatedIndexedStack oldWidget) {
    if (widget.index != oldWidget.index) {
      _controller.forward(from: 0.0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.forward();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: IndexedStack(
        alignment: Alignment.center,
        index: widget.index,
        children: widget.children,
      ),
    );
  }
}

//ignore: must_be_immutable
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

//ignore: must_be_immutable
class MyHomePage extends ConsumerStatefulWidget{
  Map properties;
  Map<String, List<TextFieldClass>> addedIMUs;
  MyHomePage({super.key, required this.properties, required this.addedIMUs});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePage();
}

class _MyHomePage extends ConsumerState<MyHomePage>{
  int animatedStackIndex = 0;
  List<Widget> animatedStackChildren = [];
  bool canContinue = true;
  double forwardSize = 60;
  double backwardSize = 60;

  @override
  Widget build(BuildContext context) {
    int imusNumber = ref.watch(imusCounter).imuCount;
    String chosenAlg = ref.watch(chosenAlgorithmProvider).chosenAlg;

    if(animatedStackIndex == 1) {
      canContinue = imusNumber > 0;
    } else if(animatedStackIndex == 2) {
      canContinue = chosenAlg.isNotEmpty;
    }

    if(animatedStackChildren.isEmpty) {
      animatedStackChildren = [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Image(image: AssetImage('assets/images/logo_round.png')),
        ),
        FractionallySizedBox(
          widthFactor: 0.6,
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.all(Radius.circular(10))
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ExpansionTile(
                      title: const Text('Add IMUs',),
                      children: [
                        IMUList(addedIMUs: widget.addedIMUs['imus']!,),
                      ],
                    ),
                    ExpansionTile(
                      title: const Text('Add Feedback sensors',),
                      children: [
                        IMUList(isFeedbackList: true, addedIMUs: widget.addedIMUs['feedbacks']!,),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: DashControl(properties: widget.properties,)
          ),
        ),
      ];
    }

    return Scaffold(
      body: Stack(
        children: [
          const Image(
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              image: AssetImage('assets/images/bg.png')
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: AnimatedIndexedStack(
                      index: animatedStackIndex,
                      children: animatedStackChildren
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipOval(
                          child: AnimatedContainer(
                            width: backwardSize,
                            height: backwardSize,
                            onEnd: () {
                              setState(() {
                                backwardSize = 60;
                              });
                            },
                            duration: const Duration(milliseconds: 200),
                            color: animatedStackIndex == 0
                                ? Colors.grey.shade100.withOpacity(0.1)
                                : Theme.of(context).cardColor,
                            child: IconButton(
                                onPressed: () => setState(() {
                                  backwardSize = 70;
                                  if(animatedStackIndex > 0) {
                                    animatedStackIndex -= 1;
                                    return;
                                  }
                                }),
                                icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                          blurRadius: 5,
                                          color: Colors.grey
                                      )
                                    ]
                                )
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipOval(
                          child: AnimatedContainer(
                            width: forwardSize,
                            height: forwardSize,
                            duration: const Duration(milliseconds: 200),
                            onEnd: (){
                              setState(() {
                                forwardSize = 60;
                              });
                            },
                            color: canContinue
                                ? Theme.of(context).cardColor
                                : Colors.grey.shade100.withOpacity(0.1),
                            child: IconButton(
                                onPressed: () => setState(() {
                                  forwardSize = 70;
                                  if(!canContinue && animatedStackIndex == 1) {
                                    showDialog(
                                        context: context,
                                        builder: (context) => BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                            child: AlertDialog(
                                              content: Text(
                                                'IMU list cannot be empty',
                                                style: Theme.of(context).textTheme.bodyText1,
                                              ),
                                            )
                                        )
                                    );
                                    return;
                                  } else if(animatedStackIndex == 1) {
                                    animatedStackIndex += 1;
                                    Navigator.of(context).pushNamed('imus_route');
                                    return;
                                  } else if(!canContinue && animatedStackIndex == 2) {
                                    showDialog(
                                        context: context,
                                        builder: (context) => BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                            child: AlertDialog(
                                              content: Text(
                                                'Please select an algorithm to continue',
                                                style: Theme.of(context).textTheme.bodyText1,
                                              ),
                                            )
                                        )
                                    );
                                    return;
                                  } else if(animatedStackIndex < animatedStackChildren.length - 1) {
                                    animatedStackIndex += 1;
                                    return;
                                  }

                                  ref.read(requestAnswerProvider).startStopDataCollection();
                                  ref.read(requestAnswerProvider).setQuery('set_params');
                                  ref.read(requestAnswerProvider).setParamsMap(widget.properties);
                                  ref.read(requestAnswerProvider).filename = widget.properties['output_file'];
                                  if(widget.properties['output_file'] != null) {
                                    if(!File(widget.properties['output_file']).existsSync()) {
                                      var outputFile = File(widget.properties['output_file']!!);
                                      List headers = [];
                                      List imus = ref.watch(imusListProvider).imus;
                                      var types = ref.watch(dataTypesProvider).types;
                                      for(int i = 0; i < imus.length; i++) {
                                        headers.add('IMU');
                                        types.forEach((key, value) {
                                          headers.addAll(value);
                                        });
                                      }

                                      String csv = const ListToCsvConverter().convert([headers]);
                                      try {
                                        outputFile.writeAsStringSync('$csv\n', mode: FileMode.append);
                                      } catch (e) {
                                        if (kDebugMode) {
                                          print(e);
                                        }
                                      }
                                    }
                                  }
                                  ref.read(requestAnswerProvider).startStopDataCollection(stop: false);
                                  Navigator.of(context).pushNamed('chart_dash_route');
                                }),
                                icon: const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                          blurRadius: 5,
                                          color: Colors.grey
                                      )
                                    ]
                                )
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
