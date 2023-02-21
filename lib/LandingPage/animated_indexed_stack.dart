import 'package:flutter/cupertino.dart';

/* First page of the web 
Flutter widget that animates the transition between 
two or more child widgets 
using the IndexedStack widget as a base */

class AnimatedIndexedStack extends StatefulWidget {
  final int index; //index of the currently displayed child widget
  final List<Widget> children; //list of child widgets
  final Duration duration; //represents the animation duration

  // constructor for the AnimatedIndexedStack widget
  const AnimatedIndexedStack({
    Key? key,
    required this.index,
    required this.children,
    this.duration = const Duration(
      milliseconds: 800,
    ),
  }) : super(key: key);
  

  // create a state for the AnimatedIndexedStack widget
  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

// the state for the AnimatedIndexedStack widget
class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;  // the animation controller for the animation

  // update the widget
  @override
  void didUpdateWidget(AnimatedIndexedStack oldWidget) {

    // if the index has changed, start the animation from the beginning
    if (widget.index != oldWidget.index) {
      _controller.forward(from: 0.0);
    }

    super.didUpdateWidget(oldWidget);
  }

  // initialize the state
  @override
  void initState() {

    // create a new animation controller with the given duration
    _controller = AnimationController(vsync: this, duration: widget.duration);

    // start the animation
    _controller.forward();

    super.initState();
  }

  // dispose of the resources used by the state
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // build the widget
  @override
  Widget build(BuildContext context) {

    // return a ScaleTransition widget, which animates the scale of its child
    return ScaleTransition(
      scale: _controller,

      // the child is an IndexedStack widget, which shows one child at a time from a list of children
      child: IndexedStack(
        alignment: Alignment.center,
        index: widget.index,
        children: widget.children,
      ),
    );
  }
}
