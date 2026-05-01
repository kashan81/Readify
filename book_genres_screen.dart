import 'package:flutter/material.dart';
import 'package:readify_app/core/routes.dart';

class BookGenresScreen extends StatelessWidget {
  const BookGenresScreen({Key? key}) : super(key: key);

  // List of genres available to explore
  final List<Map<String, dynamic>> genres = const [
    {'name': 'Mystery', 'icon': Icons.search, 'color': Color(0xFF5E35B1)},
    {'name': 'Romance', 'icon': Icons.favorite, 'color': Color(0xFFD81B60)},
    {'name': 'Motivational and Philosophy', 'icon': Icons.psychology, 'color': Color(0xFFFFB300)},
    {'name': 'Fantasy or Sci-fi', 'icon': Icons.auto_awesome, 'color': Color(0xFF00ACC1)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1B2A), // Dark aesthetic
      appBar: AppBar(
        title: const Text(
          'Explore Genres',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0E1B2A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: genres.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 items in a row
            childAspectRatio: 1.2, // Width to height ratio
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final genre = genres[index];
            return _buildGenreCard(context, genre);
          },
        ),
      ),
    );
  }

  Widget _buildGenreCard(BuildContext context, Map<String, dynamic> genre) {
    return GestureDetector(
      onTap: () {
        // Navigate to the GenreBooksScreen and pass the genre name
        Navigator.pushNamed(
          context,
          Routes.genreBooks,
          arguments: genre['name'],
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: genre['color'].withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: genre['color'].withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: genre['color'].withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              genre['icon'],
              size: 48,
              color: genre['color'],
            ),
            const SizedBox(height: 12),
            Text(
              genre['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
