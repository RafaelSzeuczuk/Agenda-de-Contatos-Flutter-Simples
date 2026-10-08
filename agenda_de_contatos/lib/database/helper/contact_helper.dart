import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../model/contact_model.dart';

class ContactHelper {
  ContactHelper._internal();

  static final ContactHelper _instance = ContactHelper._internal();

  factory ContactHelper() => _instance;

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    final databasesPath = await getDatabasesPath();
    final databasePath = join(databasesPath, 'contactsDB.db');

    return openDatabase(
      databasePath,
      version: 3,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE $contactTable (
            $idColumn INTEGER PRIMARY KEY AUTOINCREMENT,
            $nameColumn TEXT NOT NULL,
            $emailColumn TEXT NOT NULL,
            $phoneColumn TEXT NOT NULL,
            $imgColumn TEXT,
            $cepColumn TEXT,
            $addressColumn TEXT,
            $numberColumn TEXT,
            $complementColumn TEXT,
            $neighborhoodColumn TEXT,
            $cityColumn TEXT,
            $stateColumn TEXT
          )
        ''');
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          for (final column in <String>[
            cepColumn,
            addressColumn,
            numberColumn,
            neighborhoodColumn,
            cityColumn,
            stateColumn,
          ]) {
            await database.execute(
              'ALTER TABLE $contactTable ADD COLUMN $column TEXT',
            );
          }
        }
        if (oldVersion < 3) {
          await database.execute(
            'ALTER TABLE $contactTable ADD COLUMN $complementColumn TEXT',
          );
        }
      },
    );
  }

  Future<Contact> saveContact(Contact contact) async {
    final database = await db;
    contact.id = await database.insert(contactTable, contact.toMap());
    return contact;
  }

  Future<Contact?> getContact(int id) async {
    final database = await db;
    final rows = await database.query(
      contactTable,
      where: '$idColumn = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Contact.fromMap(rows.first);
  }

  Future<List<Contact>> getAllContacts() async {
    final database = await db;
    final rows = await database.query(contactTable);
    return rows.map(Contact.fromMap).toList();
  }

  Future<int> deleteContact(int id) async {
    final database = await db;
    return database.delete(
      contactTable,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateContact(Contact contact) async {
    final database = await db;
    return database.update(
      contactTable,
      contact.toMap(),
      where: '$idColumn = ?',
      whereArgs: [contact.id],
    );
  }
}
