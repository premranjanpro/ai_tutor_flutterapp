import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../authentication/auth_provider.dart';

class FamilyMemberModel {
  final String id;
  final String fullName;
  final String nickname;
  final String relation;
  final String memberType;
  final int age;
  final String preferredLanguage;

  FamilyMemberModel({
    required this.id,
    required this.fullName,
    required this.nickname,
    required this.relation,
    required this.memberType,
    required this.age,
    required this.preferredLanguage,
  });

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    return FamilyMemberModel(
      id: json['id'],
      fullName: json['fullName'],
      nickname: json['nickname'] ?? '',
      relation: json['relation'] ?? '',
      memberType: json['memberType'] ?? '',
      age: json['age'] ?? 0,
      preferredLanguage: json['preferredLanguage'] ?? 'English',
    );
  }
}

class FamilyModel {
  final String id;
  final String familyName;
  final List<FamilyMemberModel> members;

  FamilyModel({
    required this.id,
    required this.familyName,
    required this.members,
  });

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    var list = json['members'] as List? ?? [];
    var membersList = list.map((m) => FamilyMemberModel.fromJson(m)).toList();
    return FamilyModel(
      id: json['id'],
      familyName: json['familyName'] ?? '',
      members: membersList,
    );
  }
}

class FamilyNotifier extends Notifier<AsyncValue<FamilyModel?>> {
  @override
  AsyncValue<FamilyModel?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> fetchFamily() async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.dio.get('/api/family/current');
      if (response.data['success'] == true) {
        state = AsyncValue.data(FamilyModel.fromJson(response.data['data']));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> addMember({
    required String fullName,
    required String nickname,
    required String relation,
    required String memberType,
    required DateTime dateOfBirth,
    required String preferredLanguage,
    required String className,
    required String schoolBoard,
  }) async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.dio.post('/api/family/members', data: {
        'fullName': fullName,
        'nickname': nickname,
        'relation': relation,
        'memberType': memberType,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'preferredLanguage': preferredLanguage,
        'className': className,
        'schoolBoard': schoolBoard,
        'interests': [],
        'learningGoals': []
      });

      if (response.data['success'] == true) {
        await fetchFamily(); // Reload family details
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final familyProvider = NotifierProvider<FamilyNotifier, AsyncValue<FamilyModel?>>(() {
  return FamilyNotifier();
});
