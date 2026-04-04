import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/gold_card.dart';
import '../providers/admin_provider.dart';
import 'dart:html' as html;

class AdminProductManager extends ConsumerWidget {
  const AdminProductManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text('Product Catalog', style: AppTextStyles.h4),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.royalGold),
      ),
      extendBody: true,
      floatingActionButton: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.royalGold.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddProductSheet(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.royalGold, Color(0xFFB8860B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(Icons.add, color: Colors.black, size: 32),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.darkGradient),
        child: Column(
          children: [
            /// 🔍 Search & Filter Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: GoldCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  style: AppTextStyles.labelMedium,
                  onChanged: (v) => ref.read(adminProvider.notifier).updateSearchQuery(v),
                  cursorColor: AppColors.royalGold,
                  decoration: InputDecoration(
                    hintText: 'Search products by name...',
                    hintStyle: AppTextStyles.caption.copyWith(color: Colors.white24),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: AppColors.royalGold, size: 22),
                  ),
                ),
              ),
            ),

            /// 🏷️ Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  'all', '0.5', '1', '2', '5', '10'
                ].map((f) {
                  final isSelected = adminState.weightFilter == f;
                  final label = f == 'all' ? 'All' : '${f}g';
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => ref.read(adminProvider.notifier).updateWeightFilter(f),
                      borderRadius: BorderRadius.circular(25),
                      child: _FilterChip(label: label, isSelected: isSelected),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 16),

            /// 📦 Product List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(adminProvider.notifier).loadInitialData(),
                color: AppColors.royalGold,
                backgroundColor: AppColors.deepBlack,
                child: () {
                  final filteredProducts = ref.watch(adminProvider.notifier).filteredProducts;
                  
                  if (filteredProducts.isEmpty && !adminState.isLoading) {
                    return _EmptyState();
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final isLowStock = product.stock < 10;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GoldCard(
                          padding: EdgeInsets.zero,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.royalGold.withOpacity(0.1), width: 0.5),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              leading: Hero(
                                tag: product.id,
                                child: Container(
                                  width: 65,
                                  height: 65,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: _ProductImage(imageUrl: product.image),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(child: Text(product.name, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold))),
                                  if (isLowStock)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('LOW STOCK', style: AppTextStyles.caption.copyWith(color: AppColors.error, fontSize: 8, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '${product.weight}g · ${product.purity} · ${Formatters.currency(product.price)}',
                                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.royalGold),
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined, color: Colors.white38, size: 20),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.1);
                    },
                  );
                }(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddProductForm(),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String imageUrl;
  const _ProductImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
        errorWidget: (context, url, error) => Icon(Icons.image_not_supported, color: AppColors.royalGold),
      );
    } else if (imageUrl.isNotEmpty) {
      return Image.asset(imageUrl, fit: BoxFit.contain);
    }
    return Icon(Icons.image, color: AppColors.royalGold);
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.royalGold.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('No products found', style: AppTextStyles.labelLarge.copyWith(color: Colors.white54)),
          const SizedBox(height: 8),
          Text('Try clicking the + button to add one', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _AddProductForm extends ConsumerStatefulWidget {
  const _AddProductForm();

  @override
  ConsumerState<_AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends ConsumerState<_AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _weightController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _purity = '24K';
  String? _selectedCategoryId;
  bool _isSaving = false;
  
  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final categories = ref.read(adminProvider).categories;
    if (categories.isNotEmpty) {
      _selectedCategoryId = categories.first['id'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files?.isEmpty ?? true) return;

      final reader = html.FileReader();
      final file = files![0];
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((e) {
        setState(() {
          _imageBytes = reader.result as Uint8List;
          _imageFileName = file.name;
        });
      });
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null && _imageUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image or provide a URL')),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      String imageUrl = _imageUrlController.text.trim();

      // 1. Upload image if picked
      if (_imageBytes != null) {
        setState(() => _isUploading = true);
        final response = await ApiService().uploadImage(_imageBytes!, _imageFileName!);
        imageUrl = response.data['data']['url'];
        setState(() => _isUploading = false);
      }

      // 2. Submit product
      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'weight': double.tryParse(_weightController.text) ?? 0.0,
        'purity': _purity,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'imageUrl': imageUrl,
        'categoryId': _selectedCategoryId,
      };

      final success = await ref.read(adminProvider.notifier).addProduct(productData);

      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add product: ${ref.read(adminProvider).error}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.deepBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: AppColors.royalGold.withOpacity(0.2), width: 1.5),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add New Asset', style: AppTextStyles.h4.copyWith(color: AppColors.royalGold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              _LabeledField(
                label: 'Product Name',
                child: TextFormField(
                  controller: _nameController,
                  style: AppTextStyles.bodyMedium,
                  decoration: _inputDecoration('e.g. 1g 24K Gold Coin'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
              
              const SizedBox(height: 16),

              _LabeledField(
                label: 'Category',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategoryId,
                      isExpanded: true,
                      dropdownColor: AppColors.deepBlack,
                      style: AppTextStyles.bodyMedium,
                      items: ref.watch(adminProvider).categories.map((c) => DropdownMenuItem(
                        value: (c['id'] as String),
                        child: Text(c['name'] ?? ''),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              _LabeledField(
                label: 'Description',
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  style: AppTextStyles.bodyMedium,
                  decoration: _inputDecoration('Enter product details...'),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: 'Weight (g)',
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.bodyMedium,
                        decoration: _inputDecoration('1.0'),
                        validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _LabeledField(
                      label: 'Purity',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _purity,
                            dropdownColor: AppColors.deepBlack,
                            style: AppTextStyles.bodyMedium,
                            items: ['24K', '22K', '18K'].map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s),
                            )).toList(),
                            onChanged: (v) => setState(() => _purity = v!),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: 'Stock',
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.bodyMedium,
                        decoration: _inputDecoration('0'),
                        validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid' : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: const SizedBox()),
                ],
              ),

              const SizedBox(height: 16),

              _LabeledField(
                label: 'Product Image',
                child: Column(
                  children: [
                    if (_imageBytes != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_imageBytes!, height: 100, width: 100, fit: BoxFit.cover),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _imageUrlController,
                            style: AppTextStyles.bodyMedium,
                            decoration: _inputDecoration('Or paste URL...'),
                            enabled: _imageBytes == null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: Text(_imageBytes == null ? 'Upload' : 'Change'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.royalGold.withOpacity(0.1),
                            foregroundColor: AppColors.royalGold,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangle_circular(12),
                  ),
                  child: _isSaving 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text(
                        _isUploading ? 'Uploading Image...' : 'Save Product',
                        style: AppTextStyles.labelLarge.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.caption.copyWith(color: Colors.white24),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.royalGold, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

RoundedRectangleBorder RoundedRectangle_circular(double radius) {
  return RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _FilterChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.royalGold : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? AppColors.royalGold : Colors.black.withOpacity(0.1),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSelected ? AppColors.royalGold : Colors.black).withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              )
            ],
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isSelected ? Colors.black : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
