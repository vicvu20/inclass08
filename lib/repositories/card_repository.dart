import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/card.dart';

class CardRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // CREATE
  Future<int> insertCard(PlayingCard card) async {
    final db = await _dbHelper.database;
    return db.insert('cards', card.toMap());
  }

  // READ - all cards
  Future<List<PlayingCard>> getAllCards() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      orderBy: 'id ASC',
    );

    return List.generate(maps.length, (i) => PlayingCard.fromMap(maps[i]));
  }

  // READ - by folder id
  Future<List<PlayingCard>> getCardsByFolderId(int folderId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'card_name ASC',
    );

    return List.generate(maps.length, (i) => PlayingCard.fromMap(maps[i]));
  }

  // READ - by id
  Future<PlayingCard?> getCardById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return PlayingCard.fromMap(maps.first);
  }

  // UPDATE
  Future<int> updateCard(PlayingCard card) async {
    final db = await _dbHelper.database;
    return db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // DELETE
  Future<int> deleteCard(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // COUNT cards in a folder
  Future<int> getCardCountByFolder(int folderId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cards WHERE folder_id = ?',
      [folderId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // MOVE card to different folder
  Future<int> moveCardToFolder(int cardId, int newFolderId) async {
    final db = await _dbHelper.database;
    return db.update(
      'cards',
      {'folder_id': newFolderId},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }
}