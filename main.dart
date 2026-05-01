import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:readify_app/app.dart';
import 'package:readify_app/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize FlutterDownloader
  await FlutterDownloader.initialize(
    debug: true, 
    ignoreSsl: true, 
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Explicitly enable network for Firestore
  try {
    FirebaseFirestore.instance.enableNetwork();
  } catch (e) {
    debugPrint("Error enabling Firestore network: $e");
  }
  
  runApp(const App());
}


