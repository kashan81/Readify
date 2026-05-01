import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:readify_app/core/routes.dart';

class AppIntroScreen extends StatefulWidget {
  const AppIntroScreen({super.key});

  @override
  State<AppIntroScreen> createState() => _AppIntroScreenState();
}

class _AppIntroScreenState extends State<AppIntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _introData = [
    {
      "title": "Welcome to Readify",
      "subtitle": "Discover, Read & Enjoy your favorite books anytime",
      "image": "assets/images/intro_1.png",
    },
    {
      "title": "Books just for you",
      "subtitle": "Get personalized book recommendations based on your interests",
      "image": "assets/images/intro_2.png",
    },
    {
      "title": "Listen to books",
      "subtitle": "Convert text into speech and enjoy books anytime",
      "image": "assets/images/intro_3.png",
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache local images
    for (var pageData in _introData) {
      precacheImage(AssetImage(pageData['image']!), context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenAppIntro', true);

    if (mounted) {
      Navigator.pushReplacementNamed(context, Routes.signIn);
    }
  }

  void _onNextPressed() {
    if (_currentPage == _introData.length - 1) {
      _completeIntro();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLastPage = _currentPage == _introData.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background Aesthetic
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF000000),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. Navigation Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _currentPage > 0
                          ? IconButton(
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              },
                              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white54),
                            )
                          : const SizedBox(width: 48),
                      
                      TextButton(
                        onPressed: _completeIntro,
                        child: const Text(
                          "Skip",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Main Content (PageView)
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _introData.length,
                    itemBuilder: (context, index) {
                      return _buildSlide(index, _introData[index]);
                    },
                  ),
                ),

                // 3. Bottom Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _introData.length,
                          (index) => _buildDot(index),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Next / Get Started Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _onNextPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLastPage 
                                ? const Color(0xFF3A86FF) // Bright blue for CPA
                                : const Color(0xFF1E293B), // Dark slate for Next
                            foregroundColor: Colors.white,
                            elevation: isLastPage ? 8 : 4,
                            shadowColor: isLastPage ? const Color(0xFF3A86FF).withOpacity(0.5) : Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            isLastPage ? "Get Started" : "Next",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    bool isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: isActive ? 10 : 8,
      width: isActive ? (isActive ? 24 : 8) : 8, // Pill shape if active
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white24,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildSlide(int pageIndex, Map<String, String> data) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Image Section
        Expanded(
          flex: 6,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.asset(
                    data['image']!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.white10,
                      child: const Icon(Icons.image_not_supported, color: Colors.white24, size: 50),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Text Section
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  data['title']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  data['subtitle']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
