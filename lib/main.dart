import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'pages/authentification_page.dart';
import 'pages/navigation_page.dart';

Future<void> main() async {
  // Nécessaire avant l'initialisation de Firebase.
  WidgetsFlutterBinding.ensureInitialized();

  // Connexion de l'application à Firebase.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const SmartInventoryApp());
}

class SmartInventoryApp extends StatelessWidget {
  const SmartInventoryApp({super.key});

  static const Color couleurPrincipale = Color(0xFF15576B);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartInventory',

      debugShowCheckedModeBanner: false,

      // THÈME GÉNÉRAL DE L'APPLICATION
      theme: ThemeData(
        useMaterial3: true,

        scaffoldBackgroundColor: const Color(0xFFF5F6F8),

        colorScheme: ColorScheme.fromSeed(seedColor: couleurPrincipale),

        appBarTheme: const AppBarTheme(
          backgroundColor: couleurPrincipale,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,

          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: couleurPrincipale, width: 2),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: couleurPrincipale,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: couleurPrincipale,
          foregroundColor: Colors.white,
        ),

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFE0F2EE),

          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: couleurPrincipale,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              );
            }

            return const TextStyle(color: Colors.grey, fontSize: 12);
          }),
        ),
      ),

      home: const AuthGate(),
    );
  }
}

// AuthGate décide automatiquement quelle page afficher.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),

      builder: (context, snapshot) {
        // Firebase vérifie l'état de connexion.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF15576B)),
            ),
          );
        }

        // UTILISATEUR CONNECTÉ

        if (snapshot.hasData && snapshot.data != null) {
          return const NavigationPage();
        }

        // UTILISATEUR NON CONNECTÉ

        return const AuthentificationPage();
      },
    );
  }
}
