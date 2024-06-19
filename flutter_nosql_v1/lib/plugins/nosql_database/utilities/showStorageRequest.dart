import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/utilities/fileoperations.dart';
import 'package:permission_handler/permission_handler.dart';

void showStoragePermissionDialog({required BuildContext context}) {
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
              // await openAppSettings();
              // bool results = await checkPermissions();

              // if (!results && context.mounted) {
              //   showStoragePermissionDialog(context: context);
              // }
            },
          ),
          TextButton(
            child: const Text('Close App'),
            onPressed: () {
              Navigator.of(context).pop();
              Future.delayed(
                const Duration(milliseconds: 100),
                () {
                  SystemNavigator.pop();
                  exit(0);
                },
              );
            },
          ),
        ],
      );
    },
  );
}
