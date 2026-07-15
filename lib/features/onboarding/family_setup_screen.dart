import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'family_provider.dart';
import '../dashboard/dashboard_screen.dart';

class FamilySetupScreen extends ConsumerStatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  ConsumerState<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends ConsumerState<FamilySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _classController = TextEditingController();
  final _boardController = TextEditingController();
  
  DateTime? _dob;
  String _selectedLanguage = 'Hindi';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(familyProvider.notifier).fetchFamily());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _classController.dispose();
    _boardController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 8)), // Default to 8 years old
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all details and select Date of Birth.')),
      );
      return;
    }

    final success = await ref.read(familyProvider.notifier).addMember(
          fullName: _nameController.text.trim(),
          nickname: _nicknameController.text.trim(),
          relation: 'Child',
          memberType: 'Child',
          dateOfBirth: _dob!,
          preferredLanguage: _selectedLanguage,
          className: _classController.text.trim(),
          schoolBoard: _boardController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add child profile. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: familyState.when(
        data: (family) {
          if (family != null) {
            // Check if there is already a child member registered
            final child = family.members.firstWhere(
              (m) => m.memberType == 'Child',
              orElse: () => FamilyMemberModel(id: '', fullName: '', nickname: '', relation: '', memberType: '', age: 0, preferredLanguage: ''),
            );
            
            if (child.id.isNotEmpty) {
              // Auto navigate to dashboard since child profile already exists
              if (!_initialized) {
                _initialized = true;
                final navigator = Navigator.of(context);
                Future.microtask(() {
                  navigator.pushReplacement(
                    MaterialPageRoute(builder: (context) => const DashboardScreen()),
                  );
                });
              }
              return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
            }
          }

          // Show Onboarding Add Child Screen
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      "Kid's Profile",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Setup your child's profile to begin learning sessions with Mera AI Dost.",
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Child's Full Name",
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nicknameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Nickname (What AI should call them)",
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter nickname' : null,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      tileColor: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Text(
                        _dob == null ? 'Select Date of Birth' : 'DOB: ${DateFormat('yyyy-MM-dd').format(_dob!)}',
                        style: TextStyle(color: _dob == null ? const Color(0xFF94A3B8) : Colors.white),
                      ),
                      trailing: const Icon(Icons.calendar_month, color: Color(0xFF6366F1)),
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _classController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Class / Grade (e.g. Class 3)",
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter class/grade' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _boardController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "School Board (e.g. CBSE, ICSE)",
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter school board' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLanguage,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Preferred Conversation Language',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: ['Hindi', 'English', 'Spanish'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedLanguage = val);
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Create Profile',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
        error: (err, stack) => Center(
          child: Text(
            'Error loading family data: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
