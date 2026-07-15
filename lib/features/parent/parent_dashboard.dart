import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../authentication/auth_provider.dart';

class MemoryItem {
  final String id;
  final String content;
  final String type;
  final double importance;
  final String sensitivity;

  MemoryItem({
    required this.id,
    required this.content,
    required this.type,
    required this.importance,
    required this.sensitivity,
  });

  factory MemoryItem.fromJson(Map<String, dynamic> json) {
    return MemoryItem(
      id: json['id'],
      content: json['content'],
      type: json['memoryType'] ?? 'learning_goal',
      importance: (json['importance'] as num?)?.toDouble() ?? 0.5,
      sensitivity: json['sensitivity'] ?? 'low',
    );
  }
}

class ParentDashboard extends ConsumerStatefulWidget {
  const ParentDashboard({super.key});

  @override
  ConsumerState<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends ConsumerState<ParentDashboard> {
  bool _loading = true;
  List<MemoryItem> _memories = [];

  @override
  void initState() {
    super.initState();
    _fetchMemories();
  }

  Future<void> _fetchMemories() async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.dio.get('/api/memory/pending');
      if (response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        setState(() {
          _memories = list.map((m) => MemoryItem.fromJson(m)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _approve(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.dio.post('/api/memory/$id/approve');
      if (response.data['success'] == true) {
        setState(() {
          _memories.removeWhere((m) => m.id == id);
        });
        messenger.showSnackBar(
          const SnackBar(content: Text('Memory approved and integrated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error approving memory: $e');
    }
  }

  Future<void> _reject(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.dio.post('/api/memory/$id/reject');
      if (response.data['success'] == true) {
        setState(() {
          _memories.removeWhere((m) => m.id == id);
        });
        messenger.showSnackBar(
          const SnackBar(content: Text('Memory rejected.'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      debugPrint('Error rejecting memory: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Parent Console', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Parent Insight Hub',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Outfit'),
            ),
            const SizedBox(height: 16),
            // Learning Progress Cards
            _buildProgressCard('Mathematics Core', 0.82, Colors.blueAccent),
            const SizedBox(height: 12),
            _buildProgressCard('Science & Space Study', 0.65, Colors.cyan),
            const SizedBox(height: 32),
            Row(
              children: [
                const Icon(Icons.psychology, color: Color(0xFF818CF8)),
                const SizedBox(width: 8),
                const Text(
                  'AI Extracted Memories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Outfit'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Approve details discovered during AI lessons to help the companion customize future learning plans.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 16),
            _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : _memories.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'No pending memory requests at this time.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _memories.length,
                        itemBuilder: (context, index) {
                          final item = _memories[index];
                          return _buildMemoryCard(item);
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(String subject, double val, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subject, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('${(val * 100).toInt()}% Done', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: val,
            backgroundColor: const Color(0xFF0F172A),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(MemoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF312E81),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.type.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                'Conf: ${(item.importance * 100).toInt()}%',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.content,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _reject(item.id),
                child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _approve(item.id),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                child: const Text('Approve', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
