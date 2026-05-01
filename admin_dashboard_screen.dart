import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readify_app/core/routes.dart';
import 'package:readify_app/data/models/book_model.dart';
import 'package:readify_app/data/repositories/book_repository.dart';
import 'package:readify_app/viewmodel/auth_viewmodel.dart';
import 'package:readify_app/view/screens/admin_books_tab.dart';
import 'package:readify_app/view/screens/admin_categories_tab.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E1B2A),
        appBar: AppBar(
          title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: const Color(0xFF0E1B2A),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await Provider.of<AuthViewModel>(context, listen: false).signOut();
                if (context.mounted) {
                   Navigator.pushReplacementNamed(context, Routes.signIn);
                }
              },
            )
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF2196F3),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF2196F3),
            tabs: [
              Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
              Tab(text: 'Books', icon: Icon(Icons.library_books)),
              Tab(text: 'Categories', icon: Icon(Icons.category)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OverviewTab(),
            AdminBooksTab(),
            AdminCategoriesTab(),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final bookRepository = Provider.of<BookRepository>(context, listen: false);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  context, 
                  'All Books', 
                  Icons.library_books, 
                  Colors.blue, 
                  bookRepository.getAllBooksStream()
                ),
                _buildStatCard(
                  context, 
                  'Pending', 
                  Icons.pending_actions, 
                  Colors.orange, 
                  bookRepository.getPendingBooksStream(),
                ),
                _buildStatCard(
                  context, 
                  'Approved', 
                  Icons.check_circle_outline, 
                  Colors.green, 
                  bookRepository.getApprovedBooksStream(),
                ),
                _buildStatCard(
                  context, 
                  'Rejected', 
                  Icons.cancel_outlined, 
                  Colors.red, 
                  bookRepository.getRejectedBooksStream(),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            const Text(
              'Management Flow',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Navigation Tiles
            _buildNavTile(
              context,
              title: 'Review Pending Books',
              subtitle: 'Approve or reject recent upload requests',
              icon: Icons.rate_review,
              color: Colors.orange,
              route: Routes.adminPendingBooks,
            ),
            const SizedBox(height: 12),
            _buildNavTile(
              context,
              title: 'Manage Approved Books',
              subtitle: 'View and edit currently available books',
              icon: Icons.menu_book,
              color: Colors.green,
              route: Routes.adminApprovedBooks,
            ),
            const SizedBox(height: 12),
            _buildNavTile(
              context,
              title: 'View Rejected Books',
              subtitle: 'History of books that were not approved',
              icon: Icons.history,
              color: Colors.red,
              route: Routes.adminRejectedBooks,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, IconData icon, Color color, Stream<List<Book>> stream) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F27),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Book>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                );
              }
              if (snapshot.hasError) {
                return const Text('Err', style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold));
              }
              
              final count = snapshot.data?.length ?? 0;
              return Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required String route}) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F27),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
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
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}
