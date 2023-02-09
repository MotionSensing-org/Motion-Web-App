import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:iot_project/LandingPage/file_handlers.dart';
import 'package:iot_project/LandingPage/providers.dart';
import 'package:iot_project/consts.dart';
import 'animated_indexed_stack.dart';
import 'imu_list.dart';
import 'dart:io';

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
  List<bool> expanded = [false, false];
  double forwardSize = 60;
  double backwardSize = 60;
  String serverUrl = '';
  final serverInputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    int imusNumber = ref.watch(imusCounter).imuCount;
    bool connectedToIMUs = ref.read(requestAnswerProvider).isConnected();
    canContinue = imusNumber > 0 && connectedToIMUs;

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
                    child:
                    ListView(
                      shrinkWrap: true,
                      children: [
                        ExpansionPanelList(
                            elevation: 0,
                            children: [
                              ExpansionPanel(
                                  headerBuilder: (BuildContext context, bool isExpanded) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Add IMUs',),
                                    );
                                  },
                                  backgroundColor: Colors.transparent,
                                  canTapOnHeader: true,
                                  body: IMUList(addedIMUs: widget.addedIMUs['imus']!,),
                                  isExpanded: expanded[0]
                              ),
                              ExpansionPanel(
                                  headerBuilder: (BuildContext context, bool isExpanded) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Add Feedback sensors',),
                                    );
                                  },
                                  backgroundColor: Colors.transparent,
                                  canTapOnHeader: true,
                                  body: IMUList(isFeedbackList: true, addedIMUs: widget.addedIMUs['feedbacks']!,),
                                  isExpanded: expanded[1]
                              ),
                            ],
                            expansionCallback: (i, open) {
                              setState(() {
                                expanded[i] = !open;
                              });
                            }
                        ),
                      ],
                    ),
                    // ListView(
                    //   shrinkWrap: true,
                    //   children: [
                    //     ExpansionTile(
                    //       title: const Text('Add IMUs',),
                    //       maintainState: true,
                    //       initiallyExpanded: expanded[0],
                    //       onExpansionChanged: (value) {
                    //         setState(() {
                    //           expanded[0] = value;
                    //         });
                    //       },
                    //       children: [
                    //         IMUList(addedIMUs: widget.addedIMUs['imus']!,),
                    //       ],
                    //     ),
                    //     ExpansionTile(
                    //       title: const Text('Add Feedback sensors',),
                    //       initiallyExpanded: expanded[1],
                    //       children: [
                    //         IMUList(isFeedbackList: true, addedIMUs: widget.addedIMUs['feedbacks']!,),
                    //       ],
                    //     ),
                    //   ],
                    // ),
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FloatingActionButton(
                              heroTag: 'Save IMUs config',
                              backgroundColor: Colors.black.withOpacity(0.6),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Save Config',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              onPressed: () {
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

                                String name = '';
                                Map newConfig = widget.addedIMUs.map((key, value)
                                => MapEntry(key, value.map((e) => e.imuMac).toList()));
                                showDialog(context: context,
                                    builder: (context) {
                                      return BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                          child: AlertDialog(
                                            content:  Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Tooltip(
                                                  message: 'Enter a configuration name',
                                                  child: TextField(
                                                    style: Theme.of(context).textTheme.bodyText1,
                                                    textAlign: TextAlign.center,
                                                    onChanged: (value){
                                                      name = value;
                                                    },
                                                    decoration: InputDecoration(
                                                      labelStyle: const TextStyle(
                                                          color: Colors.white
                                                      ),
                                                      hintStyle: TextStyle(
                                                          color: Colors.white.withOpacity(0.7)
                                                      ),
                                                      // labelText: curAlgParams[i]['param_name'],
                                                      border: const OutlineInputBorder(),
                                                      hintText: 'Enter a configuration name',
                                                    ),
                                                  ),
                                                ),
                                                FloatingActionButton(
                                                    heroTag: 'Create imus config',
                                                    backgroundColor: Colors.black.withOpacity(0.6),
                                                    child: const FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: Padding(
                                                        padding: EdgeInsets.all(8.0),
                                                        child: Text(
                                                          'Save',
                                                          style: TextStyle(color: Colors.white),
                                                        ),
                                                      ),
                                                    ),
                                                    onPressed: () async {
                                                      if(name.isEmpty) {
                                                        showDialog(
                                                            context: context,
                                                            builder: (context) => BackdropFilter(
                                                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                                                child: AlertDialog(
                                                                  content: Text(
                                                                    'Configuration name cannot be empty',
                                                                    style: Theme.of(context).textTheme.bodyText1,
                                                                  ),
                                                                )
                                                            )
                                                        );
                                                        return;
                                                      }

                                                      await editJsonFile(imuConfigFile, name, newConfiguration: newConfig);
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) => BackdropFilter(
                                                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                                              child: AlertDialog(
                                                                content: Padding(
                                                                  padding: const EdgeInsets.all(8.0),
                                                                  child: Column(
                                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      const Padding(
                                                                        padding: EdgeInsets.all(8.0),
                                                                        child: Text(
                                                                          'Configuration saved',
                                                                          style: TextStyle(
                                                                            color: Colors.green,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Padding(
                                                                        padding: const EdgeInsets.all(8.0),
                                                                        child: FloatingActionButton(
                                                                            heroTag: 'Return after imu save',
                                                                            backgroundColor: Colors.black.withOpacity(0.6),
                                                                            child: const FittedBox(
                                                                              fit: BoxFit.scaleDown,
                                                                              child: Padding(
                                                                                padding: EdgeInsets.all(8.0),
                                                                                child: Text(
                                                                                  'Continue',
                                                                                  style: TextStyle(color: Colors.white),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            onPressed: () {
                                                                              Navigator.of(context).popUntil((route) => route.settings.name == 'setup_route');
                                                                            }
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              )
                                                          )
                                                      );
                                                    }
                                                ),
                                              ],
                                            ),
                                          )
                                      );
                                    }
                                );
                              }
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FloatingActionButton(
                              heroTag: 'Load IMUs config',
                              backgroundColor: Colors.black.withOpacity(0.6),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Load Config',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              onPressed: () async {
                                File file = getFileSync(imuConfigFile);
                                Map<String, dynamic> jsonData = getJsonConfigSync(file);
                                List<String> configList = jsonData.keys.toList();
                                if(configList.isEmpty) {
                                  await showDialog(
                                      context: context,
                                      builder: (context) => BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                          child: AlertDialog(
                                            content: SelectableText(
                                              'There are no saved configurations in $imuConfigFile',
                                              style: Theme.of(context).textTheme.bodyText1,
                                            ),
                                          )
                                      )
                                  );
                                  return;
                                }

                                await showDialog(context: context,
                                    builder: (context) {
                                      bool smallWindow = ref.watch(shortTallProvider).isShort(context)
                                          || ref.watch(shortTallProvider).isNarrow(context) ;
                                      double maxWidth = ref.watch(shortTallProvider).getWidth(context);
                                      double maxHeight = ref.watch(shortTallProvider).getHeight(context);

                                      return BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                          child: SimpleDialog(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Text(
                                                    'Click on a configuration to view details.\nSlide a configuration to select or delete it:',
                                                    style: Theme.of(context).textTheme.bodyText1,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: ScrollConfiguration(
                                                  behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
                                                    PointerDeviceKind.touch,
                                                    PointerDeviceKind.mouse,
                                                  },),
                                                  child: Container(
                                                    width: smallWindow ? maxWidth * 0.5
                                                        : maxWidth * 0.3,
                                                    height: smallWindow ? maxHeight * 0.5
                                                        : maxHeight * 0.3,
                                                    alignment: Alignment.center,
                                                    child: ListView.builder(
                                                        scrollDirection: Axis.vertical,
                                                        shrinkWrap: true,
                                                        itemCount: configList.length,
                                                        itemBuilder: (context, index) {
                                                          return Padding(
                                                            padding: const EdgeInsets.all(8.0),
                                                            child: ClipRect(
                                                              child: Slidable(
                                                                key: UniqueKey(),
                                                                startActionPane: ActionPane(
                                                                    motion: const ScrollMotion(),
                                                                    children: [
                                                                      SlidableAction(
                                                                        onPressed: (BuildContext context) async {
                                                                          await editJsonFile(imuConfigFile, configList[index], delete: true);
                                                                          showDialog(
                                                                              context: context,
                                                                              builder: (context) => BackdropFilter(
                                                                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                                                                  child: AlertDialog(
                                                                                    content: Padding(
                                                                                      padding: const EdgeInsets.all(8.0),
                                                                                      child: Column(
                                                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                                                        mainAxisSize: MainAxisSize.min,
                                                                                        children: [
                                                                                          const Padding(
                                                                                            padding: EdgeInsets.all(8.0),
                                                                                            child: Text(
                                                                                              'Configuration deleted',
                                                                                              style: TextStyle(
                                                                                                color: Colors.green,
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          Padding(
                                                                                            padding: const EdgeInsets.all(8.0),
                                                                                            child: FloatingActionButton(
                                                                                                heroTag: 'Return after imu config delete',
                                                                                                backgroundColor: Colors.black.withOpacity(0.6),
                                                                                                child: const FittedBox(
                                                                                                  fit: BoxFit.scaleDown,
                                                                                                  child: Padding(
                                                                                                    padding: EdgeInsets.all(8.0),
                                                                                                    child: Text(
                                                                                                      'Back',
                                                                                                      style: TextStyle(color: Colors.white),
                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                                onPressed: () {
                                                                                                  Navigator.of(context).popUntil((route) => route.settings.name == 'setup_route');
                                                                                                }
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                  )
                                                                              )
                                                                          );
                                                                        },
                                                                        backgroundColor: Colors.red,
                                                                        foregroundColor: Colors.white,
                                                                        icon: Icons.delete,
                                                                        label: 'Delete',
                                                                      ),
                                                                      SlidableAction(
                                                                        onPressed: (BuildContext context) {
                                                                          List imusList = jsonData[configList[index]]['imus'];
                                                                          List feedbacksList = jsonData[configList[index]]['feedbacks'];
                                                                          ref.read(imusCounter).setImuCount(imusList.length);
                                                                          widget.addedIMUs['imus']?.clear();
                                                                          widget.addedIMUs['feedbacks']?.clear();
                                                                          for(int i = 0; i < imusList.length; i++) {
                                                                            widget.addedIMUs['imus']?.add(TextFieldClass(
                                                                              controller: TextEditingController(),
                                                                            ));
                                                                            widget.addedIMUs['imus']?.last.imuMac = imusList[i];
                                                                          }
                                                                          for(int i = 0; i < feedbacksList.length; i++) {
                                                                            widget.addedIMUs['feedbacks']?.add(TextFieldClass(
                                                                              controller: TextEditingController(),
                                                                            ));
                                                                            widget.addedIMUs['feedbacks']?.last.imuMac = feedbacksList[i];
                                                                          }

                                                                          expanded[0] = imusList.isNotEmpty;
                                                                          expanded[1] = feedbacksList.isNotEmpty;
                                                                          Navigator.of(context).popUntil((route) => route.settings.name == 'setup_route');
                                                                        },
                                                                        backgroundColor: Colors.green,
                                                                        foregroundColor: Colors.white,
                                                                        icon: Icons.check_outlined,
                                                                        label: 'Select',
                                                                      )
                                                                    ]
                                                                ),
                                                                child: ExpansionTile(
                                                                    collapsedTextColor: Theme.of(context).textTheme.bodyText1?.color,
                                                                    collapsedIconColor: Theme.of(context).textTheme.bodyText1?.color,
                                                                    title: SelectableText(configList[index]),
                                                                    children: [
                                                                      Padding(
                                                                        padding: const EdgeInsets.all(8.0),
                                                                        child: SelectableText(
                                                                            'IMUs:',
                                                                            style: Theme.of(context).textTheme.bodyText1,
                                                                        ),
                                                                      ),
                                                                      Padding(
                                                                        padding: const EdgeInsets.all(8.0),
                                                                        child: Column(
                                                                          children: List.generate(jsonData[configList[index]]['imus'].length,
                                                                                  (imusIndex)
                                                                                  => SelectableText(jsonData[configList[index]]['imus'][imusIndex],
                                                                                          style: Theme.of(context).textTheme.bodyText1,)
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Padding(
                                                                        padding: const EdgeInsets.all(8.0),
                                                                        child: SelectableText('Feedbacks:',
                                                                            style: Theme.of(context).textTheme.bodyText1,),
                                                                      ),
                                                                      Padding(
                                                                        padding: const EdgeInsets.all(8.0),
                                                                        child: Column(
                                                                          children: List.generate(jsonData[configList[index]]['feedbacks'].length,
                                                                                  (feedbacksIndex)
                                                                                  => SelectableText(jsonData[configList[index]]['feedbacks'][feedbacksIndex],
                                                                                          style: Theme.of(context).textTheme.bodyText1,)
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ]
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          )
                                      );
                                    }
                                );
                                setState(() {});
                              }
                          ),
                        ),
                        Padding(
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
                                  await Future.delayed(const Duration(milliseconds: 500));
                                }

                                if(mounted) await Navigator.of(context).pushNamed('imus_route');
                                setState(() {});
                              }
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),

            ),
          ),
        ),
      ),
    ];

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
