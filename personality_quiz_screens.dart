import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readify_app/viewmodel/personality_quiz_viewmodel.dart';
import 'package:readify_app/services/gemini_service.dart';
import 'package:readify_app/viewmodel/auth_viewmodel.dart';
import 'package:readify_app/core/routes.dart';
import 'package:readify_app/utils/genre_calculator.dart';
import 'dart:math' as math;

class PersonalityQuizScreen extends StatefulWidget {
  const PersonalityQuizScreen({Key? key}) : super(key: key);

  @override
  State<PersonalityQuizScreen> createState() => _PersonalityQuizScreenState();
}

class _PersonalityQuizScreenState extends State<PersonalityQuizScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();

    // ➤ 1. Quiz Restart Behavior
    // Reset the quiz state whenever this screen is initialized.
    // Using addPostFrameCallback to ensure context is available and avoid build-phase errors.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PersonalityQuizViewModel>().resetQuiz();
    });

    // Main Content Animation
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Background Animation
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _nextQuestion(BuildContext context) {
    final viewModel = context.read<PersonalityQuizViewModel>();
    if (!viewModel.isLastQuestion) {
      _controller.reverse().then((_) {
        viewModel.nextQuestion();
        _controller.forward();
      });
    } else {
      _finishQuizAndShowResult(context, viewModel);
    }
  }

  void _finishQuizAndShowResult(BuildContext context, PersonalityQuizViewModel viewModel) async {
    viewModel.finishQuiz();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2196F3)),
      ),
    );

    // PRIMARY: Gemini API
    final geminiService = GeminiService();
    final result = await geminiService.analyzePersonality(viewModel.answers);

    if (context.mounted) {
      Navigator.pop(context); // close loading dialog
    }
    
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
      genres = GenreCalculator.calculateGenres(viewModel.answers, viewModel.questions);
    }

    if (context.mounted) {
       await context.read<AuthViewModel>().updateUserPersonality(personality, genres);
       _showResultDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ➤ 2. Background & Theme
          // Consistent with app theme (Deep Navy) but with vibrant accents
          _buildAnimatedBackground(),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Consumer<PersonalityQuizViewModel>(
                    builder: (context, viewModel, child) {
                      // Handle case where questions might be empty or index out of bounds (safety)
                      if (viewModel.questions.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final question =
                          viewModel.questions[viewModel.currentQuestion];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            // Progress Bar
                            _buildProgressBar(viewModel),
                            const SizedBox(height: 40),

                            // Question Card
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: Text(
                                  question["question"],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),

                            // ➤ 3. Option Labels & Design
                            Expanded(
                              child: ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: question["options"].length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final option = question["options"][index];
                                  final isSelected =
                                      viewModel.selectedOption == option;
                                  final labels = ["A", "B", "C", "D"];

                                  return _buildOptionCard(
                                    label: labels[index],
                                    text: option,
                                    isSelected: isSelected,
                                    onTap: () => viewModel.selectOption(option),
                                    index: index,
                                  );
                                },
                              ),
                            ),

                            // Next Button
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: _buildNextButton(viewModel, context),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0B1622), // App Theme: Very Dark Navy
                Color.lerp(const Color(0xFF1A2980), const Color(0xFF0B1622),
                    _bgController.value)!, // Pulsing Deep Blue
              ],
            ),
          ),
          child: Stack(
            children: [
              // ➤ 4. Animations & Interactivity (Floating Dots/Waves)
              Positioned(
                top: -50 + (_bgController.value * 30),
                right: -50,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blueAccent.withOpacity(0.15),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 100 - (_bgController.value * 50),
                left: -80,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.purpleAccent.withOpacity(0.1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
                SizedBox(width: 6),
                Text(
                  "Personality Quiz",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(PersonalityQuizViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Question ${viewModel.currentQuestion + 1}",
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "${viewModel.currentQuestion + 1}/${viewModel.totalQuestions}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (viewModel.currentQuestion + 1) / viewModel.totalQuestions,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF2196F3)),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String label,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
    required int index,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              // Glassmorphic card style
              color: isSelected
                  ? Colors.white
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // Label Circle (A, B, C, D)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFF0B1622) // Dark text on white
                        : Colors.white.withOpacity(0.1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Option Text
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF0B1622) : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Check Icon
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF0B1622),
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton(PersonalityQuizViewModel viewModel, BuildContext context) {
    final isEnabled = viewModel.selectedOption != null;

    return GestureDetector(
      onTap: isEnabled ? () => _nextQuestion(context) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isEnabled
              ? const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF2196F3)],
                )
              : LinearGradient(
                  colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.1)],
                ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          viewModel.isLastQuestion ? "Finish Quiz" : "Next Question",
          style: TextStyle(
            color: isEnabled ? Colors.white : Colors.white38,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  void _showResultDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Result",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1622), // Match App Theme
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: const Icon(Icons.celebration,
                        size: 50, color: Color(0xFF2196F3)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Quiz Completed!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Your reading personality has been analyzed. Get ready for some amazing book recommendations!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Close dialog and push replacement to recommendation screen
                        Navigator.pop(context); 
                        Navigator.pushReplacementNamed(context, Routes.quizRecommendation);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Continue",
                        style: TextStyle(
                          color: Color(0xFF0B1622),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
          child: child,
        );
      },
    );
  }
}
