import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/shared/widgets/app_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/local_storage_service.dart';

class _AppLanguage {
  final String code;
  final String label;
  final String native;
  const _AppLanguage(this.code, this.label, this.native);
}

const _languages = [
  _AppLanguage('en', 'English', 'English'),
  _AppLanguage('ur', 'Urdu', 'اردو'),
  _AppLanguage('ur-roman', 'Roman Urdu', 'Roman Urdu'),
];

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selected = 'en';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text('Choose your language',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('You can change this later in Settings',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              ..._languages.map((lang) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LanguageTile(
                      language: lang,
                      selected: _selected == lang.code,
                      onTap: () => setState(() => _selected = lang.code),
                    ),
                  )),
              const Spacer(),
              AppButton(
                label: 'Continue',
                onPressed: () async {
                  final box = LocalStorageService.box(HiveBoxes.settings);
                  await box.put('language', _selected);
                  if (context.mounted) context.go(AppRoutes.login);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final _AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({required this.language, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(language.native,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(language.label,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
