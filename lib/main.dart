import 'home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pointsSP = StateProvider<List<Offset>>((ref) => []);
final redosSP = StateProvider<List<Offset>>((ref) => []);

final isPolygonSP = StateProvider<bool>((ref) => false);
final isAttractedSP = StateProvider<bool>((ref) => false);


void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}
