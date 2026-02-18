import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/data.dart';
import 'providers/detection_provider.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  runApp(const CorlyApp());
}

class CorlyApp extends StatelessWidget {
  const CorlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Setup repository dan detector
    final detector = TFLiteDetector();
    final repository = DetectionRepositoryImpl(detector);

    return ChangeNotifierProvider(
      create: (_) => DetectionProvider(repository),
      child: MaterialApp(
        title: 'Corly - Coral Bleaching Detection',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
