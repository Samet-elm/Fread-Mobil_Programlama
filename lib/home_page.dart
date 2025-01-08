import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'pdf_viewer_page.dart';
import 'favorites_page.dart';
import 'book_manager.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const HomePage({super.key, required this.onToggleTheme});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<Book> recentPdfs = [];
  List<Book> favoritePdfs = [];

  @override
  void initState() {
    super.initState();
    loadRecentPdfs();
    loadFavoritePdfs();
  }

  // Son açılan pdfleri yükleme
  Future<void> loadRecentPdfs() async {
    recentPdfs = await BookStorage.loadRecents();
    if (mounted) setState(() {});
  }

  // Favori kitapları(pdf formatında) yükleme
  Future<void> loadFavoritePdfs() async {
    favoritePdfs = await BookStorage.loadFavorites();
    if (mounted) setState(() {});
  }

  //recent listesine yeni bir kitap(pdf) ekleme
  Future<void> addToRecent(String pdfPath) async {
    String pdfName = pdfPath.split('/').last;

    Book newBook = Book(name: pdfName, path: pdfPath);

    await BookStorage.addOrUpdateRecent(newBook);
    loadRecentPdfs();
  }

  // favori listesine kitap ekleme ve çıkarma işlemleri yapar
  Future<void> toggleFavorite(String pdfPath) async {
    Book book = Book(name: pdfPath.split('/').last, path: pdfPath);
    await BookStorage.toggleFavorite(book);
    loadFavoritePdfs();
  }

  // recent listesinden kitap silme işlemi yapar
  Future<void> removeFromRecent(String pdfName) async {
    recentPdfs.removeWhere((book) => book.name == pdfName);
    await BookStorage.saveBooks(recentPdfs, BookStorage.recentBooksKey);
    if (mounted) setState(() {});
  }

  // PDF seçme işlemi
  Future<void> _pickFile() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (!mounted) return;

    if (result != null && result.files.single.path != null) {
      String selectedPdfPath = result.files.single.path!;
      await addToRecent(selectedPdfPath);
      navigator.push(
        MaterialPageRoute(
            builder: (context) => PDFViewerPage(
                  filePath: selectedPdfPath,
                  isDarkMode: Theme.of(context).brightness == Brightness.dark,
                )),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text("PDF seçimi iptal edildi.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("FRead"),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.file_open),
            color: Colors.black,
            onPressed: _pickFile,
          ),
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            color: Colors.black,
            onPressed: widget.onToggleTheme,
          ),
        ],
        backgroundColor: const Color.fromARGB(255, 50, 93, 133),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 50, 93, 133),
              ),
              child: Text(
                'Menü',
                style: TextStyle(
                  color: const Color.fromARGB(255, 239, 232, 232),
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Anasayfa'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('Favoriler'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FavoritesPage(
                      onFavoritesUpdated: loadFavoritePdfs,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: recentPdfs.length,
              itemBuilder: (context, index) {
                String pdfName = recentPdfs[index].name;
                String pdfPath = recentPdfs[index].path;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: Icon(
                        Icons.book,
                        color: Colors.blue,
                        size: 32,
                      ),
                      title: Text(
                        pdfName,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              favoritePdfs.any((book) => book.path == pdfPath)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: favoritePdfs
                                      .any((book) => book.path == pdfPath)
                                  ? Colors.red
                                  : null,
                            ),
                            onPressed: () => toggleFavorite(pdfPath),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => removeFromRecent(pdfName),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PDFViewerPage(
                              filePath: pdfPath,
                              isDarkMode: Theme.of(context).brightness ==
                                  Brightness.dark,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "PDF seçmek için app bar'daki simgeye tıklayın.",
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
