import 'package:flutter/material.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/collection.dart';

import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/database.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/core/components/sub_components/document.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/wrapper/nosql_stateful_wrapper.dart';
import 'package:flutter_nosql_v1/plugins/nosql_database/wrapper/nosql_utilities.dart';
import 'package:flutter_nosql_v1/ui/utilities/utilities.dart';

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
          body: const DatabasesScreen(),
          commitStates: const [
            AppLifecycleState.inactive,
          ],
        ),
      ),
    );
  }
}

class DatabasesScreen extends StatefulWidget {
  const DatabasesScreen({
    super.key,
  });

  @override
  State<DatabasesScreen> createState() => _DatabasesScreenState();
}

class _DatabasesScreenState extends State<DatabasesScreen> {
  final NoSQLUtility noSQLUtility = NoSQLUtility();

  final TextEditingController nameController = TextEditingController();

  var formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter NoSql"),
      ),
      body: Form(
        key: formKey,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder(
                  future: noSQLUtility.getDatabases(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return StreamBuilder(
                      stream: noSQLUtility.getDatabaseStream(),
                      initialData: snapshot.data,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: Text(
                              "No Database found",
                            ),
                          );
                        }
                        List<Database>? data = snapshot.data;

                        if (data!.isEmpty) {
                          return const Center(
                            child: Text(
                              "Empty. Please create a database",
                            ),
                          );
                        }

                        return Column(
                          children: [
                            Text("Databases (${data.length})"),
                            Expanded(
                              child: ListView.separated(
                                itemCount: data.length,
                                itemBuilder: (context, index) {
                                  var db = data[index];
                                  return Dismissible(
                                    key: Key(db.objectId),
                                    direction: DismissDirection.endToStart,
                                    confirmDismiss: (direction) async {
                                      bool results = false;

                                      await showShouldAlertDialog(
                                        context: context,
                                        setResults: (res) {
                                          results = res;
                                        },
                                        title: const Text(
                                          "Delete Database",
                                        ),
                                        content: Text(
                                          'Are you sure you want to delete ( ${db.name} ) database. This action can not be undone',
                                        ),
                                      );

                                      return results;
                                    },
                                    onDismissed: (direction) {
                                      noSQLUtility.deleteDatabase(
                                        name: db.name,
                                      );
                                    },
                                    background: Container(
                                      color: Colors.redAccent,
                                      child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                          ),
                                          Text(
                                            "Delete",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        goToPage(
                                          context: context,
                                          page: DatabaseScreen(
                                            database: db,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: double.maxFinite,
                                        padding: const EdgeInsets.all(24.0),
                                        decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius:
                                              BorderRadius.circular(16.0),
                                        ),
                                        child: Text(db.name),
                                      ),
                                    ),
                                  );
                                },
                                separatorBuilder: (context, index) {
                                  return const SizedBox(
                                    height: 16.0,
                                  );
                                },
                              ),
                            )
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              TextFormField(
                controller: nameController,
                validator: (value) {
                  if (value!.trim().isEmpty) {
                    return "Database name is required";
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Database name",
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!formKey.currentState!.validate()) {
            return;
          }

          bool res = await noSQLUtility.createDatabase(
            name: nameController.text,
          );

          if (res) {
            nameController.text = "";
            if (context.mounted) FocusScope.of(context).unfocus();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class DatabaseScreen extends StatefulWidget {
  final Database database;
  const DatabaseScreen({
    super.key,
    required this.database,
  });

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  final NoSQLUtility noSQLUtility = NoSQLUtility();

  final TextEditingController nameController = TextEditingController();

  var formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.database.name} Database"),
      ),
      body: Form(
        key: formKey,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder(
                  future: noSQLUtility.getCollections(
                    databaseName: widget.database.name,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return StreamBuilder(
                      stream: noSQLUtility.getCollectionStream(
                        databaseName: widget.database.name,
                      ),
                      initialData: snapshot.data,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: Text(
                              "No Collection found",
                            ),
                          );
                        }
                        var data = snapshot.data;

                        if (data!.isEmpty) {
                          return const Center(
                            child: Text(
                              "Empty. Please create a collection",
                            ),
                          );
                        }
                        return Column(
                          children: [
                            Text("Collections (${data.length})"),
                            Expanded(
                              child: ListView.separated(
                                itemCount: data.length,
                                itemBuilder: (context, index) {
                                  var collection = data[index];

                                  return Dismissible(
                                    key: Key(collection.objectId),
                                    direction: DismissDirection.endToStart,
                                    confirmDismiss: (direction) async {
                                      bool results = false;

                                      await showShouldAlertDialog(
                                        context: context,
                                        title: const Text(
                                          "Delete Collection",
                                        ),
                                        content: Text(
                                          'Are you sure you want to delete ( ${collection.name} ) collection. This action can not be undone',
                                        ),
                                        setResults: (res) {
                                          results = res;
                                        },
                                      );

                                      return results;
                                    },
                                    onDismissed: (direction) {
                                      noSQLUtility.deleteCollection(
                                        reference:
                                            "${widget.database.name}.${collection.name}",
                                      );
                                    },
                                    background: Container(
                                      color: Colors.redAccent,
                                      child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                          ),
                                          Text(
                                            "Delete",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        goToPage(
                                          context: context,
                                          page: CollectionScreen(
                                            database: widget.database,
                                            collection: collection,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: double.maxFinite,
                                        padding: const EdgeInsets.all(24.0),
                                        decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius:
                                              BorderRadius.circular(16.0),
                                        ),
                                        child: Text(collection.name),
                                      ),
                                    ),
                                  );
                                },
                                separatorBuilder: (context, index) {
                                  return const SizedBox(
                                    height: 16.0,
                                  );
                                },
                              ),
                            )
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              TextFormField(
                controller: nameController,
                validator: (value) {
                  if (value!.trim().isEmpty) {
                    return "Collection name is required";
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Collection name",
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!formKey.currentState!.validate()) {
            return;
          }

          bool res = await noSQLUtility.createCollection(
            reference: "${widget.database.name}.${nameController.text}",
          );

          if (res) {
            nameController.text = "";
            if (context.mounted) FocusScope.of(context).unfocus();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CollectionScreen extends StatefulWidget {
  final Database database;
  final Collection collection;

  const CollectionScreen({
    super.key,
    required this.database,
    required this.collection,
  });

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final NoSQLUtility noSQLUtility = NoSQLUtility();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  var formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    var ref = "${widget.database.name}.${widget.collection.name}";

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.collection.name} Colection"),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder(
                future: noSQLUtility.getDocuments(
                  reference: ref,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return StreamBuilder(
                    stream: noSQLUtility.getDocumentStream(
                      reference: ref,
                    ),
                    initialData: snapshot.data,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Text(
                            "No Document found",
                          ),
                        );
                      }
                      var data = snapshot.data;

                      if (data!.isEmpty) {
                        return const Center(
                          child: Text(
                            "Empty. Please create a Document",
                          ),
                        );
                      }
                      return Column(
                        children: [
                          Text("Documents (${data.length})"),
                          Expanded(
                            child: ListView.separated(
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                Document document = data[index];
                                return Dismissible(
                                  key: Key(document.objectId),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (direction) async {
                                    bool results = false;

                                    await showShouldAlertDialog(
                                      context: context,
                                      title: const Text(
                                        "Delete Document",
                                      ),
                                      content: Text(
                                        'Are you sure you want to delete ( ${document.objectId} ) Document. This action can not be undone',
                                      ),
                                      setResults: (res) {
                                        results = res;
                                      },
                                    );

                                    return results;
                                  },
                                  onDismissed: (direction) {
                                    noSQLUtility.removeDocument(
                                      reference: ref,
                                      query: (doc) {
                                        return doc.objectId ==
                                            document.objectId;
                                      },
                                    );
                                  },
                                  background: Container(
                                    color: Colors.redAccent,
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                        Text(
                                          "Delete",
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  child: GestureDetector(
                                    onTap: () {},
                                    child: Container(
                                      padding: const EdgeInsets.all(24.0),
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius:
                                            BorderRadius.circular(16.0),
                                      ),
                                      child: Text(
                                        "${document.toJson(serialize: true)}",
                                      ),
                                    ),
                                  ),
                                );
                              },
                              separatorBuilder: (context, index) {
                                return const SizedBox(
                                  height: 16.0,
                                );
                              },
                            ),
                          )
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Form(
        key: formKey,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.525,
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextFormField(
                      controller: nameController,
                      validator: (value) {
                        if (value!.trim().isEmpty) {
                          return "Name is required";
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        hintText: "Name",
                      ),
                    ),
                    TextFormField(
                      controller: ageController,
                      validator: (value) {
                        if (value!.trim().isEmpty) {
                          return "Age is required";
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        hintText: "Age",
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        hintText: "Description",
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () async {
                      nameController.text = "";
                      ageController.text = "";
                      descriptionController.text = "";
                    },
                    icon: const Icon(
                      Icons.cancel_outlined,
                      size: 36.0,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      bool res = await noSQLUtility.insertDocument(
                        reference:
                            "${widget.database.name}.${widget.collection.name}",
                        data: {
                          "name": nameController.text,
                          "age": ageController.text,
                          "description": descriptionController.text,
                        },
                      );

                      if (res) {
                        nameController.text = "";
                        ageController.text = "";
                        descriptionController.text = "";
                        if (context.mounted) FocusScope.of(context).unfocus();
                      }
                    },
                    icon: const Icon(
                      Icons.check,
                      size: 36.0,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showShouldAlertDialog({
  required BuildContext context,
  required void Function(bool res) setResults,
  Widget? title,
  Widget? content,
}) async {
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: title,
        content: content,
        actions: [
          TextButton(
            onPressed: () {
              setResults(true);
              Navigator.of(context).pop();
            },
            child: const Text("Delete"),
          ),
          TextButton(
            onPressed: () {
              setResults(false);
              Navigator.of(context).pop();
            },
            child: const Text("Cancel"),
          ),
        ],
      );
    },
  );
}
