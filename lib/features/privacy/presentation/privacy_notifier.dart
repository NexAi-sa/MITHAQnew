import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/name_visibility.dart';
import 'privacy_state.dart';

final privacyProvider = StateNotifierProvider<PrivacyNotifier, PrivacyState>((
  ref,
) {
  return PrivacyNotifier();
});

class PrivacyNotifier extends StateNotifier<PrivacyState> {
  PrivacyNotifier() : super(const PrivacyState());

  void setVisibility(NameVisibility visibility) {
    state = state.copyWith(visibility: visibility);
  }

  void toggleFullNameToSubscribers(bool value) {
    state = state.copyWith(showFullNameToSubscribersOnly: value);
  }

  void setSubscriber(bool value) {
    state = state.copyWith(isSubscriber: value);
  }
}
