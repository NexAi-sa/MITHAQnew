import '../../avatar/domain/avatar_config.dart';

enum SmokingHabit { yes, no, sometimes }

extension SmokingHabitExtension on SmokingHabit {
  String get label {
    switch (this) {
      case SmokingHabit.yes:
        return 'مدخن';
      case SmokingHabit.no:
        return 'غير مدخن';
      case SmokingHabit.sometimes:
        return 'لا يهم';
    }
  }
}

enum HijabPreference { niqab, hijab, flexible }

extension HijabPreferenceExtension on HijabPreference {
  String get label {
    switch (this) {
      case HijabPreference.niqab:
        return 'نقاب';
      case HijabPreference.hijab:
        return 'حجاب';
      case HijabPreference.flexible:
        return 'مرنة';
    }
  }
}

enum SkinColor { white, wheat, brown, dark }

extension SkinColorExtension on SkinColor {
  String get label {
    switch (this) {
      case SkinColor.white:
        return 'أبيض';
      case SkinColor.wheat:
        return 'حنطي';
      case SkinColor.brown:
        return 'أسمر';
      case SkinColor.dark:
        return 'أسمر داكن';
    }
  }
}

enum Relationship { son, daughter, brother, sister, relative }

extension RelationshipExtension on Relationship {
  String get label {
    switch (this) {
      case Relationship.son:
        return 'ابن';
      case Relationship.daughter:
        return 'ابنة';
      case Relationship.brother:
        return 'أخ';
      case Relationship.sister:
        return 'أخت';
      case Relationship.relative:
        return 'قريب';
    }
  }
}

enum BuildType {
  thin('نحيف'),
  athletic('رياضي'),
  average('متوسط'),
  full('ممتلئ');

  final String label;
  const BuildType(this.label);
}

class SuitorPreferences {
  final SmokingHabit? smoking;
  final HijabPreference? hijab;

  const SuitorPreferences({this.smoking, this.hijab});

  SuitorPreferences copyWith({SmokingHabit? smoking, HijabPreference? hijab}) {
    return SuitorPreferences(
      smoking: smoking ?? this.smoking,
      hijab: hijab ?? this.hijab,
    );
  }
}

/// Partner preferences - what the user is looking for in a spouse
class PartnerPreferences {
  final int? minAge;
  final int? maxAge;
  final Set<MaritalStatus>? acceptedMaritalStatus;
  final Set<EducationLevel>? preferredEducation;
  final List<String>? preferredCities;
  final String? notes;

  const PartnerPreferences({
    this.minAge,
    this.maxAge,
    this.acceptedMaritalStatus,
    this.preferredEducation,
    this.preferredCities,
    this.notes,
  });

  PartnerPreferences copyWith({
    int? minAge,
    int? maxAge,
    Set<MaritalStatus>? acceptedMaritalStatus,
    Set<EducationLevel>? preferredEducation,
    List<String>? preferredCities,
    String? notes,
  }) {
    return PartnerPreferences(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      acceptedMaritalStatus:
          acceptedMaritalStatus ?? this.acceptedMaritalStatus,
      preferredEducation: preferredEducation ?? this.preferredEducation,
      preferredCities: preferredCities ?? this.preferredCities,
      notes: notes ?? this.notes,
    );
  }
}

enum EducationLevel {
  highSchool,
  diploma,
  bachelor,
  master,
  phd,
  other;

  String get label {
    switch (this) {
      case EducationLevel.highSchool:
        return 'ثانوي';
      case EducationLevel.diploma:
        return 'دبلوم';
      case EducationLevel.bachelor:
        return 'بكالوريوس';
      case EducationLevel.master:
        return 'ماجستير';
      case EducationLevel.phd:
        return 'دكتوراه';
      case EducationLevel.other:
        return 'أخرى';
    }
  }
}

enum MaritalStatus {
  single,
  divorced,
  widowed,
  married,
  polygamySeekingSecond;

  String get label {
    switch (this) {
      case MaritalStatus.single:
        return 'أعزب/عزباء';
      case MaritalStatus.divorced:
        return 'مطلق/مطلقة';
      case MaritalStatus.widowed:
        return 'أرمل/أرملة';
      case MaritalStatus.married:
        return 'متزوج/متزوجة';
      case MaritalStatus.polygamySeekingSecond:
        return 'معدد (متزوج ويرغب بالثانية)';
    }
  }
}

enum ProfileOwnerRole { seekerSelf, seekerDependent }

