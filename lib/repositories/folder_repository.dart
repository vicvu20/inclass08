import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/folder.dart';

class FolderRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // CREATE
  Future<int> insertFolder(Folder folder) async {
    final db = await _dbHelper.database;
    return db.insert('folders', folder.toMap());
  }

  // READ - all folders
  Future<List<Folder>> getAllFolders() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'folders',
      orderBy: 'id ASC',
    );

    return List.generate(maps.length, (i) => Folder.fromMap(maps[i]));
  }

  // READ - by id
  Future<Folder?> getFolderById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Folder.fromMap(maps.first);
  }

  // UPDATE
  Future<int> updateFolder(Folder folder) async {
    final db = await _dbHelper.database;
    return db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // DELETE (CASCADE handles cards)
  Future<int> deleteFolder(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // COUNT
  Future<int> getFolderCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM folders');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}