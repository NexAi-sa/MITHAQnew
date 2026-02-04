enum PersonalityHomeType {
  rustic('Traditional_Stability'),
  camping('Freedom_Seeker'),
  castle('Privacy_First'),
  modern('Ambition_Modern');

  final String tag;
  const PersonalityHomeType(this.tag);
}

enum PersonalitySilenceInterpretation {
  understanding('Stable_Emotional'),
  apathy('Need_Affirmation');

  final String tag;
  const PersonalitySilenceInterpretation(this.tag);
}

enum PriorityIcon {
  tree('Growth'),
  house('Family'),
  swing('Children'),
  fence('Security');

  final String tag;
  const PriorityIcon(this.tag);
}

class PersonalityTestResult {
  final PersonalitySilenceInterpretation silence;
  final PersonalityHomeType home;
  final List<PriorityIcon> priorities;
  final String personalityTypeName;
  final String analysis;
  final String matchingAdvice;

  const PersonalityTestResult({
    required this.silence,
    required this.home,
    required this.priorities,
    required this.personalityTypeName,
    required this.analysis,
    required this.matchingAdvice,
  });

  Map<String, dynamic> toJson() => {
    'silence': silence.name,
    'home': home.name,
    'priorities': priorities.map((p) => p.name).toList(),
    'type': personalityTypeName,
  };
}
