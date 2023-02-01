import 'dart:io';
import 'dart:ui';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_project/LandingPage/providers.dart';
import 'package:file_picker/file_picker.dart';

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

    params.add(Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(10))
        ),
        child: TextButton(onPressed: () async {
            ref.read(dataProvider).filename = widget.properties['output_file'];
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

            ref.read(dataProvider).startStopDataCollection();
            ref.read(requestAnswerProvider).setParamsMap(widget.properties);
            ref.read(requestAnswerProvider).setAlgParams();
            ref.read(dataProvider).startStopDataCollection(stop: false);
            await Navigator.of(context).pushNamed('chart_dash_route');
            ref.read(requestAnswerProvider).clearOutputFileName();
            dropdownValue = '';
            ref.read(chosenAlgorithmProvider).clearChosenAlg();
          },
          child: const Text('Start', style: TextStyle(color: Colors.green),)),
      ),
    ));

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
    if(ref.read(requestAnswerProvider).algorithms.isEmpty) {
      ref.read(requestAnswerProvider).getAlgList();
    }

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
                                      ref.read(chosenAlgorithmProvider).setChosenAlg(value!);
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
                      crossFadeState: ref.watch(chosenAlgorithmProvider).chosenAlg == '' ? CrossFadeState.showFirst
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
class DashControlRoute extends ConsumerStatefulWidget{
  DashControlRoute({super.key, required this.properties});
  Map properties;

  @override
  ConsumerState<DashControlRoute> createState() => _DashControlRoute();
}

class _DashControlRoute extends ConsumerState<DashControlRoute> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          const Image(
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              image: AssetImage('assets/images/bg.png')
          ),
          Builder(
              builder: (context) {
                return ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DashControl(properties: widget.properties,),
                        ],
                      )
                  ),
                );
              }
          ),
        ],
      ),
    );
  }
}