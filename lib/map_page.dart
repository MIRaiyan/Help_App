import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:help/auth_service.dart';
import 'package:help/login.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'details.dart';
import 'register_homeless.dart';
import 'homeless_list.dart';
import 'tutorial.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  //get auth service
  final authService =AuthService();

  //logout button pressed
  void logout() async{
    await authService.signOut();
  }

  late final MapController mapController;
  List<Marker> _markers = [];
  Position? _currentPosition;
  bool _isLocationFetched = false;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _getUserLocation();
    _fetchHomelessPeople(); // Fetch homeless people's data
  }

  Future<void> _fetchHomelessPeople() async {
    try {
      final response = await Supabase.instance.client
          .from('homeless')
          .select('*, location') // Select location JSON column
          .limit(100);

      debugPrint('Fetched data: $response'); // Debug the response

      if (response.isNotEmpty) {
        setState(() {
          _markers = response
              .where((person) =>
          person['location'] != null &&
              person['location']['latitude'] != null &&
              person['location']['longitude'] != null)
              .map<Marker>((person) {
            final location = person['location'] as Map<String, dynamic>;
            final latitude = location['latitude'] as double;
            final longitude = location['longitude'] as double;

            return Marker(
              width: 80.0,
              height: 80.0,
              point: LatLng(latitude, longitude),
              builder: (ctx) => GestureDetector(
                onTap: () => _showHomelessDetail(person),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40.0,
                ),
              ),
            );
          }).toList();
        });
      } else {
        debugPrint('No data found');
      }
    } catch (e) {
      debugPrint('Error fetching homeless data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching homeless data: $e')),
      );
    }
  }

  // Navigate to HomelessDetailsPage
  void _showHomelessDetail(Map<String, dynamic> person) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomelessDetailsPage(
          person: person,
          location: person['location'],
        ),
      ),
    );
  }

  // Get User Location
  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      );

      setState(() {
        _currentPosition = position;
        _isLocationFetched = true;
        mapController.move(
          LatLng(position.latitude, position.longitude),
          15.0,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location: $e')),
      );
    }
  }

  // Zoom In
  void zoomIn() {
    mapController.move(mapController.center, mapController.zoom + 0.5);
  }

  // Zoom Out
  void zoomOut() {
    if (mapController.zoom > 2.0) {
      mapController.move(mapController.center, mapController.zoom - 0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    //final user = Supabase.instance.client.auth.currentUser;
    final email = authService.getCurrentUserEmail() ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text('HelpApp'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.red,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HelpApp Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Logged in as: $email',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Homeless Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomelessListPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Register Homeless'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterHomelessPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.question_mark),
              title: const Text('Tutorial'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TutorialPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              center: _isLocationFetched
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : LatLng(23.6850, 90.3563), // Default center (Bangladesh)
              zoom: _isLocationFetched ? 15.0 : 7.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: _markers,
              ),
            ],
          ),
          Positioned(
            top: 16.0,
            right: 16.0,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: zoomIn,
                  child: const Icon(Icons.zoom_in),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: zoomOut,
                  child: const Icon(Icons.zoom_out),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              mini: true,
              onPressed: _getUserLocation,
              child: const Icon(Icons.gps_fixed),
            ),
          ),
        ],
      ),
    );
  }
}
