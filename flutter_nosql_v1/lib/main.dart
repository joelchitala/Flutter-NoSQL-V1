import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/utilities/fileoperations.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/wrapper/NoSqlUtilities.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: NoSQLStatefulWrapper(),
      ),
    );
  }
}

class NoSQLStatefulWrapper extends StatefulWidget {
  const NoSQLStatefulWrapper({super.key});

  @override
  State<NoSQLStatefulWrapper> createState() => _NoSQLStatefulWrapperState();
}

class _NoSQLStatefulWrapperState extends State<NoSQLStatefulWrapper>
    with WidgetsBindingObserver {
  NoSQLUtility noSQLUtility = NoSQLUtility();

  Map<String, dynamic> data = {};

  void setData(Map<String, dynamic> newData) {
    setState(() {
      data = newData;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    // noSQLUtility.createDatabase(name: "school");
    // noSQLUtility.createCollection(
    //   reference: "school.students",
    // );
    // noSQLUtility.insertDocument(
    //   reference: "school.students",
    //   data: {"name": "Joel"},
    //   callback: ({error, res}) {
    //     print(error);
    //   },
    // );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter NoSQL"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Expanded(
              child: SizedBox(
                width: double.maxFinite,
                // color: Colors.amber,
                child: SingleChildScrollView(
                  child: Text(data.toString()),
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () async {
                      // setData(
                      //   await noSQLUtility.noSQLDatabaseToJson(serialize: true),
                      // );

                      try {
                        await noSQLUtility.initialize();
                        setData(
                          await noSQLUtility.noSQLDatabaseToJson(
                            serialize: true,
                          ),
                        );
                      } catch (e) {
                        print(e);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: const Text("Read database"),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      bool res = await noSQLUtility.commitToDisk();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: const Text("Save database"),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _checkPermissions() async {
    PermissionStatus storagePermission =
        await Permission.manageExternalStorage.status;

    if (storagePermission.isDenied || storagePermission.isPermanentlyDenied) {
      showRequestStoragePermissionDialog();
    }
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
                _checkPermissions();
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
