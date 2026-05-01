import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readify_app/data/models/book_model.dart';
import 'package:readify_app/data/repositories/book_repository.dart';
import 'package:readify_app/view/screens/admin_edit_book_screen.dart';

class AdminBooksTab extends StatelessWidget {
  const AdminBooksTab({Key? key}) : super(key: key);

  void _deleteBook(BuildContext context, BookRepository bookRepo, Book book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F27),
        title: const Text('Delete Book', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to completely delete "${book.title}"?', 
            style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await bookRepo.deleteBookData(book.id, book);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Book deleted'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookRepo = Provider.of<BookRepository>(context, listen: false);

    return Stack(
      children: [
        StreamBuilder<List<Book>>(
          stream: bookRepo.getAllBooksStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3)));
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading books', style: TextStyle(color: Colors.red)));
            }
            
            final books = snapshot.data ?? [];
            if (books.isEmpty) {
              return const Center(
                child: Text('No books found', style: TextStyle(color: Colors.grey)),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80), // Padding for FAB
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                final isApproved = book.status == 'approved';
                final isPending = book.status == 'pending';
                
                return Card(
                  color: const Color(0xFF1A1F27),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Cover Image
                        Container(
                          width: 50,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E1B2A),
                            borderRadius: BorderRadius.circular(8),
                            image: book.coverUrl != null && book.coverUrl!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(book.coverUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: (book.coverUrl == null || book.coverUrl!.isEmpty)
                              ? const Icon(Icons.image_not_supported, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                book.author,
                                style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isApproved 
                                      ? Colors.green.withOpacity(0.2) 
                                      : (isPending ? Colors.orange.withOpacity(0.2) : Colors.red.withOpacity(0.2)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  book.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isApproved ? Colors.green : (isPending ? Colors.orange : Colors.red),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        // Actions
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminEditBookScreen(book: book),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _deleteBook(context, bookRepo, book),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        
        // Floating Action Button for "Add Book"
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminEditBookScreen(),
                ),
              );
            },
            backgroundColor: const Color(0xFF2196F3),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
