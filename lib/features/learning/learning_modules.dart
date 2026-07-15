import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../authentication/auth_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String memberId;
  const QuizScreen({super.key, required this.memberId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  bool _loading = true;
  String _title = '';
  List<dynamic> _questions = [];
  int _currentIdx = 0;
  int? _selectedAnsIdx;
  bool _showAnswer = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _fetchQuiz();
  }

  Future<void> _fetchQuiz() async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.dio.post('/api/learning/quiz', data: {
        'memberId': widget.memberId,
      });
      if (response.data['success'] == true) {
        setState(() {
          _title = response.data['data']['title'];
          _questions = response.data['data']['questions'];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _answer(int index) {
    if (_showAnswer) return;
    setState(() {
      _selectedAnsIdx = index;
      _showAnswer = true;
      if (index == _questions[_currentIdx]['correctIndex']) {
        _score++;
      }
    });
  }

  void _next() {
    if (_currentIdx < _questions.length - 1) {
      setState(() {
        _currentIdx++;
        _selectedAnsIdx = null;
        _showAnswer = false;
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('🎉 Quiz Completed!', style: TextStyle(color: Colors.white, fontFamily: 'Outfit')),
        content: Text(
          'Great job! You scored $_score out of ${_questions.length}!',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Exit screen
            },
            child: const Text('Close', style: TextStyle(color: Color(0xFF6366F1))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(_title.isNotEmpty ? _title : 'Play Quiz', style: const TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _questions.isEmpty
              ? const Center(child: Text('Failed to load quiz.', style: TextStyle(color: Colors.white)))
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Question ${_currentIdx + 1} of ${_questions.length}',
                        style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _questions[_currentIdx]['text'],
                        style: const TextStyle(fontSize: 20, color: Colors.white, height: 1.4, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      ...List.generate(
                        (_questions[_currentIdx]['options'] as List).length,
                        (index) => _buildOptionCard(index),
                      ),
                      const Spacer(),
                      if (_showAnswer) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedAnsIdx == _questions[_currentIdx]['correctIndex']
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedAnsIdx == _questions[_currentIdx]['correctIndex']
                                    ? '🎉 Correct!'
                                    : '❌ Incorrect!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedAnsIdx == _questions[_currentIdx]['correctIndex']
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _questions[_currentIdx]['explanation'],
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _currentIdx < _questions.length - 1 ? 'Next Question' : 'Finish Quiz',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildOptionCard(int index) {
    final optionText = _questions[_currentIdx]['options'][index];
    final isSelected = _selectedAnsIdx == index;
    final isCorrect = _questions[_currentIdx]['correctIndex'] == index;

    Color cardColor = const Color(0xFF1E293B);
    Color borderColor = const Color(0xFF334155);

    if (_showAnswer) {
      if (isCorrect) {
        cardColor = Colors.green.withValues(alpha: 0.2);
        borderColor = Colors.greenAccent;
      } else if (isSelected) {
        cardColor = Colors.red.withValues(alpha: 0.2);
        borderColor = Colors.redAccent;
      }
    } else if (isSelected) {
      borderColor = const Color(0xFF6366F1);
    }

    return GestureDetector(
      onTap: () => _answer(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Text(
          optionText,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}

class StoryScreen extends ConsumerStatefulWidget {
  final String memberId;
  const StoryScreen({super.key, required this.memberId});

  @override
  ConsumerState<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends ConsumerState<StoryScreen> {
  bool _loading = true;
  String _title = '';
  String _content = '';

  @override
  void initState() {
    super.initState();
    _fetchStory();
  }

  Future<void> _fetchStory() async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.dio.post('/api/learning/story', data: {
        'memberId': widget.memberId,
      });
      if (response.data['success'] == true) {
        setState(() {
          _title = response.data['data']['title'];
          _content = response.data['data']['content'];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(_title.isNotEmpty ? _title : 'Story Time', style: const TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF06B6D4),
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const Divider(color: Color(0xFF334155), height: 32),
                    Text(
                      _content,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.8,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
