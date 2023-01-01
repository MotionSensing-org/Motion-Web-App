import 'package:flutter/material.dart';
import 'package:iot_project/LandingPage/chart_dash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
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
        primarySwatch: Colors.green,
        fontFamily: "Arial"
      ),
      home: ProviderScope(child: MyHomePage()),
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
  @override
  Widget build(BuildContext context) {
    List curAlgParams = ref.watch(requestAnswerProvider).curAlgParams;
    String currentAlgorithm = ref.watch(chosenAlgorithmProvider).chosenAlg;
    List<Widget> params = [];

    if(currentAlgorithm != '') {
      for(int i = 0; i < curAlgParams.length ;i++){
        if(curAlgParams[i]['type'] == 'TextBox'){
          if(!widget.properties.containsKey(curAlgParams[i]['param_name'])) {
            widget.properties[curAlgParams[i]['param_name']] = curAlgParams[i]['default_value'];
          }

          params.add(Card(
            color: Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
            child: TextField(
              onChanged: (value){
                widget.properties[curAlgParams[i]['param_name']] = value;
              },
              decoration: InputDecoration(
                labelText: curAlgParams[i]['param_name'],
                border: const OutlineInputBorder(),
                hintText: 'Enter a value',
              ),
            ),
          )
          );
        } else {
          if(curAlgParams[i]['type'] == 'CheckList') {
            List vals = curAlgParams[i]['values'];
            if(dropdownValue == '') {
              dropdownValue = vals[curAlgParams[i]['default_value']];
              widget.properties[curAlgParams[i]['param_name']] = dropdownValue;
            }

            params.add(
              Column(
                children: [
                  Text(
                    curAlgParams[i]['param_name'],
                    style: const TextStyle(color: Colors.blue),
                  ),
                  Card(
                    color: Colors.white,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButton(
                          items: [for(int k = 0; k < vals.length; k++) DropdownMenuItem<String>(
                            value: vals[k],
                            child: Text(vals[k]),
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
          color: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          child: TextButton(
            child: const Text(
              'Start',
              style: TextStyle(
                color: Colors.green
              ),
            ),
            onPressed: () {
              ref.read(requestAnswerProvider).setQuery('set_params');
              ref.read(requestAnswerProvider).setParamsMap(widget.properties);
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProviderScope(child: ChartDashRoute(properties: widget.properties,))));
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
    algorithmsList.add(const DropdownMenuItem<String>(
      value: '',
      child: Text(''),
    ));


    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            color: Colors.white,
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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
              color: Colors.lightBlueAccent.shade100,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
              child:  Padding(
                padding: const EdgeInsets.all(8.0),
                child: AnimatedCrossFade(
                    crossFadeState: chosenAlgorithm == '' ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 300),
                    firstChild: const SizedBox.shrink(),
                    secondChild: AlgParams(properties: widget.properties,)
                ),
              )
          ),
        ),
      ],
    );
  }
}


class ChartDashRoute extends ConsumerWidget {
  Map properties;
  List imus = [];
  ChartDashRoute({Key? key, required this.properties}) : super(key: key);
  Map chartDashboards = {};
  String curImu = '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Widget> displayItems = [];
    List<Widget> algParams = [];
    imus = ref.watch(requestAnswerProvider).imus;
    for (var imu in imus) {
      chartDashboards[imu] = ChartDash(imu: imu,);
    }

    if(curImu == '') {
      curImu = imus[0];
    }

    properties.forEach((key, value) {
      if(key == 'alg_name') {
        algParams.add(Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
              value,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 20
            ),
          ),
        ));
      } else {
        algParams.add(Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
              '$key: $value',
              style: const TextStyle(
                  color: Colors.blue,
                  // fontSize: 20
              )
          ),
        ));
      }
    });

    displayItems.addAll([
      Card(
        color: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        child: Column(
          children: algParams,
        ),
      ),
    ]);

    for(var imu in imus) {
      displayItems.add(
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              color: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
              child: TextButton(
                child: Text(
                  imu,
                  style: const TextStyle(
                      color: Colors.green
                  ),
                ),
                onPressed: () {
                  curImu = imu;
                },
              ),
            ),
          )
      );
    }

    displayItems.addAll([
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () {
            ref.read(playPauseProvider).playPause();
          },
          style: ButtonStyle(
            shape: MaterialStateProperty.all(const CircleBorder()),
            padding: MaterialStateProperty.all(const EdgeInsets.all(20)),
            // elevation: MaterialStateProperty.resolveWith<double?>((states) {
            //   return 10; // <-- Splash color
            // }),
            backgroundColor: MaterialStateProperty.all(Colors.blue), // <-- Button color
            overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
              if (states.contains(MaterialState.pressed)) return Colors.lightBlueAccent; // <-- Splash color
              return Colors.blue;
            }),
          ),
          child: ref.watch(playPauseProvider).pause
              ? const Icon(Icons.pause_outlined)
              : const Icon(Icons.play_arrow),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          color: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          child: TextButton(
            child: const Text(
              'Stop',
              style: TextStyle(
                  color: Colors.red
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      )
    ]);

    return Container(
      color: Colors.lightBlue,
      child: Row(
        children: [
          Expanded(
              flex: 1,
              child:  Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
                child: Card(
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                  elevation: 10,
                  color: Colors.lightBlueAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: displayItems,
                    ),
                  ),
                ),
              )
          ),
          Expanded(
              flex: 4,
              child: chartDashboards[curImu]
          )
        ],
      ),
    );
  }
}


class MyHomePage extends StatelessWidget {
  MyHomePage({super.key});
  Map properties = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.lightBlue,
        child: Row(
          children: [
            Expanded(
                flex: 1,
                child:  Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
                  child: Card(
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                    elevation: 20,
                    color: Colors.lightBlueAccent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DashControl(properties: properties,),
                      ],
                    ),
                  ),
                )
            ),
            Expanded(
              flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
                  child: Card(
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                    elevation: 20,
                    color: Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                              'Welcome to the motion sensing web app!',
                              style: TextStyle(
                                fontSize: 30,
                                color: Colors.blue
                              ),
                          ),
                        ),
                        Padding(padding: EdgeInsets.all(60.0)),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Image(image: AssetImage('assets/images/ms-image-one.png')),
                        ),
                      ],
                    ),
                  ),
                )
            )
          ],
        ),
      ),
    );
  }
}
