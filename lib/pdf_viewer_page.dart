import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'book_manager.dart';

class PDFViewerPage extends StatefulWidget {
  final String filePath;
  final bool isDarkMode;
  const PDFViewerPage(
      {super.key, required this.filePath, required this.isDarkMode});

  @override
  PDFViewerPageState createState() => PDFViewerPageState();
}

class PDFViewerPageState extends State<PDFViewerPage> {
  bool _isAppBarVisible = true;
  bool _isSliderVisible = true;
  int _currentPage = 0;
  int startPage = 0;
  int _totalPages = 0;
  late PDFViewController _pdfViewController;

  @override
  void initState() {
    super.initState();
    _loadLastPage();
  }

  @override
  void dispose() {
    _saveLastPage(_currentPage);
    super.dispose();
  }

  // en son okununan sayfayı yükler
  Future<void> _loadLastPage() async {
    try {
      int lastPage = await BookStorage.getLastPage(widget.filePath);
      setState(() {
        startPage = lastPage;
      });

      // Eğer PDF yüklendiyse, sayfayı manuel olarak ayarla
      if (startPage > 0) {
        _pdfViewController.setPage(startPage);
      }
    } catch (e) {
      debugPrint("Sayfa yükleme hatası: $e");
    }
  }

  // Kaldığı sayfayı kaydetme
  Future<void> _saveLastPage(int page) async {
    await BookStorage.updateLastPage(widget.filePath, page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onDoubleTap: () {
              setState(() {
                _isAppBarVisible = !_isAppBarVisible;
                _isSliderVisible =
                    !_isSliderVisible; 
              });
            },
            onTap: () {
              setState(() {
                _isAppBarVisible = !_isAppBarVisible;
                _isSliderVisible =
                    !_isSliderVisible;
              });
            },
            child: Container(
              color: widget.isDarkMode ? Colors.black : Colors.white,
              child: PDFView(
                filePath: widget.filePath,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: true,
                pageFling: true,
                nightMode: widget.isDarkMode ? true : false,
                backgroundColor:
                    widget.isDarkMode ? Colors.black : Colors.white,
                fitPolicy: FitPolicy.BOTH,
                defaultPage: startPage,
                onRender: (pages) {
                  setState(() {
                    _totalPages = pages ?? 0;
                  });
                },
                onViewCreated: (controller) async {
                  _pdfViewController = controller;
                  await Future.delayed(Duration(
                      milliseconds: 500));

                  if (startPage > 0) {
                    await _pdfViewController.setPage(startPage);
                    setState(() {
                      _currentPage = startPage;
                    });
                  }
                },
                onPageChanged: (current, total) {
                  setState(() {
                    _currentPage = current ?? 0;
                    _totalPages = total ?? 0;
                  });
                  _saveLastPage(_currentPage);
                },
                onError: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("PDF görüntüleme hatası: $error")),
                  );
                },
                onPageError: (page, error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Sayfa hatası: $error")),
                  );
                },
              ),
            ),
          ),
          if (_isAppBarVisible)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                backgroundColor: const Color.fromARGB(255, 50, 93, 133),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                title: Text("Sayfa $_currentPage / $_totalPages"),
              ),
            ),
          if (_isSliderVisible)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    _totalPages > 1
                        ? Slider(
                            value: _currentPage.toDouble(),
                            min: 0,
                            max: _totalPages.toDouble(),
                            divisions: _totalPages > 1 ? _totalPages - 1 : 0,
                            label: '$_currentPage',
                            onChanged: (double value) {
                              setState(() {
                                _currentPage = value.toInt();
                              });
                              _pdfViewController.setPage(_currentPage);
                            },
                          )
                        : Container(),
                    Text(
                      "Sayfa $_currentPage / $_totalPages",
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
