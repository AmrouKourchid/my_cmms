import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AssetPage extends StatefulWidget {
  const AssetPage({super.key});

  @override
  _AssetPageState createState() => _AssetPageState();
}

class _AssetPageState extends State<AssetPage> {
  List<dynamic> _assets = [];
  final _storage = const FlutterSecureStorage();
  bool _isAddingAsset = false;

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
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
      Uri.parse('http://localhost:5506/fetchAssets'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _assets = json.decode(response.body);
      });
    } else {
      print('Failed to load assets');
    }
  }

  Future<void> _addAsset(String name, String status, String imagePath) async {
    setState(() {
      _isAddingAsset = true;
    });

    final token = await _storage.read(key: 'your_secret_key');
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token not found or invalid'),
        ),
      );
      setState(() {
        _isAddingAsset = false;
      });
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://localhost:5506/addAsset'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;
    request.fields['status'] = status;
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    final response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asset added successfully'),
        ),
      );
      _fetchAssets(); // Refresh the asset list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add asset'),
        ),
      );
    }

    setState(() {
      _isAddingAsset = false;
    });
  }

  Future<void> _deleteAsset(int id) async {
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
      Uri.parse('http://localhost:5506/deleteAsset/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asset deleted successfully'),
        ),
      );
      _fetchAssets(); // Refresh the asset list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete asset'),
        ),
      );
    }
  }

  void _showDeleteConfirmationDialog(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Do you really want to delete this asset?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAsset(id);
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddAssetForm() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: AddAssetForm(addAsset: _addAsset),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Color(0xff009fd6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80.0), // Add padding to the bottom
                  child: Column(
                    children: _assets.map((asset) {
                      return Card(
                        child: ListTile(
                          leading: asset['image'] != null
                              ? CircleAvatar(
                                  backgroundImage: MemoryImage(
                                    base64Decode(asset['image']),
                                  ),
                                )
                              : const CircleAvatar(
                                  child: Icon(Icons.business),
                                ),
                          title: Text(asset['name']),
                          subtitle: Text('Status: ${asset['status']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _showDeleteConfirmationDialog(asset['id']),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: const Color(0xff009fd6), // Set the same color as the button
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: _isAddingAsset ? null : _showAddAssetForm,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    // add width and height
                    
                  ),
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50), // Change the color here
                ),
                child: const Text('Add Asset', style: TextStyle(fontSize: 20, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddAssetForm extends StatefulWidget {
  final Function(String, String, String) addAsset;

  const AddAssetForm({super.key, required this.addAsset});

  @override
  _AddAssetFormState createState() => _AddAssetFormState();
}

class _AddAssetFormState extends State<AddAssetForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  String _selectedStatus = 'functional';
  File? _imageFile;

  final _storage = const FlutterSecureStorage();

  Future<void> _addAsset() async {
    final name = _nameController.text;
    final status = _selectedStatus;

    if (name.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing fields!'),
        ),
      );
      return;
    }

    final token = await _storage.read(key: 'your_secret_key');
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token not found or invalid'),
        ),
      );
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://localhost:5506/addAsset'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;
    request.fields['status'] = status;
    request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asset added successfully'),
        ),
      );
      widget.addAsset(name, status, _imageFile!.path);
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add asset'),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Add Asset",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Fill in the details to add a new asset",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    const Text("Name"),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 32,
                      child: TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Asset Name',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Status"),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 32,
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        items: ['functional', 'needs checking', 'faulty'].map((String status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedStatus = newValue!;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Image"),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width - 32,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text("Upload Image", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_imageFile != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Image.file(
                          _imageFile!,
                          height: 100,
                          width: 100,
                        ),
                      ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _addAsset,
                      child: Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width - 32,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text("Add Asset", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
