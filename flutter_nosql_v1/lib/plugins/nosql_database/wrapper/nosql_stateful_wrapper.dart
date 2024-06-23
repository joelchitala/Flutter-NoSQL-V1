import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/wrapper/nosql_utilities.dart';
import 'package:permission_handler/permission_handler.dart';

class NoSQlInitilizationObject {
  String databasePath;
  bool initializeFromDisk;

  NoSQlInitilizationObject({
    required this.initializeFromDisk,
    this.databasePath = "database.json",
  });
}

class NoSQLStatefulWrapper extends StatefulWidget {
  final Function({
    String? error,
    String? success,
  })? callback;

  final Widget body;
  final bool checkPermissions;
  final List<AppLifecycleState> commitStates;
  final String databasePath;
  final bool initializeFromDisk;

  const NoSQLStatefulWrapper({
    super.key,
    required this.initializeFromDisk,
    required this.checkPermissions,
    required this.body,
    this.databasePath = "database.json",
    this.callback,
    this.commitStates = const [],
  });

  @override
  State<NoSQLStatefulWrapper> createState() => _NoSQLStatefulWrapperState();
}

class _NoSQLStatefulWrapperState extends State<NoSQLStatefulWrapper>
    with WidgetsBindingObserver {
  NoSQLUtility noSQLUtility = NoSQLUtility();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (widget.commitStates.contains(state)) {
      noSQLUtility.commitToDisk(
        databasePath: widget.databasePath,
      );
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.checkPermissions) _checkPermissions();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();

    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return widget.body;
  }

  Future<bool> _checkPermissions({bool prompt = true}) async {
    bool results = true;

    PermissionStatus storagePermission =
        await Permission.manageExternalStorage.status;

    if (storagePermission.isDenied || storagePermission.isPermanentlyDenied) {
      if (prompt) showRequestStoragePermissionDialog();
      results = false;
    }

    return results;
  }

  void showRequestStoragePermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'This app needs storage permissions to function properly.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Grant Permission'),
              onPressed: () async {
                Navigator.of(context).pop();
                await Permission.manageExternalStorage.request();
                bool res = await _checkPermissions();

                if (res && widget.initializeFromDisk) {
                  noSQLUtility.initialize(
                    databasePath: widget.databasePath,
                  );
                }
              },
            ),
            TextButton(
              child: const Text('Close App'),
              onPressed: () {
                // Close the app
                Navigator.of(context).pop();
                Future.delayed(const Duration(milliseconds: 100), () {
                  SystemNavigator.pop();
                  exit(0);
                });
              },
            ),
          ],
        );
      },
    );
  }
}
