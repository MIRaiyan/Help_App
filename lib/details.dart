import 'package:flutter/material.dart';
import 'help_form.dart'; // Import the Help Form Page
import 'request_history.dart';

class HomelessDetailsPage extends StatelessWidget {
  final Map<String, dynamic> person;
  final Map<String, dynamic>? location;

  const HomelessDetailsPage({
    Key? key,
    required this.person,
    this.location,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract location data or set default values if null
    final district = location?['district'] ?? 'Unknown District';
    final subdistrict = location?['subdistrict'] ?? 'Unknown Subdistrict';
    final street = location?['street'] ?? 'Unknown Street';
    final house = location?['house'] ?? 'Unknown House';
    final latitude = location?['latitude'] ?? 0.0;
    final longitude = location?['longitude'] ?? 0.0;

    // Fetch the homeless person's picture URL
    final faceUrl = person['face'] ?? ''; // Default to an empty string if null

    return Scaffold(
      appBar: AppBar(
        title: const Text('Homeless Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display the homeless person's picture
              if (faceUrl.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      faceUrl,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text('Error loading image');
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),
                  ),
                )
              else
                Center(
                  child: const Text(
                    'No Image Available',
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ),
              const SizedBox(height: 16),
              // Show Card ID
              Text(
                'Card ID: ${person['card_id']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Show other person details
              Text(
                'Internal ID: ${person['id']}', // Keep the original ID for context
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              // Show location details
              Text(
                'Location Details:',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'District: $district',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Subdistrict: $subdistrict',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Street: $street',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'House: $house',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              // Latitude and Longitude
              Text(
                'Geographical Coordinates:',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Latitude: $latitude',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Longitude: $longitude',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              // Additional details
              Text(
                'Additional Details:',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                person['additional_info'] ?? 'No additional details provided.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              // "Request Help" and "View Requests" buttons
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                HelpFormPage(cardId: person['card_id']),
                          ),
                        );
                      },
                      child: const Text('Request Help'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RequestHistoryPage(cardId: person['card_id']),
                          ),
                        );
                      },
                      child: const Text('View Requests'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
