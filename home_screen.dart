import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readify_app/core/routes.dart';
import 'package:readify_app/viewmodel/auth_viewmodel.dart';
import 'package:readify_app/viewmodel/home_viewmodel.dart';
import 'package:readify_app/view/screens/book_detail_screen.dart';
import 'package:readify_app/data/models/book_model.dart';
import 'package:readify_app/data/repositories/book_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<String> _searchHistory = [];

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final userModel = authViewModel.userModel;
    final user = authViewModel.user;
    final String? userPhotoUrl = userModel?.photoURL ?? user?.photoURL;

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF0E1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1B2A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Readify',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3))),
              );
              
              final allBooks = await context.read<BookRepository>().getApprovedBooksStream().first;
              if (!context.mounted) return;
              Navigator.pop(context); // close dialog
              
              final uniqueBooks = {for (var book in allBooks) book.title: book}.values.toList();
              
              showSearch(
                context: context,
                delegate: BookSearchDelegate(
                  books: uniqueBooks,
                  searchHistory: _searchHistory,
                  onSearchAdded: (String searchTerm) {
                    if (searchTerm.trim().isNotEmpty && !_searchHistory.contains(searchTerm.trim())) {
                      setState(() {
                        _searchHistory.insert(0, searchTerm.trim());
                        if (_searchHistory.length > 10) _searchHistory.removeLast();
                      });
                    }
                  },
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, Routes.profile),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF2196F3).withOpacity(0.2),
                backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl) : null,
                child: userPhotoUrl == null ? const Icon(Icons.person, color: Color(0xFF2196F3)) : null,
              ),
            ),
          ),
        ],
      ),

      drawer: _buildDrawer(context),

      // -------------------- HOME SCREEN DESIGN -------------------------

      body: StreamBuilder<List<Book>>(
        stream: context.read<BookRepository>().getApprovedBooksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2196F3),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Error loading books",
                    style: TextStyle(color: Colors.redAccent, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          final allBooks = snapshot.data ?? [];
          if (allBooks.isEmpty) {
            return const Center(
              child: Text(
                "No books available",
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            );
          }

          final authViewModel = context.watch<AuthViewModel>();
          final preferredGenres = authViewModel.userModel?.preferredGenres ?? [];

          List<Book> personalizedBooks = [];
          if (preferredGenres.isNotEmpty) {
            personalizedBooks = allBooks.where((b) => preferredGenres.contains(b.category)).toList();
          }
          if (personalizedBooks.isEmpty) {
            personalizedBooks = allBooks.take(5).toList();
          }

          // Generate other lists without the ones we just picked
          final remainingBooks1 = allBooks.where((b) => !personalizedBooks.contains(b)).toList();
          final featuredBooks = remainingBooks1.take(5).toList();
          
          final remainingBooks2 = remainingBooks1.skip(5).toList();
          final trendingBooks = remainingBooks2.take(10).toList();

          return RefreshIndicator(
            onRefresh: () async { setState(() {}); },
            color: const Color(0xFF2196F3),
            backgroundColor: const Color(0xFF1A1F27),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Featured Releases
                  _sectionTitle("Recommended for You"),
                  const SizedBox(height: 16),

                  if (personalizedBooks.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: PageView.builder(
                        controller: PageController(viewportFraction: 0.9),
                        itemCount: personalizedBooks.length,
                        itemBuilder: (context, index) {
                          final book = personalizedBooks[index];
                          return _featuredCard(
                            image: book.coverUrl != null && book.coverUrl!.isNotEmpty ? book.coverUrl! : book.imageUrl,
                            title: book.title,
                            subtitle: book.author,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookDetailScreen(book: book),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 32),

                  _sectionTitle("Featured Books"),
                  const SizedBox(height: 16),
                  if (featuredBooks.isNotEmpty)
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: featuredBooks.length,
                        itemBuilder: (context, index) {
                          final book = featuredBooks[index];
                          return _bookCard(
                            book.coverUrl != null && book.coverUrl!.isNotEmpty ? book.coverUrl! : book.imageUrl, 
                            book.title, 
                            book.author,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookDetailScreen(book: book),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 32),

                  _sectionTitle("Trending Books"),
                  const SizedBox(height: 16),
                  if (trendingBooks.isNotEmpty)
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: trendingBooks.length,
                        itemBuilder: (context, index) {
                          final book = trendingBooks[index];
                          return _bookCard(
                            book.coverUrl != null && book.coverUrl!.isNotEmpty ? book.coverUrl! : book.imageUrl, 
                            book.title, 
                            book.author,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookDetailScreen(book: book),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),

      // ------------------ BOTTOM NAVIGATION BAR -----------------------
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF0E1B2A),
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF2196F3),
          unselectedItemColor: Colors.grey[500],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          onTap: (index) {
            if (index == 1) {
              Navigator.pushNamed(context, Routes.bookGenres);
              return;
            }
            if (index == 2) {
              Navigator.pushNamed(context, Routes.uploadBook);
              return;
            }
            if (index == 3) {
              Navigator.pushNamed(context, Routes.personalityQuiz);
              return;
            }
            
            if (index == 4) {
              Navigator.pushNamed(context, Routes.profile);
              return;
            }

            setState(() {
              _selectedIndex = index;
            });
          },
          items: [
            const BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.home_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.home_rounded)),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.menu_book_rounded)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.menu_book_rounded)),
              label: 'Books',
            ),
            const BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.upload_file_rounded)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.upload_file_rounded)),
              label: 'Upload B...',
            ),
            const BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.quiz_outlined)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.quiz_rounded)),
              label: 'Quiz',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4, top: 4),
                child: userPhotoUrl != null 
                  ? CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(userPhotoUrl),
                    )
                  : const Icon(Icons.person_outline_rounded),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(bottom: 4, top: 4),
                child: userPhotoUrl != null 
                  ? CircleAvatar(
                      radius: 13,
                      backgroundColor: const Color(0xFF2196F3),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(userPhotoUrl),
                      ),
                    )
                  : const Icon(Icons.person_rounded),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final userModel = context.watch<AuthViewModel>().userModel;
    final user = context.watch<AuthViewModel>().user;
    
    return Drawer(
      backgroundColor: const Color(0xFF1A1F27),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF0E1B2A), // Matches the dark Scaffold body
            ),
            accountName: Text(
              userModel?.displayName ?? user?.displayName ?? 'User',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(userModel?.email ?? user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: userModel?.photoURL != null 
                  ? NetworkImage(userModel!.photoURL!) 
                  : (user?.photoURL != null ? NetworkImage(user!.photoURL!) : null),
              child: (userModel?.photoURL == null && user?.photoURL == null)
                  ? const Icon(Icons.person, size: 40, color: Color(0xFF2196F3))
                  : null,
            ),
          ),

          // Drawer items
          _drawerItem(
            icon: Icons.home_rounded,
            label: "Home",
            selected: _selectedIndex == 0,
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 0);
            },
          ),
          _drawerItem(
            icon: Icons.menu_book_rounded,
            label: "Books",
            selected: _selectedIndex == 1,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, Routes.bookGenres);
            },
          ),
          _drawerItem(
            icon: Icons.add_circle_outline_rounded,
            label: "Upload Books",
            selected: _selectedIndex == 2,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, Routes.uploadBook);
            },
          ),
          _drawerItem(
            icon: Icons.auto_awesome_rounded,
            label: "Personality Quiz",
            selected: _selectedIndex == 3,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, Routes.personalityQuiz);
            },
          ),
          _drawerItem(
            icon: Icons.person_outline_rounded,
            label: "Profile",
            selected: _selectedIndex == 4,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, Routes.profile);
            },
          ),

          const Divider(height: 32, color: Colors.grey),

          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () async {
              await context.read<AuthViewModel>().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, Routes.signIn);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _featuredCard({
    required String image,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
        image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.9), Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _bookCard(String url, String title, String author, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                url, 
                fit: BoxFit.cover, 
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.white54, size: 40),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? const Color(0xFF2196F3) : Colors.grey[400],
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFF2196F3) : Colors.white,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      tileColor: selected ? const Color(0xFF2196F3).withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      onTap: onTap,
    );
  }
}

