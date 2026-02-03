import 'package:flutter/material.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/components/mithaq_chip.dart';
import '../../../core/ui/components/mithaq_card.dart';
import '../domain/profile.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  RangeValues _ageRange = const RangeValues(20, 40);
  EducationLevel? _selectedEducation;
  final Set<MaritalStatus> _selectedMaritalStatuses = {};
  bool _filterByMyCity = false;
  bool _filterByMyTribe = false;
  String? _selectedCity;
  final TextEditingController _tribeController = TextEditingController();

  // Physical filters
  RangeValues _heightRange = const RangeValues(150, 190);
  SkinColor? _selectedSkinColor;
  final Set<BuildType> _selectedBuildTypes = {};

  final List<String> _cities = [
    'الرياض',
    'جدة',
    'الدمام',
    'مكة',
    'المدينة',
    'الخبر',
  ];

  List<MaritalStatus> get _maritalOptions {
    // Show all marital statuses - gender filtering is automatic
    return [
      MaritalStatus.single,
      MaritalStatus.divorced,
      MaritalStatus.widowed,
      MaritalStatus.married,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'تصفية البحث',
          style: TextStyle(
            color: MithaqColors.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: MithaqColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MithaqSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'العمر',
              style: TextStyle(
                color: MithaqColors.navy,
                fontSize: MithaqTypography.titleSmall,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: MithaqSpacing.m),
            MithaqCard(
              child: Column(
                children: [
                  RangeSlider(
                    values: _ageRange,
                    min: 18,
                    max: 60,
                    divisions: 42,
                    labels: RangeLabels(
                      _ageRange.start.round().toString(),
                      _ageRange.end.round().toString(),
                    ),
                    activeColor: MithaqColors.navy,
                    inactiveColor: MithaqColors.navy.withValues(alpha: 0.1),
                    onChanged: (values) {
                      setState(() {
                        _ageRange = values;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_ageRange.start.round()} سنة'),
                      Text('${_ageRange.end.round()} سنة'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: MithaqSpacing.xl),

            // Gender filter removed - opposite gender filtering is automatic
            const Text(
              'الموقِع والقبيلة',
              style: TextStyle(
                color: MithaqColors.navy,
                fontSize: MithaqTypography.titleSmall,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: MithaqSpacing.m),
            MithaqCard(
              child: Column(
                children: [
                  _FilterCheckTile(
                    label: 'مدينتي فقط',
                    isSelected: _filterByMyCity,
                    onTap: () =>
                        setState(() => _filterByMyCity = !_filterByMyCity),
                  ),
                  const _FilterHint(
                    text: 'أضف مدينتك في الملف الشخصي لتفعيل هذا الفلتر',
                  ),
                  if (!_filterByMyCity) ...[
                    const Divider(),
                    const SizedBox(height: MithaqSpacing.s),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCity,
                      decoration: const InputDecoration(
                        labelText: 'اختيار مدينة أخرى',
                        border: OutlineInputBorder(),
                      ),
                      items: _cities.map((city) {
                        return DropdownMenuItem(value: city, child: Text(city));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCity = val),
                    ),
                  ],
                  const Divider(),
                  _FilterCheckTile(
                    label: 'نفس قبيلتي',
                    isSelected: _filterByMyTribe,
                    onTap: () =>
                        setState(() => _filterByMyTribe = !_filterByMyTribe),
                  ),
                  const _FilterHint(
                    text:
                        'إضافة القبيلة اختيارية، ويمكنك تفعيل هذا الفلتر لاحقاً',
                  ),
                  if (!_filterByMyTribe) ...[
                    const Divider(),
                    const SizedBox(height: MithaqSpacing.s),
                    TextField(
                      controller: _tribeController,
                      decoration: const InputDecoration(
                        labelText: 'البحث عن قبيلة معينة',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: MithaqSpacing.xl),

            const Text(
              'المستوى التعليمي',
              style: TextStyle(
                color: MithaqColors.navy,
                fontSize: MithaqTypography.titleSmall,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: MithaqSpacing.m),
            Wrap(
              spacing: MithaqSpacing.s,
              runSpacing: MithaqSpacing.s,
              children: EducationLevel.values.map((level) {
                return MithaqChip(
                  label: level.label,
                  isSelected: _selectedEducation == level,
                  onTap: () {
                    setState(() {
                      _selectedEducation = level;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: MithaqSpacing.xl),

            const Text(
              'الحالة الاجتماعية',
              style: TextStyle(
                color: MithaqColors.navy,
                fontSize: MithaqTypography.titleSmall,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: MithaqSpacing.m),
            MithaqCard(
              child: Column(
                children: _maritalOptions.map((status) {
                  final isLast = status == _maritalOptions.last;
                  return Column(
                    children: [
                      _FilterCheckTile(
                        label: status.label,
                        isSelected: _selectedMaritalStatuses.contains(status),
                        onTap: () {
                          setState(() {
                            if (_selectedMaritalStatuses.contains(status)) {
                              _selectedMaritalStatuses.remove(status);
                            } else {
                              _selectedMaritalStatuses.add(status);
                            }
                          });
                        },
                      ),
                      if (!isLast) const Divider(),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: MithaqSpacing.xl),

            const Text(
              'المواصفات الشكلية',
              style: TextStyle(
                color: MithaqColors.navy,
                fontSize: MithaqTypography.titleSmall,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: MithaqSpacing.m),

            // Skin Color Filter
            const Text(
              'لون البشرة',
              style: TextStyle(
                color: MithaqColors.navy,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: MithaqSpacing.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: SkinColor.values.map((color) {
                final isSelected = _selectedSkinColor == color;
                Color dotColor;
                switch (color) {
                  case SkinColor.white:
                    dotColor = const Color(0xFFFFE5D0);
                    break;
                  case SkinColor.wheat:
                    dotColor = const Color(0xFFF3C99F);
                    break;
                  case SkinColor.brown:
                    dotColor = const Color(0xFF8D5524);
                    break;
                  case SkinColor.dark:
                    dotColor = const Color(0xFF3C2006);
                    break;
                }
                return GestureDetector(
                  onTap: () => setState(
                    () => _selectedSkinColor = isSelected ? null : color,
                  ),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: MithaqColors.mint, width: 3)
                          : Border.all(color: Colors.grey.shade200),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: MithaqSpacing.l),

            // Height Range Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الطول المطلوب',
                  style: TextStyle(
                    color: MithaqColors.navy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${_heightRange.start.round()} - ${_heightRange.end.round()} سم',
                  style: const TextStyle(
                    color: MithaqColors.mint,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            RangeSlider(
              values: _heightRange,
              min: 140,
              max: 210,
              divisions: 70,
              activeColor: MithaqColors.mint,
              inactiveColor: Colors.grey.shade100,
              onChanged: (val) => setState(() => _heightRange = val),
            ),
            const SizedBox(height: MithaqSpacing.l),

            // Build Filter
            const Text(
              'البنية',
              style: TextStyle(
                color: MithaqColors.navy,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: MithaqSpacing.s),
            Wrap(
              spacing: 8,
              children: BuildType.values.map((type) {
                final isSelected = _selectedBuildTypes.contains(type);
                return MithaqChip(
                  label: type.label,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedBuildTypes.remove(type);
                      } else {
                        _selectedBuildTypes.add(type);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(MithaqSpacing.m),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: MithaqColors.navy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: MithaqSpacing.m),
            shape: RoundedRectangleBorder(borderRadius: MithaqRadius.medium),
          ),
          child: const Text(
            'عرض النتائج',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _FilterCheckTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterCheckTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MithaqSpacing.s),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: MithaqColors.navy,
                fontSize: MithaqTypography.bodyMedium,
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? MithaqColors.mint : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterHint extends StatelessWidget {
  final String text;
  const _FilterHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MithaqSpacing.s),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
      ),
    );
  }
}
