import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../authentication/auth_provider.dart';
import '../authentication/login_screen.dart';
import '../onboarding/family_provider.dart';
import '../conversation/chat_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyState = ref.watch(familyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mera AI Dost',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: familyState.when(
        data: (family) {
          if (family == null || family.members.isEmpty) {
            return const Center(
              child: Text(
                'No profiles found. Re-login or recreate family.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final child = family.members.firstWhere(
            (m) => m.memberType == 'Child',
            orElse: () => family.members.first, // Fallback to first member
          );

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Greeting Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Namaste, ${child.nickname}! 👋',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Class: ${child.relation == "Child" ? "Class 2" : "Parent Account"} | Age: ${child.age} years old',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFFE0E7FF),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Yesterday you completed basic count.\nToday let\'s practice some addition together!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFC7D2FE),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Start Talking Button
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(memberId: child.id, nickname: child.nickname),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFF334155), width: 2),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mic_none_outlined,
                          size: 70,
                          color: Color(0xFF06B6D4),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Talk to AI Dost',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start talking and ask questions!',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}
