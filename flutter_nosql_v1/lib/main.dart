import 'package:flutter/material.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/nosql_manager.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_transactional/nosql_transactional.dart';
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
  // await initDB(NoSQlInitilizationObject(initializeFromDisk: true));
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
          body: Center(
            child: GestureDetector(
              onTap: () async {
                NoSQLManager manager = NoSQLManager();
                NoSQLUtility noSQLUtility = NoSQLUtility();

                print(manager.getNoSqlDatabase().toJson(serialize: true));

                NoSQLTransactional transactional = NoSQLTransactional(
                  executeFunction: () async {
                    await noSQLUtility.createDatabase(name: "myriad");

                    NoSQLTransactional transactional = NoSQLTransactional(
                      executeFunction: () async {
                        await noSQLUtility.createDatabase(name: "middlesex");
                      },
                    );

                    await transactional.execute();
                  },
                );

                await transactional.execute();

                print("");
                print(manager.getNoSqlDatabase().toJson(serialize: true));

                await transactional.commit();

                print("");
                print("commit");
                print(manager.noSQLDatabase.toJson(serialize: true));
              },
              child: Text("Transactional"),
            ),
          ),
          // body: const NoSQLDatabaseScreen(),
          // commitStates: const [
          //   AppLifecycleState.inactive,
          // ],
        ),
      ),
    );
  }
}
