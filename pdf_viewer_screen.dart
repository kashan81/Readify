import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:readify_app/data/models/book_model.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PDFViewerScreen extends StatefulWidget {
  final Book book;

  const PDFViewerScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final PdfViewerController _pdfViewerController = PdfViewerController();
  
  // TTS State
  late FlutterTts _flutterTts;
  bool _isTtsPanelVisible = false;
  bool _isPlaying = false;
  bool _isExtractingText = false;
  String _currentTtsStatus = 'Ready to read';
  
  // PDF Data
  PdfDocument? _pdfDocument;
  int _currentReadingPage = 1; // 1-indexed for Syncfusion PdfViewer
  int _totalPdfPages = 0;
  double _speechRate = 0.5;
  List<String> _textChunks = [];
  int _currentChunkIndex = 0;
  PdfTextSearchResult? _searchResult; // Added for highlight

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    _flutterTts = FlutterTts();
    
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    String lang = widget.book.language.toLowerCase();
    String ttsLang = 'en-US';
    if (lang.contains('ur') || lang.contains('urdu')) {
      ttsLang = 'ur-PK';
    } else if (lang.contains('ar') || lang.contains('arabic')) {
      ttsLang = 'ar-SA';
    } else if (lang.contains('fr') || lang.contains('french')) {
      ttsLang = 'fr-FR';
    } else if (lang.contains('es') || lang.contains('spanish')) {
      ttsLang = 'es-ES';
    }
    
    try {
      await _flutterTts.setLanguage(ttsLang);
    } catch (e) {
      await _flutterTts.setLanguage('en-US');
    }

    _flutterTts.setCompletionHandler(() {
      if (_isPlaying) {
        _currentChunkIndex++;
        if (_currentChunkIndex < _textChunks.length) {
          _playCurrentChunk();
        } else if (_currentReadingPage < _totalPdfPages) {
          _readNextPage();
        } else {
          setState(() {
            _isPlaying = false;
            _currentTtsStatus = 'Finished reading';
            _searchResult?.clear();
          });
        }
      }
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isPlaying = false;
        _currentTtsStatus = 'TTS Error: $msg';
      });
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _searchResult?.clear();
    _pdfDocument?.dispose();
    super.dispose();
  }

  Future<void> _downloadPdfIfNecessary() async {
    if (_pdfDocument != null) return;
    
    setState(() {
      _isExtractingText = true;
      _currentTtsStatus = 'Downloading PDF for extraction...';
    });

    try {
      final response = await http.get(Uri.parse(widget.book.bookUrl!));
      if (response.statusCode == 200) {
        _pdfDocument = PdfDocument(inputBytes: response.bodyBytes);
        _totalPdfPages = _pdfDocument!.pages.count;
      } else {
        throw Exception('Failed to download PDF');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentTtsStatus = 'Error downloading: $e';
          _isPlaying = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExtractingText = false;
        });
      }
    }
  }

  List<String> _chunkText(String text, int maxLength) {
    List<String> chunks = [];
    while (text.length > maxLength) {
      int splitIdx = text.lastIndexOf(RegExp(r'[.!?]'), maxLength);
      if (splitIdx == -1 || splitIdx < maxLength - 150) {
         splitIdx = text.lastIndexOf(' ', maxLength);
         if (splitIdx == -1) splitIdx = text.lastIndexOf('\n', maxLength);
         if (splitIdx == -1) splitIdx = maxLength;
      } else {
         splitIdx++;
      }
      chunks.add(text.substring(0, splitIdx));
      text = text.substring(splitIdx);
    }
    if (text.trim().isNotEmpty) {
      chunks.add(text);
    }
    return chunks;
  }

  void _playCurrentChunk() async {
    if (_currentChunkIndex < _textChunks.length) {
      String rawChunk = _textChunks[_currentChunkIndex];
      String speakChunk = rawChunk.replaceAll('\n', ' ').replaceAll('\r', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      
      if (mounted) {
         setState(() {
           _isExtractingText = false;
           _currentTtsStatus = 'Reading page $_currentReadingPage of $_totalPdfPages\nSpeed: ${(_speechRate * 2).toStringAsFixed(1)}x (Part ${_currentChunkIndex + 1}/${_textChunks.length})';
         });
      }
      
      // Highlight logic in parallel
      if (rawChunk.trim().length > 5) {
         _searchResult?.clear();
         _searchResult = _pdfViewerController.searchText(rawChunk.trim());
      }

      var result = await _flutterTts.speak(speakChunk);
      if (result == 1) {
         if (mounted) {
           setState(() => _isPlaying = true);
         }
      }
    }
  }

  Future<void> _extractAndPlayPage(int pageIndex) async {
    if (_pdfDocument == null) return;

    if (mounted) {
      setState(() {
        _isExtractingText = true;
        _currentTtsStatus = 'Extracting text for page $pageIndex...';
      });
    }

    try {
      final extractor = PdfTextExtractor(_pdfDocument!);
      String text = extractor.extractText(startPageIndex: pageIndex - 1, endPageIndex: pageIndex - 1);
      
      if (text.trim().isEmpty) {
         if (mounted) {
           setState(() {
             _currentTtsStatus = 'No text found on page $pageIndex. Skipping...';
             _isExtractingText = false;
           });
         }
         if (_isPlaying && pageIndex < _totalPdfPages) {
           await Future.delayed(const Duration(seconds: 1));
           if (mounted && _isPlaying) {
             _readNextPage();
           }
         } else if (pageIndex >= _totalPdfPages) {
           if (mounted) {
             setState(() {
               _isPlaying = false;
               _currentTtsStatus = 'Finished reading. No more pages.';
             });
           }
         }
         return;
      }

      // Chunk size reduced to 250 characters to comfortably isolate paragraphs/lines for precise highlighting
      _textChunks = _chunkText(text, 250);
      _currentChunkIndex = 0;
      _playCurrentChunk();

    } catch (e) {
      if (mounted) {
        setState(() {
          _isExtractingText = false;
          _isPlaying = false;
          _currentTtsStatus = 'Text extraction not available for this book.';
        });
      }
    }
  }

  void _playPlay() async {
    if (_pdfDocument == null) {
      await _downloadPdfIfNecessary();
    }
    if (_pdfDocument != null) {
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
      if (_textChunks.isNotEmpty && _currentChunkIndex < _textChunks.length) {
         _playCurrentChunk();
      } else {
         _extractAndPlayPage(_currentReadingPage);
      }
    }
  }
  
  void _pause() async {
    await _flutterTts.stop();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _currentTtsStatus = 'Paused on page $_currentReadingPage';
      });
    }
  }
  
  void _stop() async {
    await _flutterTts.stop();
    _searchResult?.clear();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _currentReadingPage = 1;
        _pdfViewerController.jumpToPage(1);
        _currentTtsStatus = 'Ready to read';
      });
    }
  }

  void _readNextPage() async {
    _searchResult?.clear();
    if (_pdfDocument == null) await _downloadPdfIfNecessary();
    if (_pdfDocument != null && _currentReadingPage < _totalPdfPages) {
      if (mounted) {
        setState(() => _isPlaying = true);
        _currentReadingPage++;
        _pdfViewerController.jumpToPage(_currentReadingPage);
      }
      _extractAndPlayPage(_currentReadingPage);
    } else if (_currentReadingPage >= _totalPdfPages) {
       _stop();
       if (mounted) {
         setState(() {
             _currentTtsStatus = 'Already at the last page.';
         });
       }
    }
  }

  void _readPreviousPage() async {
    _searchResult?.clear();
    if (_pdfDocument == null) await _downloadPdfIfNecessary();
    if (_pdfDocument != null && _currentReadingPage > 1) {
      if (mounted) {
        setState(() => _isPlaying = true);
        _currentReadingPage--;
        _pdfViewerController.jumpToPage(_currentReadingPage);
      }
      _extractAndPlayPage(_currentReadingPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1B2A),
      appBar: AppBar(
        title: Text(
          widget.book.title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1F27),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.volume_up,
              color: Colors.white,
              semanticLabel: 'Listen to Book',
            ),
            onPressed: () {
              setState(() {
                _isTtsPanelVisible = !_isTtsPanelVisible;
              });
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.bookmark,
              color: Colors.white,
              semanticLabel: 'Bookmark',
            ),
            onPressed: () {
              _pdfViewerKey.currentState?.openBookmarkView();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          widget.book.bookUrl == null || widget.book.bookUrl!.isEmpty
              ? const Center(
                  child: Text(
                    'PDF not available for this book.',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                )
              : SfPdfViewer.network(
                  widget.book.bookUrl!,
                  key: _pdfViewerKey,
                  controller: _pdfViewerController,
                  canShowScrollHead: false,
                  canShowScrollStatus: false,
                  onPageChanged: (PdfPageChangedDetails details) {
                    if (!_isPlaying && !_isExtractingText) {
                      _currentReadingPage = details.newPageNumber;
                      _textChunks = [];
                    }
                  },
                ),
          
          if (_isTtsPanelVisible && widget.book.bookUrl != null && widget.book.bookUrl!.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 30,
              child: _buildTtsPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildTtsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F27).withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (_isExtractingText)
                const Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                  ),
                )
              else 
                const Icon(Icons.record_voice_over, color: Colors.blueAccent, size: 20),
              if (!_isExtractingText) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentTtsStatus,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: () {
                  setState(() {
                    _isTtsPanelVisible = false;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          
          // Subtitle box
          if (_isPlaying && _textChunks.isNotEmpty && _currentChunkIndex < _textChunks.length)
             Container(
               width: double.infinity,
               margin: const EdgeInsets.only(top: 12, bottom: 4),
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: Colors.black45,
                 borderRadius: BorderRadius.circular(10),
                 border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 1)
               ),
               child: Text(
                 _textChunks[_currentChunkIndex].replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim(),
                 style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4, fontWeight: FontWeight.w500),
                 maxLines: 4,
                 overflow: TextOverflow.ellipsis,
               ),
             ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white, size: 28),
                onPressed: _readPreviousPage,
              ),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent,
                ),
                child: IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 36),
                  onPressed: () {
                    if (_isPlaying) {
                      _pause();
                    } else {
                      _playPlay();
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.stop, color: Colors.white, size: 28),
                onPressed: _stop,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
                onPressed: _readNextPage,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.speed, color: Colors.white54, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _speechRate,
                  min: 0.25,
                  max: 1.25,
                  divisions: 8,
                  activeColor: Colors.blueAccent,
                  inactiveColor: Colors.grey[800],
                  onChanged: (value) {
                    setState(() {
                      _speechRate = value;
                    });
                    _flutterTts.setSpeechRate(_speechRate);
                  },
                  onChangeEnd: (value) async {
                    if (_isPlaying) {
                      await _flutterTts.stop();
                      _playCurrentChunk();
                    }
                  },
                ),
              ),
              Text(
                '${(_speechRate * 2).toStringAsFixed(1)}x',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
