import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: NoSQLWrapper(),
      ),
    );
  }
}

class NoSQLWrapper extends StatefulWidget {
  const NoSQLWrapper({super.key});

  @override
  State<NoSQLWrapper> createState() => _NoSQLWrapperState();
}

class _NoSQLWrapperState extends State<NoSQLWrapper>
    with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
