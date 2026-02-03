import '../domain/name_visibility.dart';

class PrivacyState {
  final NameVisibility visibility;
  final bool showFullNameToSubscribersOnly;
  final bool isSubscriber;
  final String defaultFirstName;
  final String defaultLastName;
  final String placeholderProfileId;

  const PrivacyState({
    this.visibility = NameVisibility.hidden,
    this.showFullNameToSubscribersOnly = true,
    this.isSubscriber = false,
    this.defaultFirstName = 'سارة',
    this.defaultLastName = 'العتيبي',
    this.placeholderProfileId = 'MTH-0142',
  });

  PrivacyState copyWith({
    NameVisibility? visibility,
    bool? showFullNameToSubscribersOnly,
    bool? isSubscriber,
  }) {
    return PrivacyState(
      visibility: visibility ?? this.visibility,
      showFullNameToSubscribersOnly:
          showFullNameToSubscribersOnly ?? this.showFullNameToSubscribersOnly,
      isSubscriber: isSubscriber ?? this.isSubscriber,
      defaultFirstName: defaultFirstName,
      defaultLastName: defaultLastName,
      placeholderProfileId: placeholderProfileId,
    );
  }

  String get displayName {
    switch (visibility) {
      case NameVisibility.hidden:
        return 'عضو ($placeholderProfileId)';
      case NameVisibility.firstName:
        return defaultFirstName;
      case NameVisibility.fullName:
        if (showFullNameToSubscribersOnly && !isSubscriber) {
          return defaultFirstName; // Fallback to first name for non-subscribers
        }
        return '$defaultFirstName $defaultLastName';
    }
  }
}
