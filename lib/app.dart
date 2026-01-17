import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/link_gate.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData) {
          return const LinkGate();
        }
        
        return const LoginScreen();
      },
    );
  }
}
