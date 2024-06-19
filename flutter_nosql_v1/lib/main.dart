import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/utilities/fileoperations.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/utilities/showStorageRequest.dart';
import 'package:permission_handler/permission_handler.dart';

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
  void initState() {
    super.initState();
    // bool results = await checkPermissions();

    // if (!results && context.mounted) {
    //   showStoragePermissionDialog(context: context);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
