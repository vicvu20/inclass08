import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('card_organizer.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {

    await db.execute('''
    CREATE TABLE folders(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      folder_name TEXT NOT NULL,
      timestamp TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE cards(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      card_name TEXT NOT NULL,
      suit TEXT NOT NULL,
      image_url TEXT,
      folder_id INTEGER NOT NULL,
      FOREIGN KEY (folder_id) REFERENCES folders (id)
      ON DELETE CASCADE
    )
    ''');

    await _prepopulateFolders(db);
    await _prepopulateCards(db);
  }

  Future _prepopulateFolders(Database db) async {

    final folders = [
      'Hearts',
      'Spades',
      'Diamonds',
      'Clubs'
    ];

    for (var suit in folders) {
      await db.insert('folders', {
        'folder_name': suit,
        'timestamp': DateTime.now().toIso8601String()
      });
    }
  }

  Future _prepopulateCards(Database db) async {

    final suits = [
      'Hearts',
      'Spades',
      'Diamonds',
      'Clubs'
    ];

    final ranks = [
      {'name':'Ace','code':'A'},
      {'name':'2','code':'2'},
      {'name':'3','code':'3'},
      {'name':'4','code':'4'},
      {'name':'5','code':'5'},
      {'name':'6','code':'6'},
      {'name':'7','code':'7'},
      {'name':'8','code':'8'},
      {'name':'9','code':'9'},
      {'name':'10','code':'0'},
      {'name':'Jack','code':'J'},
      {'name':'Queen','code':'Q'},
      {'name':'King','code':'K'}
    ];

    String suitLetter(String suit) {

      switch (suit) {

        case 'Hearts':
          return 'H';

        case 'Spades':
          return 'S';

        case 'Diamonds':
          return 'D';

        case 'Clubs':
          return 'C';

        default:
          return 'H';
      }
    }

    for (int i = 0; i < suits.length; i++) {

      final suit = suits[i];
      final folderId = i + 1;

      for (var rank in ranks) {

        final code = "${rank['code']}${suitLetter(suit)}";

        final imageUrl =
        "https://deckofcardsapi.com/static/img/$code.png";

        await db.insert('cards', {
          'card_name': rank['name'],
          'suit': suit,
          'image_url': imageUrl,
          'folder_id': folderId
        });

      }
    }
  }
}