import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class MaterialPage extends StatefulWidget {
  final String token;

  const MaterialPage({super.key, required this.token});

  @override
  _MaterialPageState createState() => _MaterialPageState();
}

class _MaterialPageState extends State<MaterialPage> {
  List<dynamic> _materials = [];
  final _storage = const FlutterSecureStorage();
  bool _isAddingMaterial = false;
  String? _workerName;
  String? _workerImage;

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
    _fetchWorkerDetails();
  }

  Future<void> _fetchMaterials() async {
    final token = widget.token;
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token not found or invalid'),
        ),
      );
      return;
    }

    final response = await http.get(
      Uri.parse('http://localhost:5506/displayMaterials'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _materials = json.decode(response.body).map((material) => {
          'id': material['id'],
          'name': material['name'],
          'cost': material['cost'],
          'image': material['image']
        }).toList();
      });
    } else {
      print('Failed to load materials');
    }
  }

  Future<void> _fetchWorkerDetails() async {
    final token = widget.token;
    if (token.isEmpty) {
      return;
    }

    final response = await http.get(
      Uri.parse('http://localhost:5506/workerDetails'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _workerName = data['name'];
        _workerImage = data['image'];
      });
    } else {
      print('Failed to load worker details');
    }
  }

  void _showCreateMaterialDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController costController = TextEditingController();
    File? imageFile;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Material', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text("Fill in the details to add a new material", style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 20),
                const Text("Name"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Material Name',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Cost"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: costController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Material Cost',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Image"),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      imageFile = File(pickedFile.path);
                      setState(() {}); // Refresh the UI to show the image
                    }
                  },
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text("Upload Image", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                if (imageFile != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Image.file(
                      imageFile!,
                      height: 100,
                      width: 100,
                    ),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () async {
                Navigator.of(context).pop();
                _createMaterial(nameController.text, costController.text, imageFile);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _createMaterial(String name, String cost, File? imageFile) async {
    final token = await _storage.read(key: 'your_secret_key');
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token not found or invalid')),
      );
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://localhost:5506/createMaterial'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;
    request.fields['cost'] = cost;

    // Check if imageFile is not null before adding it to the request
    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }

    final response = await request.send();
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material created successfully')),
      );
      // Optionally refresh the list of materials
      _fetchMaterials();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create material: ${response.reasonPhrase}')),
      );
    }
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
                  padding: const EdgeInsets.only(bottom: 80.0),
                  child: Column(
                    children: _materials.map((material) {
                      return Card(
                        child: ListTile(
                          leading: material['image'] != null
                              ? CircleAvatar(
                                  backgroundImage: MemoryImage(base64Decode(material['image'])),
                                )
                              : const CircleAvatar(
                                  child: Icon(Icons.business),
                                ),
                          title: Text(material['name']),
                          subtitle: Text('Cost: ${material['cost']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteMaterial(material['id']),
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
            color: const Color(0xff009fd6),
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ElevatedButton(
                onPressed: _showCreateMaterialDialog,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Create Material', style: TextStyle(fontSize: 20, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMaterial(int id) async {
    final token = await _storage.read(key: 'your_secret_key');
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token not found or invalid')),
      );
      return;
    }

    final response = await http.delete(
      Uri.parse('http://localhost:5506/deleteMaterial/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material deleted successfully')),
      );
      setState(() {
        _materials.removeWhere((material) => material['id'] == id);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete material: ${response.body}')),
      );
    }
  }
}