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
import 'package:image_picker/image_picker.dart';
import '../../product/data/models/product_model.dart';

class AdminProductManager extends ConsumerWidget {
  const AdminProductManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
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
          onPressed: () => _showProductSheet(context),
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
        decoration: BoxDecoration(color: AppColors.background),
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
                    hintStyle: AppTextStyles.caption.copyWith(color: AppColors.pureWhite.withOpacity(0.3)),
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
                backgroundColor: AppColors.background,
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
                      final isLowStock = product.stock <= adminState.lowStockThreshold;
                      final isCritical = product.stock <= (adminState.lowStockThreshold / 2);
                      
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
                                    color: AppColors.pureWhite.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: _ProductImage(imageUrl: product.image),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(child: Text(product.name, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold))),
                                  if (isLowStock)
                                    _StockBadge(count: product.stock, isCritical: isCritical),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${product.weight}g · ${product.purity} · ${Formatters.currency(product.price)}',
                                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.royalGold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'AVAILABLE STOCK: ${product.stock} UNITS',
                                      style: AppTextStyles.caption.copyWith(
                                        color: isLowStock ? (isCritical ? AppColors.error : AppColors.warning) : AppColors.pureWhite.withOpacity(0.3),
                                        fontSize: 9,
                                        fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: AppColors.royalGold),
                                    onPressed: () => _showProductSheet(context, product: product),
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

  void _showProductSheet(BuildContext context, {ProductModel? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductForm(product: product),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int count;
  final bool isCritical;
  const _StockBadge({required this.count, required this.isCritical});

  @override
  Widget build(BuildContext context) {
    final color = isCritical ? AppColors.error : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isCritical ? Icons.warning_amber_rounded : Icons.inventory_2_outlined, color: color, size: 10),
          const SizedBox(width: 6),
          Text(
            isCritical ? 'CRITICAL: $count' : 'LOW: $count',
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
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

class _ProductForm extends ConsumerStatefulWidget {
  final ProductModel? product;
  const _ProductForm({this.product});

  @override
  ConsumerState<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _weightController;
  late final TextEditingController _makingChargesController;
  late final TextEditingController _fixedPriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _imageUrlController;
  String _purity = '24K';
  String? _selectedCategoryId;
  bool _isSaving = false;
  
  XFile? _pickedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name);
    _descriptionController = TextEditingController(text: widget.product?.description);
    _weightController = TextEditingController(text: widget.product?.weight.toString() ?? '1.0');
    _makingChargesController = TextEditingController(text: widget.product?.makingCharges.toString() ?? '0');
    _fixedPriceController = TextEditingController(text: widget.product?.fixedPrice.toString() ?? '0');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '0');
    _imageUrlController = TextEditingController(text: widget.product?.imageUrl);
    _purity = widget.product?.purity ?? '24K';
    _selectedCategoryId = widget.product?.categoryId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categories = ref.read(adminProvider).categories;
      if (_selectedCategoryId == null && categories.isNotEmpty) {
        setState(() {
          _selectedCategoryId = categories.first['id'];
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _makingChargesController.dispose();
    _fixedPriceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedImage == null && _imageUrlController.text.isEmpty && widget.product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image or provide a URL')),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      String imageUrl = _imageUrlController.text.trim();

      // 1. Upload image if picked
      if (_pickedImage != null) {
        setState(() => _isUploading = true);
        final bytes = await _pickedImage!.readAsBytes();
        final response = await ApiService().uploadImage(bytes, _pickedImage!.name);
        imageUrl = response.data['data']['url'];
        setState(() => _isUploading = false);
      }

      // 2. Prepare product data
      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'weight': double.tryParse(_weightController.text) ?? 1.0,
        'makingCharges': double.tryParse(_makingChargesController.text) ?? 0.0,
        'fixedPrice': double.tryParse(_fixedPriceController.text) ?? 0.0,
        'purity': _purity,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'imageUrl': imageUrl,
        'categoryId': _selectedCategoryId,
      };

      bool success;
      if (widget.product != null) {
        success = await ref.read(adminProvider.notifier).updateProduct(widget.product!.id, productData);
      } else {
        success = await ref.read(adminProvider.notifier).addProduct(productData);
      }

      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.product != null ? 'Product updated!' : 'Product added!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${ref.read(adminProvider).error}')),
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

  Future<void> _delete() async {
    if (widget.product == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.deepBlack,
        title: Text('Delete Product', style: AppTextStyles.labelLarge),
        content: Text('Are you sure you want to delete this product?', style: AppTextStyles.caption),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      final success = await ref.read(adminProvider.notifier).deleteProduct(widget.product!.id);
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    
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
                  Text(isEditing ? 'Edit Asset' : 'Add New Asset', style: AppTextStyles.h4.copyWith(color: AppColors.royalGold)),
                  Row(
                    children: [
                      if (isEditing)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          onPressed: _isSaving ? null : _delete,
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
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
                      label: 'Making Charges (₹)',
                      child: TextFormField(
                        controller: _makingChargesController,
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.bodyMedium,
                        decoration: _inputDecoration('0'),
                        validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _LabeledField(
                      label: 'Fixed Price (₹)',
                      child: TextFormField(
                        controller: _fixedPriceController,
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.bodyMedium,
                        decoration: _inputDecoration('0 (Optional)'),
                        validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
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
                  const Expanded(child: SizedBox()),
                ],
              ),

              const SizedBox(height: 16),

              _LabeledField(
                label: 'Product Image',
                child: Column(
                  children: [
                    if (_pickedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FutureBuilder<Uint8List>(
                            future: _pickedImage!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(snapshot.data!, height: 100, width: 100, fit: BoxFit.cover);
                              }
                              return const SizedBox(height: 100, width: 100, child: Center(child: CircularProgressIndicator()));
                            },
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _imageUrlController,
                            style: AppTextStyles.bodyMedium,
                            decoration: _inputDecoration('Or paste URL...'),
                            enabled: _pickedImage == null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: Text(_pickedImage == null ? 'Upload' : 'Change'),
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
                        _isUploading ? 'Uploading Image...' : (isEditing ? 'Update Product' : 'Save Product'),
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
