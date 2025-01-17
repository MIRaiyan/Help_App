import 'package:flutter/material.dart';

class TutorialPage extends StatelessWidget {
  const TutorialPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Use the App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Welcome to the App!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            buildTutorialSection(
              context,
              title: '1. Register a Homeless Person',
              content:
              'Use the "Register Homeless" feature to register a homeless person. Provide their details and upload their photo, NID images, and other required information.',
              icon: Icons.app_registration,
            ),
            const SizedBox(height: 20),
            buildTutorialSection(
              context,
              title: '2. Request Help',
              content:
              'To request help for a registered person, search for them using their Card ID. You can specify the type of help needed, add a description, and optionally upload a related image.',
              icon: Icons.help_outline,
            ),
            const SizedBox(height: 20),
            buildTutorialSection(
              context,
              title: '3. Update Help Status',
              content:
              'Once help has been provided, you can update the status of the help request. You can also upload proof images, such as a receipt or a picture of the provided aid.',
              icon: Icons.update,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              'Tips for Using the App:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '- Keep the Card ID handy for quicker access.\n'
                  '- Use clear and concise descriptions for help requests.\n'
                  '- Upload proof images to maintain transparency and accountability.\n',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTutorialSection(BuildContext context,
      {required String title, required String content, required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 40, color: Theme.of(context).primaryColor),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                content,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