class BookSearchDelegate extends SearchDelegate<Book?> {
  final List<Book> books;
  final List<String> searchHistory;
  final Function(String) onSearchAdded;

  BookSearchDelegate({
    required this.books,
    required this.searchHistory,
    required this.onSearchAdded,
  });

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0E1B2A),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
      scaffoldBackgroundColor: const Color(0xFF0E1B2A),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFF2196F3),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isNotEmpty) {
      onSearchAdded(query.trim());
    }
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      if (searchHistory.isEmpty) {
        return const Center(
          child: Text(
            "No previous searches",
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        );
      }
      return ListView.builder(
        itemCount: searchHistory.length,
        itemBuilder: (context, index) {
          final historyItem = searchHistory[index];
          return ListTile(
            leading: const Icon(Icons.history, color: Colors.white54),
            title: Text(historyItem, style: const TextStyle(color: Colors.white)),
            onTap: () {
              query = historyItem;
              showResults(context);
            },
          );
        },
      );
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final results = books.where((book) {
      final titleLower = book.title.toLowerCase();
      final authorLower = book.author.toLowerCase();
      final searchLower = query.toLowerCase();
      return titleLower.contains(searchLower) || authorLower.contains(searchLower);
    }).toList();

    if (results.isEmpty) {
      return const Center(
        child: Text(
          "No books found",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.55,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final book = results[index];
        return GestureDetector(
          onTap: () {
            onSearchAdded(book.title);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailScreen(book: book),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      book.coverUrl != null && book.coverUrl!.isNotEmpty
                          ? book.coverUrl!
                          : book.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.white54, size: 40),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

