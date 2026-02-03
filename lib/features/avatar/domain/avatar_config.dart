enum Gender { male, female }

enum FaceShape { oval, round, square }

enum HeadStyle { hijab, shortHair, longHair, bald, beard, none }

enum SkinTone { light, medium, tan, mediumDeep, deep }

class AvatarConfig {
  final Gender gender;
  final SkinTone skinTone;
  final FaceShape faceShape;
  final HeadStyle headStyle;

  const AvatarConfig({
    this.gender = Gender.male,
    this.skinTone = SkinTone.medium,
    this.faceShape = FaceShape.oval,
    this.headStyle = HeadStyle.shortHair,
  });

  AvatarConfig copyWith({
    Gender? gender,
    SkinTone? skinTone,
    FaceShape? faceShape,
    HeadStyle? headStyle,
  }) {
    return AvatarConfig(
      gender: gender ?? this.gender,
      skinTone: skinTone ?? this.skinTone,
      faceShape: faceShape ?? this.faceShape,
      headStyle: headStyle ?? this.headStyle,
    );
  }
}
