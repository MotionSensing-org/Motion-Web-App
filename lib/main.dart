import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'LandingPage/chart_dash_route.dart';
import 'LandingPage/dash_control.dart';
import 'LandingPage/imus_route.dart';
import 'LandingPage/providers.dart';
import 'LandingPage/setup_route.dart';

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
    } else if(settings.name == 'setup_route') {
      return CustomRoute(
          settings: RouteSettings(name: settings.name),
          builder: (context) => ProviderScope(child: SetupPage(properties: properties, addedIMUs: addedIMUs,))
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
  double logoOpacity = 0;
  late Process p;

  @override
  void dispose() {
    p.kill();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Timer.run(() {setState(() {
      logoOpacity = 1;
    });});

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
                onEnd: () async {
                  await Future.delayed(const Duration(seconds: 1));
                  if(mounted) Navigator.of(context).pushNamed('setup_route');
                },
                opacity: logoOpacity,
                duration: const Duration(seconds: 3),
                child: const Image(image: AssetImage('assets/images/logo_round.png'))
            )
          ],
        ),
      ),
    );
  }
}
