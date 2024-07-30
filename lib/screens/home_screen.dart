import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/home/add_worker.dart';
import '../utils/home/CreateOrder.dart';
import '../utils/home/ViewOrder.dart';
import '../utils/home/Asset.dart'; // Import the Asset page

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, String>> _workers = [];
  final _storage = const FlutterSecureStorage();
  int _selectedDrawerIndex = 0;

  final List<String> _titles = [
    'Worker List',
    'Create Work Orders',
    'View Work Orders',
    'Assets'
  ];

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
  }

  Future<void> _fetchWorkers() async {
    final token = await _storage.read(key: 'your_secret_key');
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token not found or invalid'),
        ),
      );
      return;
    }

    final response = await http.get(
      Uri.parse('http://192.168.1.18:5506/workers'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> workers = jsonDecode(response.body);
      setState(() {
        _workers.clear();
        _workers.addAll(workers.map((worker) => {
              'name': worker['name'].toString(),
              'image': worker['image']?.toString() ?? '',
            }));
      });
    } else {
      print('Failed to fetch workers: ${response.statusCode}');
      print('Response body: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch workers'),
        ),
      );
    }
  }

  Future<void> _addWorkerName(String name, String imagePath) async {
    setState(() {
      _workers.add({'name': name, 'image': imagePath});
    });
    await _fetchWorkers();
  }

  Future<void> _deleteWorkerName(String name) async {
    final token = await _storage.read(key: 'your_secret_key');
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token not found or invalid'),
        ),
      );
      return;
    }

    final response = await http.delete(
      Uri.parse('http://192.168.1.18:5506/deleteWorker'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 200) {
      setState(() {
        _workers.removeWhere((worker) => worker['name'] == name);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Worker deleted successfully'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete worker'),
        ),
      );
    }
  }

  Future<void> _confirmDeleteWorker(String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: const Text('Are you sure you want to delete the user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _deleteWorkerName(name);
    }
  }

  void _showRegisterForm() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: HomeForm(addWorkerName: _addWorkerName),
        );
      },
    );
  }

  void _onSelectItem(int index) {
    setState(() {
      _selectedDrawerIndex = index;
    });
    Navigator.of(context).pop(); // close the drawer
  }

  Widget _getDrawerItemWidget(int pos) {
    switch (pos) {
      case 0:
        return _buildWorkerList();
      case 1:
        return const Orders();
      case 2:
        return const AllOrders();
      case 3:
        return const AssetPage(); // Add the Asset page
      default:
        return const Text("Error");
    }
  }

  Widget _buildWorkerList() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Worker List",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                ),
                SizedBox(height: 4),
                Text(
                  "Below are the workers in our CMMS",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 22.6, top: 22.6),
                  child: ElevatedButton(
                    onPressed: _showRegisterForm,
                    child: const Text(
                      'Add',
                      style: TextStyle(color: Color(0xff009fd6), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        Expanded(
          child: ListView(
            children: _workers.map((worker) => ListTile(
              leading: worker['image']!.isNotEmpty
                  ? CircleAvatar(
                      backgroundImage: MemoryImage(
                        base64Decode(worker['image']!),
                      ),
                      onBackgroundImageError: (_, __) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            worker['image'] = '';
                          });
                        });
                      },
                    )
                  : const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
              title: Text(worker['name']!),
              trailing: ElevatedButton(
                onPressed: () => _confirmDeleteWorker(worker['name']!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedDrawerIndex]),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Admin Menu'),
            ),
            ListTile(
              title: const Text('Workers'),
              onTap: () => _onSelectItem(0),
            ),
            ListTile(
              title: const Text('Create Work Orders'),
              onTap: () => _onSelectItem(1),
            ),
            ListTile(
              title: const Text('View Work Orders'),
              onTap: () => _onSelectItem(2),
            ),
            ListTile(
              title: const Text('Assets'), // Add the Assets option
              onTap: () => _onSelectItem(3),
            ),
            ListTile(
              title: const Text('Logout'),
              onTap: () async {
                await _storage.delete(key: 'your_secret_key');
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xff009fd6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _getDrawerItemWidget(_selectedDrawerIndex),
        ),
      ),
    );
  }
}