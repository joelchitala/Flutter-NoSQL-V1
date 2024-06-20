import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> checkPermissions({required BuildContext context}) async {
  PermissionStatus storagePermission = await Permission.storage.status;

  if (storagePermission.isDenied || storagePermission.isPermanentlyDenied) {
    PermissionStatus status = await Permission.manageExternalStorage.request();

    if (status.isDenied) {
      if (context.mounted) showRequestStoragePermissionDialog(context: context);
    }
  }
}

void showRequestStoragePermissionDialog({required BuildContext context}) {
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
              if (context.mounted) checkPermissions(context: context);
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