class SeekerProfile {
  static int calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  final String profileId;
  final String userId;
  final String name;
  final String city;
  final String? tribe;
  final EducationLevel? educationLevel;
  final MaritalStatus maritalStatus;
  final Gender gender;
  final String job;
  final bool isManagedByGuardian;
  final bool guardianContactAvailable;
  final ProfileOwnerRole profileOwnerRole;
  final DateTime? dob;
  final String? skinColor;
  final String? relationship;
  final int? height;
  final String? build;
  final SuitorPreferences? suitorPreferences;
  final PartnerPreferences? partnerPreferences;
  final String? bio; // النبذة التعريفية / About Me
  final bool isPaused;
  final bool shufaCardActive;
  // Private fields: These are excluded from general fetch responses for privacy.
  // Access them via ProfileRepository.fetchGuardianContactInfo after verification.
  final String? shufaCardGuardianName;
  final String? shufaCardGuardianTitle;
  final String? shufaCardGuardianPhone;
  final bool shufaCardIsVerified;
  final String? guardianUserId;

  final String profilePublicId;
  final String nameVisibility; // 'hidden' | 'first' | 'full_subscribers_only'

  int? get age => dob != null ? calculateAge(dob!) : null;

  const SeekerProfile({
    required this.profileId,
    required this.userId,
    required this.name,
    required this.city,
    this.tribe,
    this.educationLevel,
    required this.maritalStatus,
    required this.gender,
    required this.job,
    required this.isManagedByGuardian,
    this.guardianContactAvailable = false,
    this.profileOwnerRole = ProfileOwnerRole.seekerSelf,
    this.dob,
    this.skinColor,
    this.relationship,
    this.height,
    this.build,
    this.suitorPreferences,
    this.partnerPreferences,
    this.bio,
    this.isPaused = false,
    this.shufaCardActive = false,
    this.shufaCardGuardianName,
    this.shufaCardGuardianTitle,
    this.shufaCardGuardianPhone,
    this.shufaCardIsVerified = false,
    this.guardianUserId,
    this.profilePublicId = '',
    this.nameVisibility = 'hidden',
  });

  SeekerProfile copyWith({
    String? profileId,
    String? userId,
    String? name,
    String? city,
    String? tribe,
    EducationLevel? educationLevel,
    MaritalStatus? maritalStatus,
    Gender? gender,
    String? job,
    bool? isManagedByGuardian,
    bool? guardianContactAvailable,
    ProfileOwnerRole? profileOwnerRole,
    DateTime? dob,
    String? skinColor,
    String? relationship,
    int? height,
    String? build,
    SuitorPreferences? suitorPreferences,
    PartnerPreferences? partnerPreferences,
    String? bio,
    bool? isPaused,
    bool? shufaCardActive,
    String? shufaCardGuardianName,
    String? shufaCardGuardianTitle,
    String? shufaCardGuardianPhone,
    bool? shufaCardIsVerified,
    String? guardianUserId,
    String? profilePublicId,
    String? nameVisibility,
  }) {
    return SeekerProfile(
      profileId: profileId ?? this.profileId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      city: city ?? this.city,
      tribe: tribe ?? this.tribe,
      educationLevel: educationLevel ?? this.educationLevel,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      gender: gender ?? this.gender,
      job: job ?? this.job,
      isManagedByGuardian: isManagedByGuardian ?? this.isManagedByGuardian,
      guardianContactAvailable:
          guardianContactAvailable ?? this.guardianContactAvailable,
      profileOwnerRole: profileOwnerRole ?? this.profileOwnerRole,
      dob: dob ?? this.dob,
      skinColor: skinColor ?? this.skinColor,
      relationship: relationship ?? this.relationship,
      height: height ?? this.height,
      build: build ?? this.build,
      suitorPreferences: suitorPreferences ?? this.suitorPreferences,
      partnerPreferences: partnerPreferences ?? this.partnerPreferences,
      bio: bio ?? this.bio,
      isPaused: isPaused ?? this.isPaused,
      shufaCardActive: shufaCardActive ?? this.shufaCardActive,
      shufaCardGuardianName:
          shufaCardGuardianName ?? this.shufaCardGuardianName,
      shufaCardGuardianTitle:
          shufaCardGuardianTitle ?? this.shufaCardGuardianTitle,
      shufaCardGuardianPhone:
          shufaCardGuardianPhone ?? this.shufaCardGuardianPhone,
      shufaCardIsVerified: shufaCardIsVerified ?? this.shufaCardIsVerified,
      guardianUserId: guardianUserId ?? this.guardianUserId,
      profilePublicId: profilePublicId ?? this.profilePublicId,
      nameVisibility: nameVisibility ?? this.nameVisibility,
    );
  }
}
