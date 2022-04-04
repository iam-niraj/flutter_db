import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SQLiteApp());
}

class SQLiteApp extends StatefulWidget {
  const SQLiteApp({Key? key}) : super(key: key);

  @override
  State<SQLiteApp> createState() => _SQLiteAppState();
}

class _SQLiteAppState extends State<SQLiteApp> {
  int? selectedId;
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: textController,
          ),
        ),
        body: Center(
          child: FutureBuilder<List<Students>>(
              future: DatabaseHelper.instance.getStudents(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<Students>> snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: Text("Loading"),
                  );
                }
                return snapshot.data!.isEmpty
                    ? Center(child: Text("No Data"))
                    : ListView(
                        children: snapshot.data!.map((students) {
                          return Center(
                            child: Card(
                              color: selectedId == students.id
                                  ? Colors.white70
                                  : Colors.white,
                              child: ListTile(
                                onTap: () {
                                  setState(() {
                                    if (selectedId == null) {
                                      textController.text = students.name;
                                      selectedId = students.id;
                                    } else{
                                      textController.text = '';
                                      selectedId = null;
                                    }
                                  });
                                }, 
                                onLongPress: () {
                                  setState(() {
                                    DatabaseHelper.instance
                                        .delete(students.id!);
                                    selectedId = null;
                                  });
                                },
                                title: Text(students.name),
                              ),
                            ),
                          );
                        }).toList(),
                      );
              }),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            selectedId != null
                ? await DatabaseHelper.instance.update(
                    Students(id: selectedId, name: textController.text),
                  )
                : await DatabaseHelper.instance.add(
                    Students(name: textController.text),
                  );
            setState(() {
              textController.clear();
              selectedId = null;
            });
          },
          child: Icon(Icons.save),
        ),
      ),
    );
  }
}

class Students {
  final int? id;
  final String name;

  Students({this.id, required this.name});

  factory Students.fromMap(Map<String, dynamic> res) =>
      new Students(id: res['id'], name: res['name']);

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }
}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'students.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students(
        id INTEGER PRIMARY KEY,
        name TEXT
    )''');
  }

  Future<List<Students>> getStudents() async {
    Database db = await instance.database;
    var students = await db.query('students', orderBy: 'name');
    List<Students> studentsList = students.isNotEmpty
        ? students.map((e) => Students.fromMap(e)).toList()
        : [];
    return studentsList;
  }

  Future<int> add(Students students) async {
    Database db = await instance.database;
    return await db.insert('students', students.toMap());
  }

  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete('students', where: 'id=?', whereArgs: [id]);
  }

  Future<int> update(Students students) async {
    Database db = await instance.database;
    return await db.update('students', students.toMap(),
        where: 'id=?', whereArgs: [students.id]);
  }
}
