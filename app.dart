import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readify_app/core/routes.dart';
import 'package:readify_app/data/repositories/auth_repository.dart';
import 'package:readify_app/data/repositories/book_repository.dart';
import 'package:readify_app/data/repositories/category_repository.dart';
import 'package:readify_app/viewmodel/auth_viewmodel.dart';
import 'package:readify_app/viewmodel/home_viewmodel.dart';
import 'package:readify_app/viewmodel/personality_quiz_viewmodel.dart';
import 'package:readify_app/viewmodel/upload_book_viewmodel.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repositories
        Provider<AuthRepository>(
          create: (_) => AuthRepository(),
        ),
        Provider<BookRepository>(
          create: (_) => BookRepository(),
        ),
        Provider<CategoryRepository>(
          create: (_) => CategoryRepository(),
        ),

        // ViewModels
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (context) => HomeViewModel(
            bookRepository: context.read<BookRepository>(),
          ),
        ),
        ChangeNotifierProvider<PersonalityQuizViewModel>(
          create: (_) => PersonalityQuizViewModel(),
        ),
        ChangeNotifierProvider<UploadBookViewModel>(
          create: (context) => UploadBookViewModel(
            bookRepository: context.read<BookRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Readify App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: false,
        ),
        initialRoute: Routes.splash,
        onGenerateRoute: Routes.generateRoute,
      ),
    );
  }
}
