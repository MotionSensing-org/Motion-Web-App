import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'chart_dash.dart';


//ignore: must_be_immutable
class IMUList extends ConsumerStatefulWidget {
  IMUList({Key? key, required this.addedIMUs, this.isFeedbackList=false}) : super(key: key);
  List<TextFieldClass> addedIMUs;
  bool isFeedbackList;

  List<String> getList() => addedIMUs.map((e) => e.imuMac).toList();

  @override
  ConsumerState<IMUList> createState() => _IMUListState();
}

class _IMUListState extends ConsumerState<IMUList> {
  List imus = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: FloatingActionButton(
            heroTag: 'Add ${widget.isFeedbackList ? 'feedback' : 'IMU'}',
            onPressed: () {
              setState(() {
                if(!widget.isFeedbackList) {
                  ref.read(imusCounter).inc();
                }

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
                          if(!widget.isFeedbackList) {
                            ref.read(imusCounter).dec();
                          }

                          widget.addedIMUs.removeAt(index);
                        });
                      }),
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (BuildContext context) {
                            setState(() {
                              if(!widget.isFeedbackList) {
                                ref.read(imusCounter).dec();
                              }

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
                        style: Theme.of(context).textTheme.bodyText1,
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

//ignore: must_be_immutable
class IMUsRoute extends ConsumerStatefulWidget{
  IMUsRoute({super.key, required this.addedIMUs, required this.properties});
  Map<String, List<TextFieldClass>> addedIMUs = {'imus': [], 'feedbacks': []};
  Map properties;

  @override
  ConsumerState<IMUsRoute> createState() => _IMUsRoute();
}

class _IMUsRoute extends ConsumerState<IMUsRoute> {
  @override
  Widget build(BuildContext context) {
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
            child: Builder(
              builder: (context) {
                return FutureBuilder(
                    future: ref.read(requestAnswerProvider).connectToIMUs(widget.addedIMUs),
                    builder: (BuildContext context, AsyncSnapshot snapshot){
                      if(snapshot.hasError) {
                        return ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: const BorderRadius.all(Radius.circular(10))
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Failed to connect to IMUs',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      switch(snapshot.connectionState) {
                        case ConnectionState.done:
                          ref.read(requestAnswerProvider).startStopDataCollection();
                          var connectedIMUs = jsonDecode(snapshot.data)['connection_state'];
                          ref.read(requestAnswerProvider).imus = connectedIMUs['imus'];
                          ref.read(requestAnswerProvider).shouldInitBuffers = true;
                          ref.read(requestAnswerProvider).startStopDataCollection(stop: false);

                          return ClipRRect(
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
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Connected successfully to IMUs: \nIMUs: ${connectedIMUs['imus']}, Feedbacks: ${connectedIMUs['feedbacks']}',
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
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: Theme.of(context).cardColor,
                                            borderRadius: const BorderRadius.all(Radius.circular(10))
                                        ),
                                        child: TextButton(
                                            onPressed: () {
                                              // ref.read(requestAnswerProvider).startStopDataCollection(stop: false);
                                              Navigator.pop(context);
                                            },
                                            child: const Text(
                                                'Continue',
                                              style: TextStyle(color: Colors.green),
                                            )
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        default: //waiting for completion
                          return ClipRRect(
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                  decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: const BorderRadius.all(Radius.circular(10))
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(),
                                  )
                              ),
                            ),
                          );
                      }
                    }
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}