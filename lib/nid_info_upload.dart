import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'auth_service.dart';
import 'map_page.dart';

class NidInfoUploadPage extends StatefulWidget {
  const NidInfoUploadPage({Key? key}) : super(key: key);

  @override
  State<NidInfoUploadPage> createState() => _NidInfoUploadPageState();
}

class _NidInfoUploadPageState extends State<NidInfoUploadPage> {
  final _nidController = TextEditingController();
  File? _faceImage;
  File? _nidFrontImage;
  File? _nidBackImage;

  // To store success status of each upload
  bool _isFaceImageUploaded = false;
  bool _isNidFrontImageUploaded = false;
  bool _isNidBackImageUploaded = false;

  Future<void> _pickImage(ImageSource source, String imageType) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        if (imageType == 'face') {
          _faceImage = File(pickedFile.path);
          _isFaceImageUploaded = true;
        } else if (imageType == 'nidFront') {
          _nidFrontImage = File(pickedFile.path);
          _isNidFrontImageUploaded = true;
        } else if (imageType == 'nidBack') {
          _nidBackImage = File(pickedFile.path);
          _isNidBackImageUploaded = true;
        }
      });
    }
  }

  Future<void> _uploadData() async {
    final nid = _nidController.text.trim();

    if (nid.length != 9 || !RegExp(r'^\d{9}$').hasMatch(nid)) {
      _showSnackBar('NID should be a 9-digit number');
      return;
    }

    if (_faceImage == null || _nidFrontImage == null || _nidBackImage == null) {
      _showSnackBar('Please upload all images');
      return;
    }

    try {
      final authService = AuthService();
      final user = authService.getCurrentUser();

      if (user == null) {
        throw Exception('No user found');
      }

      // Upload images
      final faceUrl = await authService.uploadUserImage(_faceImage!, user.email ?? '', 'face');
      final nidFrontUrl = await authService.uploadUserImage(_nidFrontImage!, user.email ?? '', 'nid_front');
      final nidBackUrl = await authService.uploadUserImage(_nidBackImage!, user.email ?? '', 'nid_back');

      // Update profile data in the database
      final profileData = {
        'email': user.email,
        'user_nid': nid,
        'image_urls': {
          'face': faceUrl,
          'nid_front': nidFrontUrl,
          'nid_back': nidBackUrl,
        },
      };

      await authService.upsertProfileData(profileData);

      // Re-check the profile data
      final updatedProfile = await authService.getProfileData(user.email ?? '');
      if (updatedProfile != null &&
          updatedProfile['user_nid'] != null &&
          updatedProfile['image_urls'] != null) {
        // Navigate to MapPage if the profile is complete
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MapPage()),
        );
      } else {
        // Show error if the profile data is not updated correctly
        _showSnackBar('Profile update failed. Please check your details or log in again.');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload NID and Face Images')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nidController,
              decoration: const InputDecoration(labelText: 'Enter NID (9 digits)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildUploadButton('Face Image', 'face', _faceImage, _isFaceImageUploaded),
            const SizedBox(height: 12),
            _buildUploadButton('NID Front Image', 'nidFront', _nidFrontImage, _isNidFrontImageUploaded),
            const SizedBox(height: 12),
            _buildUploadButton('NID Back Image', 'nidBack', _nidBackImage, _isNidBackImageUploaded),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadData,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(String label, String imageType, File? imageFile, bool isUploaded) {
    return ElevatedButton(
      onPressed: () => _pickImage(ImageSource.gallery, imageType),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(imageFile == null ? 'Upload $label' : '$label Uploaded'),
          if (isUploaded) const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }
}
