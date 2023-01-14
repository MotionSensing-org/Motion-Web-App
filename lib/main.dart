import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iot_project/LandingPage/chart_dash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_slidable/flutter_slidable.dart';


void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  MyApp({super.key});
  Map routes = {};
  Map properties = {};
  List imus = [];
  Route<dynamic> generateRoute(RouteSettings settings) {
    if(settings.name == 'home') {
      return MaterialPageRoute(
          settings: RouteSettings(name: settings.name),
          builder: (context) => ProviderScope(child: MyHomePage(properties: properties,))
      );
    }
    return MaterialPageRoute(
        settings: RouteSettings(name: settings.name),
        builder: (context) => ProviderScope(child: ChartDashRoute(properties: properties))
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
        cardTheme: const CardTheme(
          elevation: 0
        )
      ),
      home: ProviderScope(child: MyHomePage(properties: properties,)),
      initialRoute: 'home',
      onGenerateRoute: generateRoute,
    );
  }
}

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

    params.add(
        Text(
          outputFileForDisplay.split('\\').last,
          style: const TextStyle(
              color: Colors.white,
              shadows: [
                Shadow(
                    blurRadius: 5,
                    color: Colors.grey
                )
              ]
          ),
        )
    );
    params.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              color: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
              elevation: Theme.of(context).cardTheme.elevation,
              child: TextButton(
                child: const Text(
                  'Select output file',
                  style: TextStyle(
                      color: Colors.grey
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
            Card(
              color: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
              elevation: Theme.of(context).cardTheme.elevation,
              child: TextButton(
                child: const Text(
                  'Clear',
                  style: TextStyle(
                      color: Colors.grey
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
            widthFactor: 0.4,
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
                    style: const TextStyle(
                        color: Colors.white,
                        shadows: [
                          Shadow(
                              blurRadius: 5,
                              color: Colors.grey
                          )
                        ]
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
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
                        style: const TextStyle(
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                  blurRadius: 5,
                                  color: Colors.grey
                              )
                            ]
                        ),
                        onChanged: (String? value) {
                          setState(() {
                            dropdownValue = value;
                            widget.properties[curAlgParams[i]['param_name']] = dropdownValue;
                          });
                        }
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
          style: const TextStyle(
              shadows: [
                Shadow(
                    blurRadius: 5,
                    color: Colors.grey
                )
              ]
          ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
                'Please choose an algorithm:',
              style: TextStyle(
                  color: Colors.white,
                shadows: [
                  Shadow(
                      blurRadius: 5,
                      color: Colors.grey
                  )
                ]
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
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
                  style: const TextStyle(color: Colors.white),
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
  _AnimatedIndexedStackState createState() => _AnimatedIndexedStackState();
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

  @override
  void initState() {
    _playPauseAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> displayItems = [];
    List<Widget> algParams = [];
    List imus = ref.watch(requestAnswerProvider).imus;

    widget.properties.forEach((key, value) {
      if(key == 'alg_name') {
        algParams.add(Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
              value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20
            ),
          ),
        ));
      } else if(key == 'output_file' && value != null) {
        String nameWithoutPath = value.split('\\').last;
        algParams.add(Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Output file:\n$nameWithoutPath',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                // fontSize: 20
            ),
          ),
        ));
        // ref.read(requestAnswerProvider).filename = value;
      } else if(value != null) {
        algParams.add(Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
              '$key: $value',
              style: const TextStyle(
                  color: Colors.white,
                  // fontSize: 20
              )
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
              ref.read(requestAnswerProvider).startStopDataCollection(stop: true);
              widget.properties['output_file'] = null;
              Navigator.of(context).pushNamed('home');
            },
          ),
        ),
      )
    ]);

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
        children: [
          const Image(
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              image: AssetImage('assets/images/bg.png')
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  flex: 7,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                          decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: const BorderRadius.all(Radius.circular(10))
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: AnimatedIndexedStack(
                                duration: const Duration(milliseconds: 500),
                                index: chosenIMUIndex,
                                children: List.generate(imus.length, (index) {
                                  return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                                    return Stack(
                                        children: [
                                          Positioned(
                                            top: 0,
                                            left: 3 * constraints.maxWidth / 8,
                                            child: Icon(
                                              Icons.show_chart,
                                              color: Colors.white,
                                              size: constraints.maxWidth / 4,
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
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(20)),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                                decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: const BorderRadius.all(Radius.circular(10))
                                ),
                                child: Center(
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    shrinkWrap: true,
                                    itemCount: imus.length,
                                    itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
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
                                                    child: Icon(
                                                      Icons.sensors,
                                                      color: _connectedIMUColor,
                                                    ),
                                                  ),
                                                  Flexible(
                                                    fit: FlexFit.loose,
                                                    child: Visibility(
                                                      visible: MediaQuery.of(context).size.width > narrowWidth ? true : false,
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                )
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Flexible(
                  fit: FlexFit.loose,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 5.0),)
                )
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Builder(
                      builder: (context) {
                        return FloatingActionButton(
                          heroTag: 'Options',
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                          tooltip: 'Options',
                          child: const Icon(Icons.settings),
                        );
                      }
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FloatingActionButton(
                      heroTag: 'Imu status',
                      onPressed: () {

                      },
                      tooltip: 'Imu status',
                      child: const Icon(Icons.notifications),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FloatingActionButton(
                      heroTag: 'Play/Pause',
                      onPressed: () {
                        ref.read(playPauseProvider).playPause();
                        if(ref.read(playPauseProvider).pause) {
                          _playPauseAnimationController.forward();
                        } else {
                          _playPauseAnimationController.reverse();
                        }
                      },
                      tooltip: 'Play/Pause',
                      child: AnimatedIcon(icon: AnimatedIcons.pause_play, progress: _playPauseAnimationController),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class TextFieldClass{
  TextEditingController controller = TextEditingController();
  String imuMac;

  TextFieldClass({required this.controller, this.imuMac='88:6B:0F:E1:D8:68'});
}

class IMUList extends ConsumerStatefulWidget {
  IMUList({Key? key, this.isFeedbackList=false}) : super(key: key);
  List<TextFieldClass> addedIMUs = [];
  bool isFeedbackList;

  List<String> getList() => addedIMUs.map((e) => e.imuMac).toList();

  @override
  ConsumerState<IMUList> createState() => _IMUListState();
}

class _IMUListState extends ConsumerState<IMUList> {
  List imus = [];
  ListView listus = ListView();
  @override
  Widget build(BuildContext context) {
    print('\n\n');
    for (var element in widget.addedIMUs) {
      print(element.imuMac);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: FloatingActionButton(
            heroTag: 'Add ${widget.isFeedbackList ? 'feedback' : 'IMU'}',
            onPressed: () {
              setState(() {
                widget.addedIMUs.add(TextFieldClass(
                    controller: TextEditingController(),
                ));
              });
            },
            tooltip: 'Add ${widget.isFeedbackList ? 'feedback' : 'IMU'}',
            child: const Icon(Icons.plus_one),
          ),
        ),
        Flexible(
          child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.addedIMUs.length,
              itemBuilder: (context, index) {
                return Slidable(
                  key: UniqueKey(),
                  startActionPane: ActionPane(
                      dismissible: DismissiblePane(onDismissed: () {
                        setState(() {
                          widget.addedIMUs.removeAt(index);
                        });
                      }),
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                            onPressed: (BuildContext context) {
                              setState(() {
                                widget.addedIMUs.removeAt(index);
                              });
                            },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                        )
                      ]
                  ),
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.7,
                      child: TextFormField(
                        textAlign: TextAlign.center,
                        controller: widget.addedIMUs[index].controller..text = widget.addedIMUs[index].imuMac,
                        // initialValue: '88:6B:0F:E1:D8:68',
                        onChanged: (value) {
                          widget.addedIMUs[index].imuMac = value;
                          // ref.read(imusProvider).addIMU(value, isFeedback: widget.isFeedbackList);
                        },
                      ),
                    ),
                  ),
                );
              }
          ),
        )
      ],
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget{
  Map properties;
  MyHomePage({super.key, required this.properties});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePage();
}

class _MyHomePage extends ConsumerState<MyHomePage>{
  int animatedStackIndex = 0;
  List<Widget> animatedStackChildren = [];

  @override
  Widget build(BuildContext context) {
    if(animatedStackChildren.isEmpty) {
      animatedStackChildren = [
        const Image(image: AssetImage('assets/images/logo_cropped.png')),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: DashControl(properties: widget.properties,)
          ),
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
                      title: const Text('Add IMUs'),
                      children: [
                        IMUList(),
                      ],
                    ),
                    ExpansionTile(
                      title: const Text('Add Feedback sensors'),
                      children: [
                        IMUList(isFeedbackList: true,),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: animatedStackIndex == 0
                                  ? Colors.grey.shade100.withOpacity(0.1)
                                  : Theme.of(context).cardColor
                          ),
                          child: IconButton(
                              onPressed: () => setState(() {
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
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ref.watch(chosenAlgorithmProvider).chosenAlg == ''
                                && animatedStackIndex == 1
                                ? Colors.grey.shade100.withOpacity(0.1)
                                : Theme.of(context).cardColor
                          ),
                          child: IconButton(
                              onPressed: () => setState(() {
                                if(widget.properties['alg_name'] == null && animatedStackIndex == 1) {
                                  showDialog(
                                      context: context,
                                      builder: (context) => const AlertDialog(content: Text('Please select an algorithm to continue'),)
                                  );
                                  return;
                                } else if(animatedStackIndex < animatedStackChildren.length - 1) {
                                  animatedStackIndex += 1;
                                  return;
                                }

                                ref.read(requestAnswerProvider).setQuery('set_params');
                                ref.read(requestAnswerProvider).setParamsMap(widget.properties);
                                ref.read(requestAnswerProvider).startStopDataCollection(stop: false);
                                ref.read(requestAnswerProvider).filename = widget.properties['output_file'];
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
