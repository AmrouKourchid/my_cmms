import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/home/home_form.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, String>> _workers = [];
  final _storage = const FlutterSecureStorage();

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
      Uri.parse('http://localhost:5506/workers'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> workers = jsonDecode(response.body);
      setState(() {
        _workers.clear();
        _workers.addAll(workers.map((worker) => {
              'email': worker['email'].toString(),
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

  Future<void> _addWorkerEmail(String email, String imagePath) async {
    setState(() {
      _workers.add({'email': email, 'image': imagePath});
    });
    await _fetchWorkers();
  }

  Future<void> _deleteWorkerEmail(String email) async {
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
      Uri.parse('http://localhost:5506/deleteWorker'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      setState(() {
        _workers.removeWhere((worker) => worker['email'] == email);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete worker'),
        ),
      );
    }
  }

  void _showRegisterForm() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: HomeForm(addWorkerEmail: _addWorkerEmail),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Center(
              child: Text(
                "Worker List",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
            ),
            const SizedBox(height: 16.0),
            ..._workers.map((worker) => ListTile(
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
                  title: Text(worker['email']!),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _deleteWorkerEmail(worker['email']!),
                        child: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                onPressed: _showRegisterForm,
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}