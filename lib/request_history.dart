import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class RequestHistoryPage extends StatefulWidget {
  final String cardId;

  const RequestHistoryPage({Key? key, required this.cardId}) : super(key: key);

  @override
  _RequestHistoryPageState createState() => _RequestHistoryPageState();
}

class _RequestHistoryPageState extends State<RequestHistoryPage> {
  late Future<List<Map<String, dynamic>>> _helpRequests;

  @override
  void initState() {
    super.initState();
    _helpRequests = fetchHelpRequests();
  }

  Future<List<Map<String, dynamic>>> fetchHelpRequests() async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('help')
          .select('*')
          .eq('card_id', widget.cardId)
          .order('status', ascending: true)
          .order('updated_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching help requests: $e');
    }
  }

  Future<void> updateHelpRequestStatus({
    required int helpId,
    required String newStatus,
    File? proofImage,
  }) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    try {
      // Prepare the update data
      Map<String, dynamic> updateData = {
        'status': newStatus,
        'status_marked_by': user?.email ?? user?.id,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // If a proof image is provided, upload it
      if (proofImage != null) {
        final fileName = '$helpId-proof-${DateTime.now().millisecondsSinceEpoch}.jpg';
        final bucketName = 'help_proof_images';

        // Upload the image and check for errors
        final uploadPath = await supabase.storage.from(bucketName).upload(fileName, proofImage);

        if (uploadPath.isEmpty) {
          throw Exception('Failed to upload proof image. Received empty response.');
        }

        // Generate the public URL for the uploaded image
        final imageUrl = supabase.storage.from(bucketName).getPublicUrl(fileName);

        if (imageUrl.isEmpty) {
          throw Exception('Failed to retrieve public URL for the uploaded proof image.');
        }

        // Add the image URL to the update data
        updateData['help_proof_pic'] = imageUrl;
      }

      // Update the help request in the database
      final updateResponse = await supabase
          .from('help')
          .update(updateData)
          .eq('id', helpId)
          .select() // Ensure it returns the updated record
          .single();

      // Check if the response is valid
      if (updateResponse == null) {
        throw Exception('Update query returned null. Help ID might not exist.');
      }

      // Notify success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully!')),
      );
    } catch (e) {
      // Notify error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }



  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request History'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _helpRequests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No help requests found.'));
          }

          final helpRequests = snapshot.data!;

          return ListView.builder(
            itemCount: helpRequests.length,
            itemBuilder: (context, index) {
              final help = helpRequests[index];

              String selectedStatus = help['status'] ?? 'pending';
              bool isEditing = false;
              File? proofImage;

              final createdAt = DateTime.parse(help['created_at']);
              final updatedAt = DateTime.parse(help['updated_at']);

              return StatefulBuilder(
                builder: (context, setInnerState) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Help Type: ${help['category']}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Description: ${help['description'] ?? 'None'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Status: $selectedStatus',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Request Created At: ${createdAt.toString()}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Request Updated At: ${updatedAt.toString()}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 15),

                          // Status Selection Section
                          if (isEditing)
                            Column(
                              children: [
                                // Status Selection
                                Column(
                                  children: ['pending', 'on my way', 'done'].map((status) {
                                    return RadioListTile<String>(
                                      title: Text(status),
                                      value: status,
                                      groupValue: selectedStatus,
                                      onChanged: (value) {
                                        setInnerState(() {
                                          selectedStatus = value!;
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 10),

                                // Image Upload Button
                                ElevatedButton(
                                  onPressed: () async {
                                    proofImage = await pickImage();
                                    if (proofImage != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Image selected successfully!')),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('No image selected.')),
                                      );
                                    }
                                  },
                                  child: const Text('Upload Proof Image'),
                                ),
                                const SizedBox(height: 10),

                                // Update Button
                                ElevatedButton(
                                  onPressed: () async {
                                    await updateHelpRequestStatus(
                                      helpId: help['id'],
                                      newStatus: selectedStatus,
                                      proofImage: proofImage,
                                    );

                                    setInnerState(() {
                                      isEditing = false;
                                    });

                                    setState(() {
                                      _helpRequests = fetchHelpRequests();
                                    });
                                  },
                                  child: const Text('Update Status'),
                                ),
                              ],
                            )
                          else
                            ElevatedButton(
                              onPressed: () {
                                setInnerState(() {
                                  isEditing = true;
                                });
                              },
                              child: const Text('Change Status'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
