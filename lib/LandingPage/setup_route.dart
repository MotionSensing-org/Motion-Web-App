import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_project/LandingPage/providers.dart';
import 'animated_indexed_stack.dart';
import 'imus_route.dart';

//ignore: must_be_immutable
class SetupPage extends ConsumerStatefulWidget{
  Map properties;
  Map<String, List<TextFieldClass>> addedIMUs;
  SetupPage({super.key, required this.properties, required this.addedIMUs});

  @override
  ConsumerState<SetupPage> createState() => _SetupPage();
}

class _SetupPage extends ConsumerState<SetupPage>{
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
    // String chosenAlg = ref.watch(chosenAlgorithmProvider).chosenAlg;
    canContinue = imusNumber > 0 && connectedToIMUs;

    if(animatedStackChildren.isEmpty) {
      animatedStackChildren = [
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

                              if(!ref.read(backendProcessHandler).running) {
                                await ref.read(backendProcessHandler).startBackendProcess();
                              }

                              if(mounted) await Navigator.of(context).pushNamed('imus_route');
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
