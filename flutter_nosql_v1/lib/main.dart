import 'package:flutter/material.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/wrapper/nosql_stateful_wrapper.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/wrapper/nosql_utilities.dart';
import 'package:flutter_nosql_v1/ui/screens/nosql_database_screen.dart';

Future<void> initDB(NoSQlInitilizationObject initilizationObject) async {
  NoSQLUtility noSQLUtility = NoSQLUtility();
  try {
    if (initilizationObject.initializeFromDisk) {
      await noSQLUtility.initialize(
        databasePath: initilizationObject.databasePath,
        loggerPath: initilizationObject.loggerPath,
      );
    }
  } catch (_) {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDB(NoSQlInitilizationObject(initializeFromDisk: true));
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: NoSQLStatefulWrapper(
          checkPermissions: true,
          initilizationObject: NoSQlInitilizationObject(
            initializeFromDisk: false,
          ),
          body: const NoSQLDatabaseScreen(),
          commitStates: const [
            AppLifecycleState.inactive,
          ],
        ),
      ),
    );
  }
}
