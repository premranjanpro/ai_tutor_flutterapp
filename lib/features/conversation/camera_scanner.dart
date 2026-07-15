import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/storage/secure_storage.dart';

class CameraScanner extends StatefulWidget {
  final String userName;
  final Function(String) onGreetingTriggered;

  const CameraScanner({
    super.key,
    required this.userName,
    required this.onGreetingTriggered,
  });

  @override
  State<CameraScanner> createState() => _CameraScannerState();
}

class _CameraScannerState extends State<CameraScanner> with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;
  
  bool _isScanning = true;
  String _scanStatus = 'Looking for faces...';
  String _cooldownStatus = '';

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scannerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_scannerController);

    // Start simulation
    _startFaceScanning();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _startFaceScanning() {
    Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;

      setState(() {
        _scanStatus = 'Face Identified: ${widget.userName}';
      });

      // 4-Hour Cooldown greeting check
      final storageKey = 'last_greet_${widget.userName}';
      final lastGreetStr = await SecureStorage.getVal(storageKey);
      
      final now = DateTime.now();
      bool shouldGreet = true;
      Duration? timePassed;

      if (lastGreetStr != null) {
        final lastGreetTime = DateTime.parse(lastGreetStr);
        timePassed = now.difference(lastGreetTime);
        if (timePassed.inHours < 4) {
          shouldGreet = false;
        }
      }

      if (shouldGreet) {
        await SecureStorage.writeVal(storageKey, now.toIso8601String());
        setState(() {
          _isScanning = false;
          _cooldownStatus = '4h Cooldown started now.';
        });
        widget.onGreetingTriggered('Hi ${widget.userName}! Good to see you again!');
      } else {
        final remainingMin = 240 - timePassed!.inMinutes;
        setState(() {
          _isScanning = false;
          _cooldownStatus = 'Greet skipped: Cooldown active (${remainingMin}m remaining)';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📷 Face ID Greeting Scan',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 16),
            // Mock Camera Feed Container
            AspectRatio(
              aspectRatio: 1.2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Mock camera background
                    Container(
                      color: const Color(0xFF1E293B),
                      child: const Center(
                        child: Icon(Icons.person, size: 100, color: Color(0xFF334155)),
                      ),
                    ),
                    // Green tracking boundaries
                    Container(
                      margin: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isScanning ? Colors.greenAccent : Colors.blueAccent,
                          width: 2.0,
                        ),
                      ),
                    ),
                    // Animated scan line
                    if (_isScanning)
                      AnimatedBuilder(
                        animation: _scannerAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: MediaQuery.of(context).size.height * 0.25 * _scannerAnimation.value,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 3,
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.greenAccent,
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _scanStatus,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (_cooldownStatus.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _cooldownStatus,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
