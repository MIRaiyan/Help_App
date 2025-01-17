import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'details.dart';

class HomelessListPage extends StatefulWidget {
  const HomelessListPage({Key? key}) : super(key: key);

  @override
  State<HomelessListPage> createState() => _HomelessListPageState();
}

class _HomelessListPageState extends State<HomelessListPage> {
  List<Map<String, dynamic>> _filteredHomelessList = [];
  final TextEditingController _searchController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchHomelessList(); // Fetch initial data
  }

  // Fetch the list of homeless people
  Future<void> _fetchHomelessList() async {
    try {
      final response = await _supabase
          .from('homeless')
          .select('*') // Fetch all columns
          .limit(100);

      setState(() {
        _filteredHomelessList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error fetching homeless data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching homeless data: $e')),
      );
    }
  }

  // Fetch filtered data based on card_id
  Future<void> _fetchFilteredData(String query) async {
    if (query.isEmpty) {
      _fetchHomelessList(); // Fetch all if the query is empty
      return;
    }

    try {
      final response = await _supabase
          .from('homeless')
          .select('*')
          .ilike('card_id', '%$query%') // Search by card_id using a case-insensitive filter
          .limit(100);

      setState(() {
        _filteredHomelessList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error searching data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homeless List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by Card ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _fetchFilteredData, // Fetch filtered data as user types
            ),
          ),
          Expanded(
            child: _filteredHomelessList.isEmpty
                ? const Center(child: Text('No data found'))
                : ListView.builder(
              itemCount: _filteredHomelessList.length,
              itemBuilder: (context, index) {
                final person = _filteredHomelessList[index];
                final location = person['location'] as Map<String, dynamic>?;

                // Extract location details
                final house = location?['house'] ?? 'Unknown House';
                final street = location?['street'] ?? 'Unknown Street';
                final district = location?['district'] ?? 'Unknown District';
                final subdistrict = location?['subdistrict'] ?? 'Unknown Subdistrict';
                final latitude = location?['latitude'] ?? 0.0;
                final longitude = location?['longitude'] ?? 0.0;

                return ListTile(
                  title: Text('Card ID: ${person['card_id']}, $district'),
                  subtitle: Text(
                      '$subdistrict, $street, $house\nLatitude: $latitude, Longitude: $longitude'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomelessDetailsPage(
                          person: person,
                          location: location,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
