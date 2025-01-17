import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterHomelessPage extends StatefulWidget {
  const RegisterHomelessPage({Key? key}) : super(key: key);

  @override
  State<RegisterHomelessPage> createState() => _RegisterHomelessPageState();
}

class _RegisterHomelessPageState extends State<RegisterHomelessPage> {
  // Form Fields
  final TextEditingController _cardIdController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _subdistrictController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();

  // Dropdowns and Tags
  String? _selectedGender;
  String? _selectedAgeGroup;
  List<String> _selectedTags = [];
  File? _selectedImage;
  Position? _currentPosition;
  String? userNid;
  bool isLoading = true;

  // Options
  final List<String> _ageGroups = ['Child', 'Teenager', 'Adult', 'Middle Aged', 'Elderly'];
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _tags = ['Severely Ill', 'Child', 'Old', 'Drug Addict'];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
    _fetchUserNid(); // Fetch userNid on page load
  }

  Future<void> _fetchUserNid() async {
    try {
      final email = Supabase.instance.client.auth.currentUser?.email;
      if (email == null) {
        throw 'User is not logged in.';
      }

      final response = await Supabase.instance.client
          .from('profiles')
          .select('user_nid')
          .eq('email', email)
          .single();

      setState(() {
        userNid = response['user_nid'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user NID: $e')),
      );
    }
  }

  // Fetch user location
  Future<void> _fetchUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackbar('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackbar('Location permissions are denied.');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() => _currentPosition = position);
    } catch (e) {
      _showSnackbar('Error fetching location: $e');
    }
  }

  // Pick an image
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  // Upload image to Supabase storage
  Future<String?> _uploadImage(String cardId) async {
    if (_selectedImage == null) return null;

    try {
      final fileName = '$cardId.jpg';

      // Upload the image to the 'homeless_faces' bucket
      final response = await Supabase.instance.client.storage
          .from('homeless_faces')
          .upload(fileName, _selectedImage!);

      if (response.isEmpty) {
        throw Exception('Failed to upload image.');
      }

      // Get the public URL of the uploaded image
      final publicUrl = Supabase.instance.client.storage
          .from('homeless_faces')
          .getPublicUrl(fileName);

      return publicUrl; // Return the URL as a string
    } catch (e) {
      _showSnackbar('Error uploading image: $e');
      return null;
    }
  }


  // Submit form
  Future<void> _submitForm() async {
    if (_isSubmitting) return;

    // Validate required fields
    if (_selectedGender == null ||
        _selectedAgeGroup == null ||
        _selectedTags.isEmpty ||
        _currentPosition == null ||
        _districtController.text.isEmpty ||
        _cardIdController.text.isEmpty ||
        _cardIdController.text.length != 9) {
      _showSnackbar('Please fill in all required fields correctly.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload image and get URL
      final imageUrl = await _uploadImage(_cardIdController.text);

      // Prepare data
      final locationData = {
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'house': _houseController.text,
        'street': _streetController.text,
        'subdistrict': _subdistrictController.text,
        'district': _districtController.text,
      };

      final response = await Supabase.instance.client.from('homeless').insert({
        'gender': _selectedGender,
        'age_group': _selectedAgeGroup?.toLowerCase().replaceAll(' ', '_'),
        'tag': _selectedTags,
        'location': locationData,
        'card_id': _cardIdController.text,
        'registered_by': userNid,
        'face': imageUrl,
      });

      if (response.error != null) throw response.error!;

      _showSnackbar('Homeless person registered successfully!');
      Navigator.pop(context);
    } catch (e) {
      _showSnackbar('Error submitting form: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Homeless')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card ID
            const Text('Card ID (9 Digits)'),
            TextField(
              controller: _cardIdController,
              keyboardType: TextInputType.number,
              maxLength: 9,
              decoration: const InputDecoration(hintText: 'Enter Card ID', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            // Gender
            const Text('Gender'),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              items: _genders.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
              onChanged: (value) => setState(() => _selectedGender = value),
              decoration: const InputDecoration(hintText: 'Select Gender'),
            ),
            const SizedBox(height: 16),

            // Age Group
            const Text('Age Group'),
            DropdownButtonFormField<String>(
              value: _selectedAgeGroup,
              items: _ageGroups.map((ageGroup) => DropdownMenuItem(value: ageGroup, child: Text(ageGroup))).toList(),
              onChanged: (value) => setState(() => _selectedAgeGroup = value),
              decoration: const InputDecoration(hintText: 'Select Age Group'),
            ),
            const SizedBox(height: 16),

            // Tags
            const Text('Tags'),
            Wrap(
              spacing: 8.0,
              children: _tags.map((tag) {
                return FilterChip(
                  label: Text(tag),
                  selected: _selectedTags.contains(tag),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Address Fields
            const Text('Address Information'),
            TextField(controller: _houseController, decoration: const InputDecoration(hintText: 'House', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _streetController, decoration: const InputDecoration(hintText: 'Street', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _subdistrictController, decoration: const InputDecoration(hintText: 'Subdistrict', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _districtController, decoration: const InputDecoration(hintText: 'District', border: OutlineInputBorder())),
            const SizedBox(height: 16),

            // Location
            Text(
              _currentPosition != null
                  ? 'Current Location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}'
                  : 'Fetching current location...',
            ),
            const SizedBox(height: 16),

            // Image Picker
            if (_selectedImage != null)
              Image.file(_selectedImage!, height: 200)
            else
              ElevatedButton(onPressed: _pickImage, child: const Text('Upload Image')),

            const SizedBox(height: 16),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
