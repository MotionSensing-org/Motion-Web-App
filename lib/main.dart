import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'LandingPage/animated_indexed_stack.dart';
import 'LandingPage/chart_dash_route.dart';
import 'LandingPage/dash_control.dart';
import 'LandingPage/imus_route.dart';
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
    } else if(settings.name == 'dash_control_route') {
      return CustomRoute(
          settings: RouteSettings(name: settings.name),
          builder: (context) => ProviderScope(child: DashControlRoute(properties: properties))
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
        inputDecorationTheme: const InputDecorationTheme(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.transparent
            )
          )
        ),
        expansionTileTheme: ExpansionTileThemeData(
          iconColor: Colors.blue.shade700,
          collapsedIconColor: Colors.black.withOpacity(0.7),
          collapsedTextColor: Colors.black.withOpacity(0.7),
          textColor: Colors.blue.shade700,
        ),
        textTheme: const TextTheme(
          bodyText1: TextStyle(
              color: Colors.white,
              // shadows: [
              //   Shadow(
              //       blurRadius: 5,
              //       color: Colors.grey
              //   )
              // ]
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
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                          'Please insert server address:',
                          style: TextStyle(color: Colors.black.withOpacity(0.6),)
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FractionallySizedBox(
                        widthFactor: 0.7,
                        child: TextFormField(
                          style: TextStyle(color: Colors.black.withOpacity(0.6),),
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
                                onPressed: () async {
                                  setState(() {
                                  });
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

                                  // ref.read(dataProvider).startStopDataCollection();
                                  // // ref.read(requestAnswerProvider).setQuery('set_params');
                                  // ref.read(requestAnswerProvider).setParamsMap(widget.properties);
                                  // ref.read(requestAnswerProvider).setAlgParams();

                                  ref.read(requestAnswerProvider).getAlgParams();
                                  ref.read(requestAnswerProvider).getCurAlg();
                                  ref.read(requestAnswerProvider).getDataTypes();
                                  await Navigator.of(context).pushNamed('dash_control_route');
                                },
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
