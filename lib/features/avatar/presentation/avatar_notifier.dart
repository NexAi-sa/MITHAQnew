import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/avatar_config.dart';

final avatarProvider = StateNotifierProvider<AvatarNotifier, AvatarConfig>((
  ref,
) {
  return AvatarNotifier();
});

class AvatarNotifier extends StateNotifier<AvatarConfig> {
  AvatarNotifier() : super(const AvatarConfig());

  void setGender(Gender gender) {
    state = state.copyWith(
      gender: gender,
      headStyle: gender == Gender.female
          ? HeadStyle.hijab
          : HeadStyle.shortHair,
    );
  }

  void setSkinTone(SkinTone tone) {
    state = state.copyWith(skinTone: tone);
  }

  void setFaceShape(FaceShape shape) {
    state = state.copyWith(faceShape: shape);
  }

  void setHeadStyle(HeadStyle style) {
    state = state.copyWith(headStyle: style);
  }
}
