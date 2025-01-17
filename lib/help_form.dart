import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HelpFormPage extends StatefulWidget {
  final String cardId;

  const HelpFormPage({Key? key, required this.cardId}) : super(key: key);

  @override
  State<HelpFormPage> createState() => _HelpFormPageState();
}

class _HelpFormPageState extends State<HelpFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = 'Food';
  String _description = '';
  File? _selectedImage;

  Future<void> submitHelpRequest({
    required String cardId,
    required String category,
    String? description,
    File? image,
  }) async {
    final supabase = Supabase.instance.client;

    try {
      // Retrieve the current user
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated.');
      }

      // Insert the new help request and get the inserted ID
      final response = await supabase
          .from('help')
          .insert({
        'card_id': cardId,
        'category': category,
        'description': description,
        'requested_by': user?.email, // Set the user ID here
        'status': 'pending', // Default status
      })
          .select('id')
          .single();

      if (response == null || response.isEmpty) {
        throw Exception('Failed to insert help request.');
      }

      final int helpId = response['id']; // Extract the help ID

      // If an image is selected, upload it to Supabase storage
      if (image != null) {
        final fileName = '$helpId.jpg'; // Use help.id to name the file
        final uploadPath = await supabase.storage
            .from('help_request_images') // Bucket name
            .upload(fileName, image);

        if (uploadPath == null) {
          throw Exception('Failed to upload image.');
        }

        // Get the public URL for the uploaded image
        final imageUrl = supabase.storage
            .from('help_request_images')
            .getPublicUrl(fileName);

        // Update the `help` record with the image URL
        await supabase.from('help').update({'request_pic': imageUrl}).eq('id', helpId);
      }

      print('Help request submitted successfully.');
    } catch (e) {
      print('Error: $e');
      throw Exception('Error submitting help request: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    try {
      await submitHelpRequest(
        cardId: widget.cardId,
        category: _selectedCategory,
        description: _description.isNotEmpty ? _description : null,
        image: _selectedImage,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Help request submitted successfully!')),
      );

      Navigator.pop(context); // Go back to the previous page
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit help request: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Help'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select a category:', style: TextStyle(fontSize: 16)),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: const [
                  DropdownMenuItem(value: 'Food', child: Text('Food')),
                  DropdownMenuItem(value: 'Sleeping Bag', child: Text('Sleeping Bag')),
                  DropdownMenuItem(value: 'Surgery', child: Text('Surgery')),
                  DropdownMenuItem(value: 'Medicines', child: Text('Medicines')),
                  DropdownMenuItem(value: 'Needs to see a doctor', child: Text('Needs to see a doctor')),
                  DropdownMenuItem(value: 'Winter Clothes', child: Text('Winter Clothes')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),
              const SizedBox(height: 16),
              const Text('Description (optional, 40 characters max):', style: TextStyle(fontSize: 16)),
              TextFormField(
                maxLength: 40,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onSaved: (value) => _description = value ?? '',
              ),
              const SizedBox(height: 16),
              const Text('Upload Image (optional):', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              if (_selectedImage != null)
                Image.file(
                  _selectedImage!,
                  height: 100,
                  fit: BoxFit.cover,
                )
              else
                const Text('No image selected.'),
              TextButton(
                onPressed: _pickImage,
                child: const Text('Select Image'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Submit Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
