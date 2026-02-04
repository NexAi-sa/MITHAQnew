import 'package:flutter/material.dart';

class FiltersScreen extends StatelessWidget {
  const FiltersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تصفية النتائج')),
      body: const Center(child: Text('صفحة الفلاتر (قريباً)')),
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدعم الفني')),
      body: const Center(child: Text('صفحة الدعم الفني (قريباً)')),
    );
  }
}
