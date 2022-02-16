import 'package:flutter/material.dart';

import 'src/functions.dart';

import 'screens/home_screens.dart';

import '../src/functions.dart';

void main() async {
  await checkConfigFiles();
  await checkOutputDir();
  await scanFolder();
  runApp(const ArtorLightApp());
}

class ArtorLightApp extends StatelessWidget {
  const ArtorLightApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
      theme: ThemeData(
          textButtonTheme: TextButtonThemeData(
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.black)))),
    );
  }
}
