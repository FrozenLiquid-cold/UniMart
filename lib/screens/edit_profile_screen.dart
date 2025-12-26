import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, String> profileData;

  const EditProfileScreen({super.key, required this.profileData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  late final TextEditingController _avatarController;

  ImageProvider? _avatarImageProvider(String avatar) {
    if (avatar.isEmpty) return null;
    final lower = avatar.toLowerCase();
    if (!avatar.startsWith('http://') && !avatar.startsWith('https://')) {
      return null;
    }
    if (lower.endsWith('.svg') || lower.contains('/svg')) {
      return null;
    }
    return NetworkImage(avatar);
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.profileData['name'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.profileData['email'] ?? '',
    );
    _bioController = TextEditingController(
      text: widget.profileData['bio'] ?? '',
    );
    _avatarController = TextEditingController(
      text: widget.profileData['avatar'] ?? '',
    );
    _avatarController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'bio': _bioController.text.trim(),
      'avatar': _avatarController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Builder(
                builder: (context) {
                  final avatarUrl = _avatarController.text.isNotEmpty
                      ? _avatarController.text
                      : widget.profileData['avatar'] ?? '';
                  final avatarImage = _avatarImageProvider(avatarUrl);
                  return CircleAvatar(
                    radius: 48,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? Icon(
                            Icons.person,
                            size: 40,
                            color: theme.colorScheme.onPrimaryContainer,
                          )
                        : null,
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter your name'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bioController,
                label: 'Bio',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _avatarController,
                label: 'Profile picture URL',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: const Text('Save changes'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
