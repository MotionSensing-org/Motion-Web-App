import 'package:flutter/material.dart';
import 'package:iot_project/LandingPage/chart_dash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

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
        builder: (context) => ProviderScope(child: ChartDashRoute(properties: properties, imu: settings.name!,))
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
        fontFamily: "Arial",
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.lightBlue.shade50,
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
    List imus = ref.watch(requestAnswerProvider).imus;


    for (var imu in imus) {
      imuDashboards[imu] = (context) => ProviderScope(child: ChartDashRoute(imu: imu, properties: widget.properties));
    }

    params.add(
        Text(
          outputFileForDisplay.split('\\').last,
          style: const TextStyle(
              color: Colors.white
          ),
        )
    );
    params.add(
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
                    style: const TextStyle(color: Colors.white),
                  ),
                  Card(
                    color: Colors.white,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    elevation: Theme.of(context).cardTheme.elevation,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButton(
                          items: [for(int k = 0; k < values.length; k++) DropdownMenuItem<String>(
                            value: values[k],
                            child: Text(values[k]),
                          )],
                          icon: const Icon(
                            Icons.arrow_downward,
                            color: Colors.blue,
                          ),
                          value: dropdownValue,
                          underline: Container(
                            color: Colors.blue,
                            height: 3,
                          ),
                          style: const TextStyle(color: Colors.blue),
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

    params.add(
        Card(
          color: Colors.green,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          elevation: Theme.of(context).cardTheme.elevation,
          child: TextButton(
            child: const Text(
              'Start',
              style: TextStyle(
                color: Colors.white
              ),
            ),
            onPressed: () {
              ref.read(requestAnswerProvider).setQuery('set_params');
              ref.read(requestAnswerProvider).setParamsMap(widget.properties);
              ref.read(requestAnswerProvider).startStopDataCollection(stop: false);
              ref.read(requestAnswerProvider).filename = widget.properties['output_file'];
              Navigator.of(context).pushNamed(imus[0]);
            },
          ),
        )
    );
    return Column(
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
      child: Text(algorithms[i]),
    )];

    if(dropdownValue == '' && algorithms.isNotEmpty) {
      dropdownValue = algorithms[0];
    } 

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            elevation: Theme.of(context).cardTheme.elevation,
            color: Colors.blue,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                      'Please choose an algorithm:',
                    style: TextStyle(
                        color: Colors.white
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    color: Colors.white,
                    elevation: Theme.of(context).cardTheme.elevation,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButton(
                          items: algorithmsList,
                          icon: const Icon(
                            Icons.arrow_downward,
                            color: Colors.blue,
                          ),
                          value: dropdownValue,
                          underline: Container(
                            color: Colors.blue,
                            height: 3,
                          ),
                          style: const TextStyle(color: Colors.blue),
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
          ),
        ),

      ],
    );
  }
}


class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    Key? key,
    required this.index,
    required this.children,
    this.duration = const Duration(
      milliseconds: 800,
    ),
  }) : super(key: key);

  @override
  _FadeIndexedStackState createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
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
        index: widget.index,
        children: widget.children,
      ),
    );
  }
}


class ChartDashRoute extends ConsumerStatefulWidget{
  Map properties;
  final String imu;
  ChartDashRoute({Key? key, required this.imu, required this.properties}) : super(key: key);

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
      } else {
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
        color: Colors.blue,
        elevation: Theme.of(context).cardTheme.elevation,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        child: Column(
          children: algParams,
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () {
            ref.read(playPauseProvider).playPause();
            if(ref.read(playPauseProvider).pause) {
              _playPauseAnimationController.forward();
            } else {
              _playPauseAnimationController.reverse();
            }
          },
          style: ButtonStyle(
            shape: MaterialStateProperty.all(const CircleBorder()),
            padding: MaterialStateProperty.all(const EdgeInsets.all(20)),
            backgroundColor: MaterialStateProperty.all(Colors.blue), // <-- Button color
            overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
              if (states.contains(MaterialState.pressed)) return Colors.lightBlueAccent; // <-- Splash color
              return Colors.blue;
            }),
          ),
          child: AnimatedIcon(icon: AnimatedIcons.play_pause, progress: _playPauseAnimationController),
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
              Navigator.of(context).pushNamed('home');
            },
          ),
        ),
      )
    ]);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.properties['alg_name']}'),
      ),
      drawer: Drawer(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: displayItems,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {

        },
        tooltip: 'Imu status',
        child: const Icon(Icons.notifications),
      ), // Th,
      body: Row(
        children: [
          Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Card(
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                          elevation: Theme.of(context).cardTheme.elevation,
                          color: Theme.of(context).cardColor,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: FadeIndexedStack(
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
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Card(
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                                elevation: Theme.of(context).cardTheme.elevation,
                                color: Theme.of(context).cardColor,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      shrinkWrap: true,
                                      itemCount: imus.length,
                                      itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: GestureDetector(
                                          child: AnimatedContainer(
                                            duration:  const Duration(milliseconds: 500),
                                            decoration: BoxDecoration(
                                                color: (chosenIMUIndex == index) ? Colors.lightBlue.shade200 : Colors.white,
                                                borderRadius: const BorderRadius.all(Radius.circular(20))
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Flexible(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(8.0),
                                                    child: Icon(
                                                      Icons.sensors,
                                                      color: _connectedIMUColor,
                                                    ),
                                                  ),
                                                ),
                                                Flexible(
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Text(
                                                      imus[index].toString().substring(12),
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              ],
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
                        ],
                      ),
                    ),
                  ],
                ),
              )
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
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                widget.addedIMUs.add(TextFieldClass(
                    controller: TextEditingController(),
                ));
                print(widget.addedIMUs.length);
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
                return TextFormField(
                  textAlign: TextAlign.center,
                  controller: widget.addedIMUs[index].controller..text = widget.addedIMUs[index].imuMac,
                  // initialValue: '88:6B:0F:E1:D8:68',
                  onFieldSubmitted: (value) {
                    widget.addedIMUs[index].imuMac = value;
                    ref.read(imusProvider).addIMU(value, isFeedback: widget.isFeedbackList);
                  },
                );
              }
          ),
        )
      ],
    );
  }
}

class MyHomePage extends ConsumerWidget {
  MyHomePage({super.key, required this.properties});
  Map properties;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motion Sensing'),
      ),
      drawer: Drawer(
        child: ListView(
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
            ExpansionTile(
              title: const Text('Add IMUs'),
              children: ref.watch(imusProvider).imus.map((e) => Text(e)).toList(),
            ),
            ExpansionTile(
              title: const Text('Add Feedback sensors'),
              children: ref.watch(imusProvider).feedbacks.map((e) => Text(e)).toList(),
            )
          ],
        ),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Card(
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                  elevation: Theme.of(context).cardTheme.elevation,
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Expanded(child: Image(image: AssetImage('assets/images/logo_cropped.png'))),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(child: DashControl(properties: properties,)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
