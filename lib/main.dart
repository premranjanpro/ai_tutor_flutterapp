import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/authentication/auth_provider.dart';
import 'features/authentication/login_screen.dart';
import 'features/onboarding/family_setup_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    Widget homeScreen;
    if (authState is AuthenticatedState) {
      homeScreen = const FamilySetupScreen();
    } else {
      homeScreen = const LoginScreen();
    }

    return MaterialApp(
      title: 'Mera AI Dost',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        fontFamily: 'Outfit',
      ),
      home: homeScreen,
    );
  }
}
