import '../../../core/session/app_session.dart';

class DependentSummary {
  final String id;
  final String displayName;
  final String gender;
  final int age;
  final String city;
  final ProfileStatus status;

  const DependentSummary({
    required this.id,
    required this.displayName,
    required this.gender,
    required this.age,
    required this.city,
    required this.status,
  });
}
