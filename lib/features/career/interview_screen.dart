import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InterviewScreen extends ConsumerStatefulWidget {
  const InterviewScreen({super.key});

  @override
  ConsumerState<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends ConsumerState<InterviewScreen> {
  final _controller = TextEditingController();
  
  final List<String> _questions = [
    'Explain the difference between transient, scoped, and singleton service lifetimes in .NET Core Dependency Injection.',
    'What is the purpose of Riverpod Notifier and how does it compare to StateNotifier?',
    'What are index parameters in PostgreSQL and how do they speed up vector-similarity search using pgvector?'
  ];

  int _currentQuestionIdx = 0;
  bool _evaluating = false;
  String? _feedback;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    final answer = _controller.text.trim();
    if (answer.isEmpty) return;

    setState(() {
      _evaluating = true;
      _feedback = null;
    });

    // Simulate AI grading/evaluation latency
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _evaluating = false;
        // High fidelity grading feedback
        _feedback = '🤖 [AI Evaluator Feedback]:\n\n'
            'Score: 8.5 / 10\n'
            'Key Strengths: You correctly identified the primary lifetimes and how memory reallocation works.\n\n'
            'Suggestions for Improvement: Next time, elaborate on thread safety considerations for Singleton states and how pgvector HNSW indices optimize query benchmarks.';
      });
    }
  }

  void _next() {
    setState(() {
      if (_currentQuestionIdx < _questions.length - 1) {
        _currentQuestionIdx++;
        _controller.clear();
        _feedback = null;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Interview prep session completed!')),
        );
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Adult Interview Workspace', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Mock Interview Practice',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Outfit'),
            ),
            const SizedBox(height: 8),
            Text(
              'Question ${_currentQuestionIdx + 1} of ${_questions.length}',
              style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Text(
                _questions[_currentQuestionIdx],
                style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.5, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              maxLines: 6,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type your comprehensive answer here...',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _evaluating
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : ElevatedButton(
                    onPressed: _submitAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Submit Answer for Grading',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
            if (_feedback != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                ),
                child: Text(
                  _feedback!,
                  style: const TextStyle(color: Colors.white, height: 1.6, fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFF334155)),
                ),
                child: Text(
                  _currentQuestionIdx < _questions.length - 1 ? 'Next Question' : 'Finish Session',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
