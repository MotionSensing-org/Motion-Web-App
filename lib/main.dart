import 'dart:ui';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'LandingPage/animated_indexed_stack.dart';
import 'LandingPage/chart_dash_route.dart';
import 'LandingPage/imus_route.dart';
import 'dart:io';
import 'LandingPage/providers.dart';



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
        inputDecorationTheme: const InputDecorationTheme(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.transparent
            )
          )
        ),
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
        Container(
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: const BorderRadius.all(Radius.circular(20))
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Visibility(
                  visible: outputFileForDisplay.isNotEmpty,
                  child: Text(
                    outputFileForDisplay.split('\\').last,
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: TextButton(
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Select output file',
                            style: TextStyle(
                                color: Colors.white
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
                    Flexible(
                      fit: FlexFit.loose,
                      child: Visibility(
                        visible: outputFileForDisplay.isNotEmpty,
                        child: TextButton(
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                  color: Colors.white
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
                ),
              ],
            ),
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
            widthFactor: 0.6,
            child: Tooltip(
              message: curAlgParams[i]['param_name'],
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: const BorderRadius.all(Radius.circular(4))
                ),
                child: TextField(
                  style: const TextStyle(
                    color: Colors.white
                  ),
                  textAlign: TextAlign.center,
                  onChanged: (value){
                    widget.properties[curAlgParams[i]['param_name']] = value;
                  },
                  decoration: InputDecoration(
                    labelStyle: const TextStyle(
                      color: Colors.white
                    ),
                    hintStyle: const TextStyle(
                      color: Colors.white
                    ),
                    labelText: curAlgParams[i]['param_name'],
                    border: const OutlineInputBorder(),
                    hintText: 'Enter a value. Default: ${curAlgParams[i]['default_value']}',
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: const BorderRadius.all(Radius.circular(20))
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
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
                  ),
                ),
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
    print('dash control');
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: const BorderRadius.all(Radius.circular(20))
                    ),
                    child: Column(
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
                                      ref.read(requestAnswerProvider).setCurAlg();
                                    });
                                  }
                              ),
                            ),
                          ),
                        ),
                      ],
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
          ],
        ),
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
  String serverUrl = '';
  final serverInputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    int imusNumber = ref.watch(imusCounter).imuCount;
    bool connectedToIMUs = ref.read(requestAnswerProvider).isConnected();
    String chosenAlg = ref.watch(chosenAlgorithmProvider).chosenAlg;
    if(animatedStackIndex == 2) {
      canContinue = imusNumber > 0 && connectedToIMUs;
    } else if(animatedStackIndex == 3) {
      canContinue = chosenAlg.isNotEmpty;
    } else {
      canContinue = true;
    }

    if(animatedStackChildren.isEmpty) {
      animatedStackChildren = [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: FractionallySizedBox(
            heightFactor: 0.5,
              alignment: Alignment.center,
              child: Image(image: AssetImage('assets/images/logo_round.png'))),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                          'Please insert server address:',
                          style: TextStyle(
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
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FractionallySizedBox(
                        widthFactor: 0.7,
                        child: TextFormField(
                          style: Theme.of(context).textTheme.bodyText1,
                          textAlign: TextAlign.center,
                          controller: serverInputController..text = 'http://127.0.0.1:5000',
                          onFieldSubmitted: (value) {
                            // serverUrl = value;
                            serverInputController.text = value;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
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
                    Flexible(
                      fit: FlexFit.loose,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FloatingActionButton(
                            heroTag: 'Connect to IMUs',
                            backgroundColor: Colors.black.withOpacity(0.6),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Connect',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            onPressed: () async {
                              if(ref.watch(imusCounter).imuCount == 0) {
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
                              }

                              await Navigator.of(context).pushNamed('imus_route');
                              setState(() {});
                            }
                        ),
                      ),
                    )
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
              // mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  // fit: FlexFit.loose,
                  flex: 4,
                  child: AnimatedIndexedStack(
                      index: animatedStackIndex,
                      children: animatedStackChildren
                  ),
                ),
                Flexible(
                  flex: 1,
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
                                  if(!canContinue) {
                                    return;
                                  } else if(animatedStackIndex == 2
                                      && !ref.read(requestAnswerProvider).isConnected()) {
                                    // animatedStackIndex += 1
                                    return;
                                  } else if(!canContinue && animatedStackIndex == 3) {
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
                                    if(animatedStackIndex == 1) {
                                      ref.read(requestAnswerProvider).setServerAddress(serverInputController.text);
                                    }

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
                                      headers.add('Time [sec]');

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
