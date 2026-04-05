import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/gold_card.dart';
import '../providers/admin_provider.dart';

class AdminCategoryManager extends ConsumerWidget {
  const AdminCategoryManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);
    final categories = adminState.categories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Category Management', style: AppTextStyles.h4),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.royalGold),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategorySheet(context, ref),
        backgroundColor: AppColors.royalGold,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Container(
        decoration: BoxDecoration(color: AppColors.background),
        child: categories.isEmpty
            ? _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GoldCard(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.royalGold.withOpacity(0.1),
                          child: Text(
                            cat['name']?[0]?.toUpperCase() ?? '?',
                            style: TextStyle(color: AppColors.royalGold, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(cat['name'] ?? 'Unnamed', style: AppTextStyles.labelLarge),
                        subtitle: Text('/${cat['slug'] ?? ''}', style: AppTextStyles.caption),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () async {
                            final success = await ref.read(adminProvider.notifier).deleteCategory(cat['id']);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Category deleted')),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
                },
              ),
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final slugController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: AppColors.royalGold.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Category', style: AppTextStyles.h4),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              style: AppTextStyles.bodyMedium,
              decoration: _inputDecoration('Category Name (e.g. Rare Coins)'),
              onChanged: (v) => slugController.text = v.toLowerCase().replaceAll(' ', '-'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: slugController,
              style: AppTextStyles.bodyMedium,
              decoration: _inputDecoration('Slug (unique identifier)'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final success = await ref.read(adminProvider.notifier).createCategory({
                    'name': nameController.text.trim(),
                    'slug': slugController.text.trim(),
                  });
                  if (success && context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('CREATE CATEGORY', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.caption.copyWith(color: AppColors.pureWhite.withOpacity(0.3)),
      filled: true,
      fillColor: AppColors.pureWhite.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.royalGold.withOpacity(0.5)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 64, color: AppColors.royalGold.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text('No categories found', style: AppTextStyles.labelLarge.copyWith(color: AppColors.pureWhite.withOpacity(0.3))),
        ],
      ),
    );
  }
}
