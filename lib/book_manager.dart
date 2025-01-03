import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Book {
  String name;
  String path;
  int lastPage;

  Book({
    required this.name,
    required this.path,
    this.lastPage = 0,
  });

  // JSON'a dönüştürme için map'e çevirme
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'path': path,
      'lastPage': lastPage,
    };
  }

  // JSON'dan nesneye dönüştürme
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      name: map['name'],
      path: map['path'],
      lastPage: map['lastPage'] ?? 0,
    );
  }
}

class BookStorage {
  static const String _recentBooksKey =
      'recent_books'; // Recent kitaplar anahtarı
  static const String _favoriteBooksKey =
      'favorite_books'; // Favori kitaplar anahtarı
  static String get recentBooksKey => _recentBooksKey;

  // Kitapları SharedPreferences'a kaydetme
  static Future<void> saveBooks(List<Book> books, String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> booksJson =
        books.map((book) => jsonEncode(book.toMap())).toList();
    await prefs.setStringList(key, booksJson);
  }

  // Kitapları SharedPreferences'dan yükleme
  static Future<List<Book>> loadBooks(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? booksJson = prefs.getStringList(key);
    if (booksJson == null) {
      return [];
    }
    List<Book> books = booksJson
        .map((bookJson) => Book.fromMap(jsonDecode(bookJson)))
        .toList();
    return books;
  }

  // Yeni bir kitabı recent'e ekleme veya mevcut kitabı güncelleme
  static Future<void> addOrUpdateRecent(Book book) async {
    List<Book> books = await loadBooks(_recentBooksKey);

    String normalizedName = book.name.trim().toLowerCase();

    int index = books.indexWhere((b) {
      String normalizedBookName = b.name.trim().toLowerCase();

      return normalizedBookName == normalizedName;
    });

    if (index != -1) {
      books[index] = book;
    } else {
      books.insert(0, book);
    }

    if (books.length > 20) {
      books = books.sublist(0, 20);
    }
    await saveBooks(books, _recentBooksKey);
  }

  // Kitabı recent'den silme
  static Future<void> removeRecent(String path) async {
    List<Book> books = await loadBooks(_recentBooksKey);
    books.removeWhere((book) => book.path == path);
    await saveBooks(books, _recentBooksKey);
  }

  static Future<List<Book>> loadRecents() async {
    return await loadBooks(_recentBooksKey);
  }

  // Kitabı favorilere ekleme/çıkarma
  static Future<void> toggleFavorite(Book book) async {
    List<Book> favorites = await loadBooks(_favoriteBooksKey);
    int index = favorites.indexWhere((b) => b.path == book.path);
    if (index != -1) {
      favorites.removeAt(index);
    } else {
      favorites.add(book);
    }
    await saveBooks(favorites, _favoriteBooksKey);
  }

  // Favori kitapları yükleme
  static Future<List<Book>> loadFavorites() async {
    return await loadBooks(_favoriteBooksKey);
  }

  // Favorilerden kitabı silme
  static Future<void> removeFavorite(String path) async {
    List<Book> books = await loadBooks(_favoriteBooksKey);
    books.removeWhere((book) => book.path == path);
    await saveBooks(books, _favoriteBooksKey);
  }

  //Belirli bir kitap için son kalınan sayfayı güncelleme
  static Future<void> updateLastPage(String filePath, int lastPage) async {
    List<Book> books = await loadBooks(_recentBooksKey);
    int index = books.indexWhere((b) => b.path == filePath);
    if (index != -1) {
      books[index].lastPage = lastPage;
      await saveBooks(books, _recentBooksKey);
    }
  }

  // Okunan kitaptan son kalınan sayfayı alma
  static Future<int> getLastPage(String filePath) async {
    List<Book> books = await loadBooks(_recentBooksKey);
    int index = books.indexWhere((b) => b.path == filePath);
    if (index != -1) {
      return books[index].lastPage;
    }
    return 0;
  }

  /* Kitabın adını güncelleme fonksiyonu filepicker dan kaynaklı daha önceden eklenmiş pdfleri
  eklememek için kullandığım path karşılaştırması işe yaramadığı için kaldırıldı
  static Future<void> updateBookName(String oldPath, String newName) async {
    List<Book> recentBooks = await loadBooks(_recentBooksKey);
    int recentIndex = recentBooks.indexWhere((book) => book.path == oldPath);

    if (recentIndex != -1) {
      recentBooks[recentIndex].name = newName;
    }

    List<Book> favoriteBooks = await loadBooks(_favoriteBooksKey);
    int favoriteIndex =
        favoriteBooks.indexWhere((book) => book.path == oldPath);

    if (favoriteIndex != -1) {
      favoriteBooks[favoriteIndex].name = newName;
    }

    await saveBooks(recentBooks, _recentBooksKey);
    await saveBooks(favoriteBooks, _favoriteBooksKey);
  }*/
}
