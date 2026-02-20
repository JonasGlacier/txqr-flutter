import 'package:flutter/material.dart';
import 'screens/scanner_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TxqrApp());
}

class TxqrApp extends StatelessWidget {
  const TxqrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TXQR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const ScannerScreen(),
    );
  }
}
