import 'package:flutter/material.dart';
import 'family_setup_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _micGranted = false;
  bool _camGranted = false;
  bool _notifGranted = false;
  bool _memoryGranted = false;

  void _continue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const FamilySetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Permissions Setup',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enable features to customize your family AI companion experience.',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionTile(
                      icon: Icons.mic_none_outlined,
                      title: 'Microphone Access',
                      desc: 'Required so the AI companion can hear and respond to your child\'s voice naturally.',
                      value: _micGranted,
                      onChanged: (val) => setState(() => _micGranted = val),
                    ),
                    _buildPermissionTile(
                      icon: Icons.camera_alt_outlined,
                      title: 'Camera Integration',
                      desc: 'Used only during approved homework and visual learning activity sessions.',
                      value: _camGranted,
                      onChanged: (val) => setState(() => _camGranted = val),
                    ),
                    _buildPermissionTile(
                      icon: Icons.notifications_none_outlined,
                      title: 'Daily Reminders',
                      desc: 'Receive alerts when it\'s study time or when the AI has compiled new learning milestones.',
                      value: _notifGranted,
                      onChanged: (val) => setState(() => _notifGranted = val),
                    ),
                    _buildPermissionTile(
                      icon: Icons.psychology_outlined,
                      title: 'Conversation Memory',
                      desc: 'Allows the AI teacher to remember user-specific milestones and interests for future sessions.',
                      value: _memoryGranted,
                      onChanged: (val) => setState(() => _memoryGranted = val),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Accept and Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF0F172A),
            child: Icon(icon, color: const Color(0xFF6366F1)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF6366F1),
            inactiveTrackColor: const Color(0xFF0F172A),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
