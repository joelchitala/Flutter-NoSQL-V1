import 'package:flutter/material.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/nosql_database.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/collection.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/database.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/document.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/nosql_manager.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/nosql_meta/components/restriction_object.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/utilities/utils.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/wrapper/nosql_stateful_wrapper.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/wrapper/nosql_utilities.dart';
import 'package:flutter_nosql_v1/ui/screens/nosql_database_screen.dart';

Future<void> initDB(NoSQlInitilizationObject initilizationObject) async {
  NoSQLUtility noSQLUtility = NoSQLUtility();
  try {
    if (initilizationObject.initializeFromDisk) {
      await noSQLUtility.initialize(
        databasePath: initilizationObject.databasePath,
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
          initializeFromDisk: true,
          checkPermissions: true,
          body: const NoSQLDatabaseScreen(),
          commitStates: const [
            AppLifecycleState.inactive,
          ],

          // body: const Center(),
          // floatingActionButton: FloatingActionButton(
          //   onPressed: () async {
          //     NoSQLUtility sqlUtility = NoSQLUtility();

          //     // print(await sqlUtility.noSQLDatabaseToJson(serialize: true));

          //     await sqlUtility.createDatabase(name: "myriad");
          //     await sqlUtility.createCollection(reference: "myriad.staff");

          //     await sqlUtility.setRestrictions(
          //       reference: "myriad.staff",
          //       builder: RestrictionBuilder()
          //           .addField(
          //             key: "name",
          //             unique: true,
          //             expectedType: String,
          //           )
          //           .addValue(
          //             key: "age",
          //             expectedValues: [25],
          //             type: RestrictionValueTypes.eqgt,
          //           ),
          //     );

          //     try {
          //       var transactional = sqlUtility.transactional(
          //         () async {
          //           await sqlUtility.insertDocuments(
          //             reference: "myriad.staff",
          //             data: [
          //               {
          //                 "name": "Mike",
          //                 "age": 35,
          //               },
          //               {
          //                 "name": "Mike",
          //                 "age": 30,
          //               },
          //               {
          //                 "name": "Jane",
          //                 "age": 27,
          //                 "gender": "Female",
          //               },
          //             ],
          //           );

          //           // await sqlUtility.updateDocuments(
          //           //   reference: "myriad.staff",
          //           //   query: (document) => document.fields["name"] == "Jane",
          //           //   data: {
          //           //     "age": 38,
          //           //     "!unset": ["gender"]
          //           //   },
          //           // );

          //           // await sqlUtility.removeDocuments(
          //           //   reference: "myriad.staff",
          //           //   query: (document) => document.fields["name"] == "Mike",
          //           // );

          //           await sqlUtility.removeCollection(reference: "myriad.staff");
          //         },
          //       );

          //       var res = await transactional.execute();

          //       // print(res);
          //       // print(NoSQLManager().currentDB.toJson(serialize: true));

          //       await transactional.commit();
          //       // print("");
          //       // print(NoSQLManager().currentDB.toJson(serialize: true));

          //       // print("");
          //       // print(
          //       //   transactional.noSQLDatabase?.toJson(
          //       //     serialize: true,
          //       //   ),
          //       // );
          //     } catch (e) {
          //       print(e);
          //     }
          //   },
          //   child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
