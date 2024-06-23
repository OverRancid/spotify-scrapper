import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:spotify/song.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'songs.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE songs(id INTEGER PRIMARY KEY, name TEXT, artists TEXT)',
        );
      },
    );
  }

  Future<void> insertSong(Song song) async {
    final db = await database;
    await db.insert('songs', song.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Song>> getSongs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('songs');

    return List.generate(maps.length, (i) {
      return Song(
        name: maps[i]['name'],
        artists: (maps[i]['artists'] as String).split(', '),
      );
    });
  }

  Future<void> deleteSong(String name) async {
    final db = await database;
    await db.delete('songs', where: 'name = ?', whereArgs: [name]);
  }

  Future<void> deleteSongByIndex(int index) async {
    final db = await database;
    final List<Song> songs = await getSongs();
    
    if (index >= 0 && index < songs.length) {
      final Song songToDelete = songs[index];
      await db.delete('songs', where: 'name = ?', whereArgs: [songToDelete.name]);
    } else {
      throw Exception('Index out of bounds');
    }
  }
}
