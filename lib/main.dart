import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spotify/main_screen.dart';

void main() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // Set theme mode to system
      theme: ThemeData.light(), // Default theme (light theme)
      darkTheme: ThemeData.dark(), // Dark theme
      home: MainScreen(),
    );
  }
}
