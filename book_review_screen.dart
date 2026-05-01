import 'package:flutter/material.dart';
import 'package:readify_app/data/models/book_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:readify_app/view/screens/pdf_viewer_screen.dart';

class BookReviewScreen extends StatelessWidget {
  final Book book;

  const BookReviewScreen({Key? key, required this.book}) : super(key: key);

  void _openPdfUrl(BuildContext context) {
    final url = book.bookUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No PDF file associated with this book.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(book: book),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayImage = book.coverUrl?.isNotEmpty == true ? book.coverUrl! : book.imageUrl;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1B2A),
      appBar: AppBar(
        title: const Text('Book Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0E1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Image
            Center(
              child: Container(
                width: 160,
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                  image: displayImage.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(displayImage),
                          fit: BoxFit.cover,
                          onError: (_, __) => const Icon(Icons.book, size: 80, color: Colors.grey),
                        )
                      : null,
                ),
                child: displayImage.isEmpty ? const Icon(Icons.book, size: 80, color: Colors.grey) : null,
              ),
            ),
            const SizedBox(height: 24),

            // Title and Author
            Text(
              book.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              book.author,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Details Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F27),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildDetailRow('Genre/Category', book.category, Icons.category),
                   const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.grey, height: 1)),
                   _buildDetailRow('Language', book.language, Icons.language),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              book.description,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 48),

            // Open PDF Button
            ElevatedButton.icon(
              onPressed: () => _openPdfUrl(context),
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text(
                'Open Book',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}
