import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../seeker/domain/profile.dart';
import '../../avatar/domain/avatar_config.dart';

class WizardProgress {
  final int step;
  final DateTime? dob;
  final String city;
  final MaritalStatus? maritalStatus;
  final String? tribe;
  final String? name;
  final Gender? gender;
  final Relationship? relationship;
  final SkinColor? skinColor;
  final String? job;
  final int? height;
  final BuildType? buildType;
  final SmokingHabit? smokingPreference;
  final HijabPreference? hijabPreference;
  final bool? shufaCardActive;
  final String? shufaCardGuardianName;
  final String? shufaCardGuardianTitle;
  final String? shufaCardGuardianPhone;

  const WizardProgress({
    this.step = 1,
    this.dob,
    this.city = '',
    this.maritalStatus,
    this.tribe,
    this.name,
    this.gender,
    this.relationship,
    this.skinColor,
    this.job,
    this.height,
    this.buildType,
    this.smokingPreference,
    this.hijabPreference,
    this.shufaCardActive,
    this.shufaCardGuardianName,
    this.shufaCardGuardianTitle,
    this.shufaCardGuardianPhone,
  });

  bool get isEmpty =>
      dob == null &&
      city.isEmpty &&
      maritalStatus == null &&
      tribe == null &&
      name == null &&
      gender == null &&
      relationship == null &&
      skinColor == null &&
      job == null &&
      height == null &&
      buildType == null &&
      smokingPreference == null &&
      hijabPreference == null &&
      shufaCardActive == null;
}

class WizardProgressNotifier extends StateNotifier<WizardProgress> {
  WizardProgressNotifier() : super(const WizardProgress());

  void updateStep(int step) => state = WizardProgress(
    step: step,
    dob: state.dob,
    city: state.city,
    maritalStatus: state.maritalStatus,
    tribe: state.tribe,
    name: state.name,
    gender: state.gender,
    relationship: state.relationship,
    skinColor: state.skinColor,
    job: state.job,
    height: state.height,
    buildType: state.buildType,
    smokingPreference: state.smokingPreference,
    hijabPreference: state.hijabPreference,
    shufaCardActive: state.shufaCardActive,
    shufaCardGuardianName: state.shufaCardGuardianName,
    shufaCardGuardianTitle: state.shufaCardGuardianTitle,
    shufaCardGuardianPhone: state.shufaCardGuardianPhone,
  );

  void updateData({
    DateTime? dob,
    String? city,
    MaritalStatus? maritalStatus,
    String? tribe,
    String? name,
    Gender? gender,
    Relationship? relationship,
    SkinColor? skinColor,
    String? job,
    int? height,
    BuildType? buildType,
    SmokingHabit? smokingPreference,
    HijabPreference? hijabPreference,
    bool? shufaCardActive,
    String? shufaCardGuardianName,
    String? shufaCardGuardianTitle,
    String? shufaCardGuardianPhone,
  }) {
    state = WizardProgress(
      step: state.step,
      dob: dob ?? state.dob,
      city: city ?? state.city,
      maritalStatus: maritalStatus ?? state.maritalStatus,
      tribe: tribe ?? state.tribe,
      name: name ?? state.name,
      gender: gender ?? state.gender,
      relationship: relationship ?? state.relationship,
      skinColor: skinColor ?? state.skinColor,
      job: job ?? state.job,
      height: height ?? state.height,
      buildType: buildType ?? state.buildType,
      smokingPreference: smokingPreference ?? state.smokingPreference,
      hijabPreference: hijabPreference ?? state.hijabPreference,
      shufaCardActive: shufaCardActive ?? state.shufaCardActive,
      shufaCardGuardianName:
          shufaCardGuardianName ?? state.shufaCardGuardianName,
      shufaCardGuardianTitle:
          shufaCardGuardianTitle ?? state.shufaCardGuardianTitle,
      shufaCardGuardianPhone:
          shufaCardGuardianPhone ?? state.shufaCardGuardianPhone,
    );
  }

  void clear() => state = const WizardProgress();
}

final wizardProgressProvider =
    StateNotifierProvider<WizardProgressNotifier, WizardProgress>((ref) {
      return WizardProgressNotifier();
    });
