// favorites_page.dart
import 'package:flutter/material.dart';
import 'book_manager.dart';
import 'pdf_viewer_page.dart';

class FavoritesPage extends StatefulWidget {
  //Buton güncellem için callback fonksiyonu
  final VoidCallback onFavoritesUpdated; 

  const FavoritesPage({super.key, required this.onFavoritesUpdated});

  @override
  FavoritesPageState createState() => FavoritesPageState();
}

class FavoritesPageState extends State<FavoritesPage> {
  List<Book> favoritePdfs = [];

  @override
  void initState() {
    super.initState();
    loadFavoritePdfs();
  }

  // Favoriler listesini SharedPreferences'den yükleme
  Future<void> loadFavoritePdfs() async {
    favoritePdfs = await BookStorage.loadFavorites();
    setState(() {});
  }

  // Favorilerden bir PDF'yi silme işlemi
  Future<void> removeFromFavorites(String pdfPath) async {
    await BookStorage.removeFavorite(pdfPath);
    loadFavoritePdfs(); 
    widget.onFavoritesUpdated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Favoriler"),
      ),
      body: favoritePdfs.isEmpty
          ? Center(child: Text("Favorilere eklenmiş PDF bulunmuyor."))
          : ListView.builder(
              itemCount: favoritePdfs.length,
              itemBuilder: (context, index) {
                String pdfPath = favoritePdfs[index].path;
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
                        favoritePdfs[index].name,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            removeFromFavorites(pdfPath),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PDFViewerPage( filePath: pdfPath, 
                                isDarkMode: Theme.of(context).brightness == Brightness.dark,
                            )
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
