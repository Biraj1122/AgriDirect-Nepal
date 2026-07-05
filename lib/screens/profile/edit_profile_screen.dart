import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../misc/splash_screen.dart';
import '../auth/login_screen.dart';
import 'package:farmtech_agridirect/services/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentPhone;
  final bool mandatoryPhoto;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentPhone,
    this.mandatoryPhoto = false,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _profileImageUrl;
  File? _imageFile;
  final _picker = ImagePicker();
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _fetchCurrentProfileImage();
    
    if (widget.mandatoryPhoto) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile photo is mandatory for your role. Please upload one to continue."),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      });
    }
  }

  Future<void> _fetchCurrentProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _profileImageUrl = doc.data()?['profileImageUrl'];
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.mandatoryPhoto && _imageFile == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a profile photo to continue.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? imageUrl = _profileImageUrl;
        if (_imageFile != null) {
          final xFile = XFile(_imageFile!.path);
          imageUrl = await _storageService.uploadImage(xFile, 'profile_pics');
          if (imageUrl == null) {
            throw "Failed to upload image. Please check your internet connection or try a different photo.";
          }
        }

        // Update Name in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fullName': _nameController.text.trim(),
          'profileImageUrl': imageUrl,
        });

        // Update Firebase Auth Display Name
        await user.updateDisplayName(_nameController.text.trim());

        // Update Password if provided
        if (_passwordController.text.isNotEmpty) {
          if (!user.emailVerified) {
            throw "Please verify your email address before changing your password.";
          }
          await user.updatePassword(_passwordController.text.trim());
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          if (widget.mandatoryPhoto) {
            // Force a reload of the app or redirect to splash to handle role routing again
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SplashScreen()),
              (route) => false,
            );
          } else {
            Navigator.pop(context, true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        String message = e.toString();
        if (message.contains("requires-recent-login")) {
          message = "This action requires you to login again for security.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.mandatoryPhoto,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.mandatoryPhoto) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Profile photo is mandatory. Please upload and save.")),
           );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF7F8F3),
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          automaticallyImplyLeading: !widget.mandatoryPhoto,
          leading: !widget.mandatoryPhoto ? IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ) : null,
          actions: [
            if (widget.mandatoryPhoto)
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xffE8F5E9),
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(_profileImageUrl!)
                                : null) as ImageProvider?,
                        child: (_imageFile == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty))
                            ? const Icon(Icons.person, size: 60, color: Colors.green)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.mandatoryPhoto) ...[
                  const SizedBox(height: 12),
                  const Text("Upload a profile photo to verify your identity", 
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
                const SizedBox(height: 30),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter your name' : null,
                ),
                if (!widget.mandatoryPhoto) ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'New Password (Optional)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty && value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (_passwordController.text.isNotEmpty && value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
