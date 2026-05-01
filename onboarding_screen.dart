import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:readify_app/core/routes.dart';
import 'package:readify_app/viewmodel/auth_viewmodel.dart';
import 'package:readify_app/services/gemini_service.dart';
import 'package:readify_app/utils/genre_calculator.dart';

/// Service class for Onboarding persistence logic
class OnboardingService {
  static const String keyCompleted = 'isOnboardingCompleted';
  static const String keyAnswers = 'onboardingAnswers';
  static const String keyLastPage = 'currentOnboardingPage';

  /// Marks onboarding as completed in SharedPreferences.
  Future<void> markOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyCompleted, true);
  }

  /// Checks if onboarding is already completed.
  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyCompleted) ?? false;
  }

  /// Saves the user's answers as a JSON string.
  /// Map keys are page indices (as String), values are the selected option strings.
  Future<void> saveOnboardingAnswers(Map<int, String> answers) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert int keys to String for JSON encoding
    final Map<String, dynamic> jsonMap =
        answers.map((key, value) => MapEntry(key.toString(), value));
    await prefs.setString(keyAnswers, jsonEncode(jsonMap));
  }

  /// Retrieves saved answers from SharedPreferences.
  Future<Map<int, String>> getOnboardingAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(keyAnswers);
    if (jsonString == null) return {};

    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return jsonMap.map((key, value) => MapEntry(int.parse(key), value.toString()));
    } catch (e) {
      return {};
    }
  }

  /// Saves the last visited page index to allow resuming.
  Future<void> setLastOnboardingPage(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyLastPage, index);
  }

  /// Retrieves the last visited page index.
  Future<int> getLastOnboardingPage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyLastPage) ?? 0;
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingService _onboardingService = OnboardingService();

  int _currentPage = 0;
  bool _isLastPage = false;
  bool _isLoading = true;

  // Track selected option INDICES: PageIndex -> OptionIndex
  final Map<int, int> _selectedOptionIndices = {};
  
  // Track actual answer STRINGS: PageIndex -> AnswerString
  final Map<int, String> _answers = {};

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "question": "What is your age group?",
      "image": "https://image.pollinations.ai/prompt/3d%20illustration%20minimal%20people%20group%20soft%20lighting%20clay%20render%20dark%20theme?width=800&height=800&nologo=true",
      "options": ["Below 15", "15–20", "21–30", "Above 30"],
    },
    {
      "question": "What do you enjoy doing in your free time?",
      "image": "https://image.pollinations.ai/prompt/3d%20illustration%20minimal%20hobbies%20books%20music%20headphones%20clay%20style%20dark%20theme?width=800&height=800&nologo=true",
      "options": [
        "Reading or learning something new",
        "Hanging out with friends",
        "Watching music or movies",
        "Doing creative things (art, writing)"
      ]
    },
    {
      "question": "How do you usually make decisions?",
      "image": "https://image.pollinations.ai/prompt/3d%20illustration%20minimal%20pathways%20choices%20arrows%20soft%20colors%20dark%20theme?width=800&height=800&nologo=true",
      "options": [
        "I think carefully before choosing",
        "I follow my heart",
        "I ask others for advice",
        "I go with what seems fun"
      ]
    },
    {
      "question": "What kind of stories do you enjoy most?",
      "image": "https://image.pollinations.ai/prompt/3d%20illustration%20minimal%20open%20book%20floating%20pages%20magic%20clean%20dark%20theme?width=800&height=800&nologo=true",
      "options": [
        "Mystery or suspense",
        "Romantic or emotional",
        "Sci-fi or fantasy",
        "Motivational stories"
      ]
    },
    {
      "question": "How do you handle problems?",
      "image": "https://image.pollinations.ai/prompt/3d%20illustration%20minimal%20puzzle%20pieces%20solving%20calm%20focus%20dark%20theme?width=800&height=800&nologo=true",
      "options": [
        "Analyze calmly",
        "Talk to someone",
        "Stay positive",
        "Ignore & move on"
      ]
    },
    {
      "question": "How do you spend weekends?",
      "image": "https://image.pollinations.ai/prompt/3d%20illustration%20minimal%20coffee%20cup%20sunlight%20lazy%20day%20clay%20dark%20theme?width=800&height=800&nologo=true",
      "options": [
        "Reading or studying",
        "Going out with friends",
        "Watching shows or gaming",
        "Personal projects"
      ]
    },
    {
      "question": "Which word describes you best?",
      "image": "https://image.pollinations.ai/prompt/3d%20illustration%20minimal%20mirror%20reflection%20identity%20clean%20style%20dark%20theme?width=800&height=800&nologo=true",
      "options": ["Calm", "Social", "Creative", "Ambitious"]
    },
    {
      "question": "What kind of ending do you like?",
      "image": "https://image.pollinations.ai/prompt/3d%20illustration%20minimal%20sunset%20horizon%20peaceful%20ending%20clay%20dark%20theme?width=800&height=800&nologo=true",
      "options": [
        "Smart twist",
        "Happy emotional",
        "Motivational",
        "Open and thoughtful"
      ]
    },
    {
      "question": "What inspires you the most?",
      "image": "https://image.pollinations.ai/prompt/3d%20illustration%20minimal%20lightbulb%20idea%20spark%20clean%20background%20dark%20theme?width=800&height=800&nologo=true",
      "options": [
        "Success stories",
        "Love & emotions",
        "Creativity",
        "Mystery & solving"
      ]
    },
    {
      "question": "What would you like to improve?",
      "image": "https://image.pollinations.ai/prompt/3d%20illustration%20minimal%20stairs%20climbing%20growth%20upward%20clay%20dark%20theme?width=800&height=800&nologo=true",
      "options": ["Knowledge", "Confidence", "Creativity", "Focus"]
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache images for better performance
    for (var pageData in _onboardingData) {
      precacheImage(CachedNetworkImageProvider(pageData['image']), context);
    }
  }

  Future<void> _loadSavedState() async {
    // Resume functionality
    final savedPage = await _onboardingService.getLastOnboardingPage();
    final savedAnswers = await _onboardingService.getOnboardingAnswers();

    setState(() {
      _currentPage = savedPage;
      _answers.addAll(savedAnswers);
      
      // Restore selected indices based on saved answer strings
      savedAnswers.forEach((pageIndex, answer) {
        final options = _onboardingData[pageIndex]['options'] as List;
        final index = options.indexOf(answer);
        if (index != -1) {
          _selectedOptionIndices[pageIndex] = index;
        }
      });
      
      _isLastPage = _currentPage == _onboardingData.length - 1;
      _isLoading = false;
    });

    // Jump to the saved page after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentPage);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- Logic Functions ---

  void onOptionSelected(int pageIndex, String option) {
    final options = _onboardingData[pageIndex]['options'] as List;
    final optionIndex = options.indexOf(option);

    setState(() {
      _selectedOptionIndices[pageIndex] = optionIndex;
      _answers[pageIndex] = option;
    });

    // Save progress immediately
    _onboardingService.saveOnboardingAnswers(_answers);
  }

  void onNextPressed() {
    // Validation
    if (!_selectedOptionIndices.containsKey(_currentPage)) {
      _showSelectionError();
      return;
    }

    if (_isLastPage) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  // Also acts as 'markOnboardingCompleted' trigger
  void _completeOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    final List<String> answersList = _answers.values.toList();
    
    // PRIMARY: Gemini API
    final geminiService = GeminiService();
    final result = await geminiService.analyzePersonality(answersList);

    String personality;
    List<String> genres;

    if (result != null && result.containsKey('personality') && result.containsKey('genres')) {
      personality = result['personality'];
      genres = List<String>.from(result['genres']);
    } else {
      // FALLBACK: Local Logic
      final fallbacks = [
        "A curious and diverse reader seeking new adventures.",
        "An imaginative mind exploring uncharted worlds.",
        "A thoughtful reader blending logic with emotion.",
        "An adventurous soul eager for the next chapter.",
        "A quiet observer looking for profound stories."
      ];
      personality = fallbacks[DateTime.now().millisecond % fallbacks.length];
      genres = GenreCalculator.calculateGenres(answersList, _onboardingData);
    }

    if (mounted) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      await authViewModel.completeOnboarding();
      await authViewModel.updateUserPersonality(personality, genres);
      
      setState(() {
        _isLoading = false;
      });
      
      Navigator.pushReplacementNamed(context, Routes.home);
    }
  }

  void _showSelectionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select an option to continue'),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 1),
      ),
    );
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool isOptionSelected = _selectedOptionIndices.containsKey(_currentPage);

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
                    children: [
                      if (_currentPage > 0)
                        IconButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white54),
                        )
                      else
                        const SizedBox(width: 48),

                      const Spacer(),
                    ],
                  ),
                ),

                // 2. Main Content (PageView)
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(), // Disable swipe to enforce validation
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                        _isLastPage = index == _onboardingData.length - 1;
                      });
                      // Save last page index
                      _onboardingService.setLastOnboardingPage(index);
                    },
                    itemCount: _onboardingData.length,
                    itemBuilder: (context, index) {
                      return _buildOnboardingPage(index, _onboardingData[index]);
                    },
                  ),
                ),

                // 3. Bottom Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _onboardingData.length,
                          (index) => _buildDot(index),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Next / Get Started Button
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: isOptionSelected ? 1.0 : 0.5,
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isOptionSelected ? onNextPressed : null,
                            style: ElevatedButton.styleFrom(
                              // Requirement: Darker (Higher Contrast) button
                              backgroundColor: const Color(0xFF1E293B), // Slate 800 (Darker than before)
                              foregroundColor: Colors.white,
                              elevation: isOptionSelected ? 4 : 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isOptionSelected 
                                      ? Colors.white.withOpacity(0.1) 
                                      : Colors.transparent,
                                ),
                              ),
                            ),
                            child: Text(
                              _isLastPage ? "Get Started" : "Next",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
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
      width: isActive ? 10 : 8, // Dots
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white24, // High contrast active dot
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildOnboardingPage(int pageIndex, Map<String, dynamic> data) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Image Section ~40%
        Flexible(
          flex: 4,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: CachedNetworkImage(
                    imageUrl: data['image'],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF334155)),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.white10,
                      child: const Icon(Icons.image_not_supported, color: Colors.white24, size: 50),
                    ),
                    fadeInDuration: const Duration(milliseconds: 500),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Content Section ~60%
        Flexible(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Question
                Text(
                  data['question'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 24),

                // Options
                ...List.generate((data['options'] as List).length, (optionIndex) {
                  final option = data['options'][optionIndex];
                  final isSelected = _selectedOptionIndices[pageIndex] == optionIndex;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => onOptionSelected(pageIndex, option),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          // Requirement: Selected option uses darker fill
                          color: isSelected
                              ? const Color(0xFF1E293B) // Slate 800 (Darker)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected 
                                ? Colors.blueAccent.withOpacity(0.5) 
                                : Colors.transparent,
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : Colors.white70,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: Colors.blueAccent, size: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                
                 // Extra bottom padding to avoid scrolling issues
                 const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
