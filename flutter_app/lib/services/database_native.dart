import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Future<void> initializeDatabaseFactory() async {
}

Future<String> getDatabasePath(String dbName) async {
  final dbPath = await getDatabasesPath();
  return join(dbPath, dbName);
}
