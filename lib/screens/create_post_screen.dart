import 'package:flutter/material.dart';
import '../data/item_store.dart';
import '../models/item.dart';
import '../services/auth_service.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _imageUrlController = TextEditingController();

  static const _categories = [
    'Books',
    'Electronics',
    'Transport',
    'Dorm',
    'Clothes',
    'Others',
  ];

  static const _conditions = ['Brand New', 'Like New', 'Good', 'Fair'];

  String _selectedCategory = '';
  String _selectedCondition = '';
  bool _isPosting = false;
  bool _posted = false;

  String get _effectiveCategory => _selectedCategory == 'Others'
      ? _customCategoryController.text.trim()
      : _selectedCategory;

  bool get _isValid =>
      _titleController.text.trim().isNotEmpty &&
      _descriptionController.text.trim().isNotEmpty &&
      _priceController.text.trim().isNotEmpty &&
      _selectedCategory.isNotEmpty &&
      (_selectedCategory != 'Others'
          ? true
          : _customCategoryController.text.trim().isNotEmpty) &&
      _selectedCondition.isNotEmpty;

  Map<String, String> get _currentUser {
    final authUser = AuthService.getUser();
    return {
      'id': 'current-user',
      'name': 'Jordan Smith',
      'avatar': 'https://api.dicebear.com/7.x/avataaars/svg?seed=Jordan',
      if (authUser != null)
        ...authUser.map((key, value) => MapEntry(key, value?.toString() ?? '')),
    };
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _customCategoryController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _handlePost() async {
    if (!_isValid || _isPosting) return;

    setState(() {
      _isPosting = true;
    });

    try {
      String imageUrl = _imageUrlController.text.trim().isNotEmpty
          ? _imageUrlController.text.trim()
          : 'https://images.unsplash.com/photo-1579535984712-92fffbbaa266?auto=format&fit=crop&w=1080&q=80';

      final newItem = _buildNewItem(imageUrl);
      await ItemStore.instance.addItem(newItem);

      setState(() {
        _isPosting = false;
        _posted = true;
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing posted successfully!')),
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Go back to previous screen
    } catch (e) {
      setState(() {
        _isPosting = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Item _buildNewItem(String imageUrl) {
    final user = _currentUser;
    final seller = Seller(
      id: user['id'] ?? 'current-user',
      name: user['name'] ?? 'Jordan Smith',
      avatar:
          user['avatar'] ??
          'https://api.dicebear.com/7.x/avataaars/svg?seed=Jordan',
      rating: 5.0,
      isFollowing: false,
      followers: 0,
    );

    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final category = _effectiveCategory;

    return Item(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      price: price,
      image: imageUrl,
      category: category,
      seller: seller,
      condition: _selectedCondition,
      postedAt: 'Just now',
      saved: false,
      comments: const [],
      commentsCount: 0,
      likes: 0,
      likedByMe: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, borderColor),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildImagePreview(theme, borderColor),
                    const SizedBox(height: 16),
                    _buildForm(theme, borderColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color borderColor) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : const Color(0x11000000),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Create Listing',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _isValid ? _handlePost : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              backgroundColor: theme.colorScheme.primary,
              disabledBackgroundColor: theme.disabledColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: _isPosting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Icon(_posted ? Icons.check : Icons.cloud_upload_outlined),
            label: Text(
              _posted ? 'Posted' : 'Post',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(ThemeData theme, Color borderColor) {
    final isDark = theme.brightness == Brightness.dark;
    final imageUrl = _imageUrlController.text.trim().isNotEmpty
        ? _imageUrlController.text.trim()
        : 'https://images.unsplash.com/photo-1579535984712-92fffbbaa266?auto=format&fit=crop&w=1080&q=80';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: theme.cardColor,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0x11000000),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme, Color borderColor) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Title *', theme),
          TextField(
            controller: _titleController,
            decoration: _inputDecoration(
              hint: 'e.g., Engineering Textbooks Bundle',
              theme: theme,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _buildLabel('Description *', theme),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: _inputDecoration(
              hint: 'Describe your item in detail...',
              theme: theme,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _buildLabel('Price *', theme),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(
              hint: '0.00',
              prefix: Text(
                '\$ ',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
              theme: theme,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          _buildLabel('Image URL (optional)', theme),
          TextField(
            controller: _imageUrlController,
            decoration: _inputDecoration(
              hint: 'https://example.com/image.jpg',
              theme: theme,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          _buildLabel('Category *', theme),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (_) => setState(() {
                  _selectedCategory = category;
                }),
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : theme.colorScheme.outline,
                ),
                backgroundColor: isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : const Color(0xFFF1F5F9),
              );
            }).toList(),
          ),
          if (_selectedCategory == 'Others') ...[
            const SizedBox(height: 12),
            _buildLabel('Tell us more', theme),
            TextField(
              controller: _customCategoryController,
              decoration: _inputDecoration(
                hint: 'e.g., Sports gear, Musical instruments, etc.',
                theme: theme,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 24),
          _buildLabel('Condition *', theme),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _conditions.map((condition) {
              final isSelected = _selectedCondition == condition;
              return ChoiceChip(
                label: Text(condition),
                selected: isSelected,
                onSelected: (_) => setState(() {
                  _selectedCondition = condition;
                }),
                selectedColor: theme.colorScheme.secondary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : theme.colorScheme.outline,
                ),
                backgroundColor: isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : const Color(0xFFF1F5F9),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required ThemeData theme,
    Widget? prefix,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return InputDecoration(
      hintText: hint,
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.outline,
      ),
      prefixIcon: prefix != null
          ? Padding(
              padding: const EdgeInsets.only(left: 12, right: 6),
              child: prefix,
            )
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: isDark
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
          : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
