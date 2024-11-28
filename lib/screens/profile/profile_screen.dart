import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final UserType userType;
  const ProfileScreen({super.key, required this.userType});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _businessHoursController;
  late TextEditingController _addressController;
  String? _imageUrl;
  bool _isLoading = false;
  final _cloudinaryService = CloudinaryService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _businessHoursController = TextEditingController();
    _addressController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (userId != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (mounted && doc.exists) {
        setState(() {
          _nameController.text = doc.data()?['name'] ?? '';
          _emailController.text = doc.data()?['email'] ?? '';
          _phoneController.text = doc.data()?['phone'] ?? '';
          _businessHoursController.text = doc.data()?['businessHours'] ?? '';
          _addressController.text = doc.data()?['address'] ?? '';
          _imageUrl = doc.data()?['imageUrl'];
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _isLoading = true);

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();
      final url = await _cloudinaryService.uploadImage(fileBytes: bytes);

      if (url != null) {
        if (_imageUrl != null) {
          await _cloudinaryService.deleteImage(_imageUrl!);
        }
        setState(() => _imageUrl = url);
        await _updateUserData({'imageUrl': url});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile picture: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserData([Map<String, dynamic>? additionalData]) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;

      Map<String, dynamic> data = {
        'name': _nameController.text,
        'phone': _phoneController.text,
      };

      if (widget.userType == UserType.cafe) {
        data['businessHours'] = _businessHoursController.text;
        data['address'] = _addressController.text;
      }

      if (additionalData != null) {
        data.addAll(additionalData);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false)
                  .signOut(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    image: _imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageUrl == null
                      ? Icon(
                          Icons.camera_alt,
                          size: 40,
                          color: theme.primaryColor,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                enabled: false,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              if (widget.userType == UserType.cafe) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessHoursController,
                  decoration: const InputDecoration(
                    labelText: 'Business Hours',
                    prefixIcon: Icon(Icons.access_time),
                    hintText: 'e.g., Mon-Fri: 9 AM - 5 PM',
                  ),
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter business hours'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on),
                    hintText: 'Enter your business address',
                  ),
                  minLines: 1,
                  maxLines: 2,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter your address'
                      : null,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateUserData,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Update Profile'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Implement password reset
                },
                child: const Text('Change Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _businessHoursController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
