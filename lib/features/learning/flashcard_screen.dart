import 'package:flutter/material.dart';

class FlashcardItem {
  final String question;
  final String answer;
  final String? imageUrl; // Mock image indicator or emoji
  final List<String> suggestions;

  FlashcardItem({
    required this.question,
    required this.answer,
    this.imageUrl,
    required this.suggestions,
  });
}

class FlashcardScreen extends StatefulWidget {
  final String deckType; // math, english, hindi
  const FlashcardScreen({super.key, required this.deckType});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late final List<FlashcardItem> _cards;
  int _currentIdx = 0;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _cards = _loadDeck(widget.deckType);
  }

  List<FlashcardItem> _loadDeck(String type) {
    if (type == 'math') {
      return [
        FlashcardItem(question: '1 + 2 = ?', answer: '3', suggestions: ['2', '3', '4']),
        FlashcardItem(question: '5 - 3 = ?', answer: '2', suggestions: ['1', '2', '3']),
        FlashcardItem(question: '3 + 4 = ?', answer: '7', suggestions: ['6', '7', '8']),
      ];
    } else if (type == 'english') {
      return [
        FlashcardItem(question: '🍎 What starts with A?', answer: 'Apple', suggestions: ['Banana', 'Apple', 'Orange']),
        FlashcardItem(question: '🐱 What starts with C?', answer: 'Cat', suggestions: ['Dog', 'Cat', 'Bird']),
        FlashcardItem(question: '🐘 What starts with E?', answer: 'Elephant', suggestions: ['Lion', 'Fox', 'Elephant']),
      ];
    } else {
      // Hindi deck
      return [
        FlashcardItem(question: '🍎 सेब (Fruit) - Ye kya hai?', answer: 'सेब (Apple)', suggestions: ['केला', 'सेब', 'आम']),
        FlashcardItem(question: '✏️ कलम (Writing) - Ye kya hai?', answer: 'कलम (Pen)', suggestions: ['कलम', 'किताब', 'कागज']),
        FlashcardItem(question: '🌻 कमल (Flower) - Ye kya hai?', answer: 'कमल (Lotus)', suggestions: ['गुलाब', 'कमल', 'सूरजमुखी']),
      ];
    }
  }

  void _flipCard() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _nextCard() {
    if (_currentIdx < _cards.length - 1) {
      setState(() {
        _currentIdx++;
        _isFlipped = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Deck completed! Awesome job!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCard = _cards[_currentIdx];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${widget.deckType.toUpperCase()} Deck - Ye Kya Hai?', style: const TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Card ${_currentIdx + 1} of ${_cards.length}',
              style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Flipping Flashcard
            GestureDetector(
              onTap: _flipCard,
              child: AspectRatio(
                aspectRatio: 1.3,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isFlipped ? const Color(0xFF06B6D4) : const Color(0xFF334155),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isFlipped ? 'Answer:' : 'Question (Ye Kya Hai?):',
                        style: TextStyle(
                          color: _isFlipped ? const Color(0xFF06B6D4) : const Color(0xFF94A3B8),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isFlipped ? currentCard.answer : currentCard.question,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Outfit',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isFlipped ? 'Tap to view question' : 'Tap to reveal answer',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Quick input suggestion chips
            if (!_isFlipped) ...[
              const Text(
                'QUICK ANSWERS:',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: currentCard.suggestions.map((option) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isFlipped = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFF334155)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(option, style: const TextStyle(color: Color(0xFF818CF8))),
                    ),
                  );
                }).toList(),
              ),
            ],
            const Spacer(),
            if (_isFlipped)
              ElevatedButton(
                onPressed: _nextCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Next Card',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
