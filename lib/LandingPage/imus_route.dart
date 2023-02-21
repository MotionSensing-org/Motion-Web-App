import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_project/LandingPage/providers.dart';

//ignore: must_be_immutable
class IMUsRoute extends ConsumerStatefulWidget{
  IMUsRoute({super.key, required this.addedIMUs, required this.properties});
  Map<String, List<TextFieldClass>> addedIMUs = {'imus': [], 'feedbacks': []};
  Map properties;

  @override
  ConsumerState<IMUsRoute> createState() => _IMUsRoute();
}

class _IMUsRoute extends ConsumerState<IMUsRoute> {
  final stopwatch = Stopwatch();

  @override
  void initState() {
    stopwatch.start();
    super.initState();
  }

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
                      if(snapshot.hasError || stopwatch.elapsedMilliseconds > 20000) {
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
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Failed to connect to IMUs',
                                      style: TextStyle(color: Colors.red),
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
                                            ref.read(requestAnswerProvider).connectionSuccessful(false);
                                            Navigator.pop(context);
                                          },
                                          child: const Text(
                                            'Back',
                                            style: TextStyle(color: Colors.grey),
                                          )
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      switch(snapshot.connectionState) {
                        case ConnectionState.done:
                          ref.read(dataProvider).startStopDataCollection();
                          print(utf8.decode(snapshot.data).runtimeType);
                          var connectedIMUs = jsonDecode(utf8.decode(snapshot.data))['set_imus'];
                          ref.read(dataProvider).imus = connectedIMUs['imus'];
                          Future((){ref.read(imusListProvider).updateList(connectedIMUs['imus'], connectedIMUs['feedbacks']);});
                          ref.read(dataProvider).shouldInitBuffers = true;
                          ref.read(requestAnswerProvider).connectionSuccess = true;

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
                                      child: SelectableText(
                                        'Connected successfully to IMUs:',
                                        style: TextStyle(
                                            color: Colors.black.withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: SelectableText(
                                        '${connectedIMUs['imus']}',
                                        style: const TextStyle(
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: SelectableText(
                                        'Feedbacks:',
                                        style: TextStyle(
                                          color: Colors.black.withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: SelectableText(
                                        '${connectedIMUs['feedbacks']}',
                                        style: const TextStyle(
                                          color: Colors.green,
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
                                              ref.read(requestAnswerProvider).connectionSuccessful(true);
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