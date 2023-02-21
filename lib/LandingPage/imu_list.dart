import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:iot_project/LandingPage/providers.dart';


/*We define here a widget named "IMUList" 
//ignore: must_be_immutable
class IMUList extends ConsumerStatefulWidget {
  IMUList({Key? key, required this.addedIMUs, this.isFeedbackList=false}) : super(key: key);
  List<TextFieldClass> addedIMUs;
  bool isFeedbackList;

  List<String> getList() => addedIMUs.map((e) => e.imuMac).toList(); // Returns a list of the IMU MAC addresses from the addedIMUs list.

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
          child: FloatingActionButton(  //A FloatingActionButton used to add new items to the list
            heroTag: 'Add ${widget.isFeedbackList ? 'feedback' : 'IMU'}',
            backgroundColor: Colors.black.withOpacity(0.6),
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
        Flexible( //A ListView used to display the items in the list.
          child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.addedIMUs.length,
              itemBuilder: (context, index) {
                return Slidable(
                  key: UniqueKey(), //The Slidable widget provides an action pane that slides out from the left.
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
                  child: Center( // Each item in the list is a row containing a text field and a delete button.
                    child: FractionallySizedBox(
                      widthFactor: 0.7,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            fit: FlexFit.loose,
                            child: TextFormField(
                              style: TextStyle(color: Colors.black.withOpacity(0.6)),
                              textAlign: TextAlign.center,
                              controller: widget.addedIMUs[index].controller..text = widget.addedIMUs[index].imuMac,
                              onChanged: (value) {
                                widget.addedIMUs[index].imuMac = value;
                                // ref.read(imusProvider).addIMU(value, isFeedback: widget.isFeedbackList);
                              },
                            ),
                          ),
                          Flexible(
                            fit: FlexFit.loose,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Tooltip(
                                message: 'Remove',
                                child: Card(
                                  color: Colors.red,
                                  shape: const CircleBorder(),
                                  child: IconButton(onPressed: (){
                                    setState(() {
                                      if(!widget.isFeedbackList) {
                                        ref.read(imusCounter).dec();
                                      }

                                      widget.addedIMUs.removeAt(index);
                                    });
                                  }, icon: const Icon(Icons.delete, color: Colors.white,)),
                                ),
                              ),
                            ),
                          )
                        ],
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
