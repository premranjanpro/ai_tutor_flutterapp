import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../authentication/auth_provider.dart';
import '../authentication/login_screen.dart';
import '../onboarding/family_provider.dart';
import '../conversation/chat_screen.dart';
import '../learning/learning_modules.dart';
import '../learning/flashcard_screen.dart';
import '../career/interview_screen.dart';
import '../parent/parent_dashboard.dart';

enum DashboardMode { kids, parent, adult }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DashboardMode _currentMode = DashboardMode.kids;

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _currentMode == DashboardMode.kids
              ? '🤖 Mera AI Dost'
              : _currentMode == DashboardMode.parent
                  ? '👨‍👩‍👧‍👦 Parent Insights'
                  : '💼 Adult Prep Workspace',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        actions: [
          PopupMenuButton<DashboardMode>(
            icon: const Icon(Icons.swap_horiz, color: Color(0xFF6366F1)),
            onSelected: (mode) {
              setState(() => _currentMode = mode);
            },
            color: const Color(0xFF1E293B),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: DashboardMode.kids,
                child: Text('👦 Kids Mode', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: DashboardMode.parent,
                child: Text('👨‍👩‍👧‍👦 Parent Hub', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: DashboardMode.adult,
                child: Text('💼 Adult Mode', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
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
            orElse: () => family.members.first,
          );

          if (_currentMode == DashboardMode.parent) {
            return const ParentDashboard();
          }

          if (_currentMode == DashboardMode.adult) {
            return _buildAdultView();
          }

          return _buildKidsView(child);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
    );
  }

  Widget _buildKidsView(FamilyMemberModel child) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  'Class: ${child.memberType == "Child" ? "Class 2" : "Parent Account"} | Age: ${child.age} years old',
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
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildKidsActivityCard(
                  icon: Icons.menu_book,
                  title: 'Story Time',
                  color: Colors.cyan,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => StoryScreen(memberId: child.id)),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKidsActivityCard(
                  icon: Icons.mode_edit,
                  title: 'Play Quiz',
                  color: Colors.amber,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => QuizScreen(memberId: child.id)),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Interactive Study Cards ("Ye Kya Hai?"):',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildKidsActivityCard(
                  icon: Icons.abc,
                  title: 'English',
                  color: Colors.greenAccent,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const FlashcardScreen(deckType: 'english')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKidsActivityCard(
                  icon: Icons.calculate,
                  title: 'Math (1+2)',
                  color: Colors.purpleAccent,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const FlashcardScreen(deckType: 'math')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKidsActivityCard(
                  icon: Icons.translate,
                  title: 'Hindi',
                  color: Colors.pinkAccent,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const FlashcardScreen(deckType: 'hindi')),
                    );
                  },
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChatScreen(memberId: child.id, nickname: child.nickname),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 36),
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
  }

  Widget _buildKidsActivityCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdultView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome to Career Space',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Practice mock interviews and enhance your communication skills with the adult tutor persona.',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const InterviewScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFF312E81),
                    child: Icon(Icons.work_outline, color: Color(0xFF818CF8)),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Practice Mock Interview',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Answer structured questions on .NET Core, Flutter, and DB indexing.',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Color(0xFF64748B), size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
