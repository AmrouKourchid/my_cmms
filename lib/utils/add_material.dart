import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class MaterialPage extends StatefulWidget {
  const MaterialPage({super.key});

  @override
  _MaterialPageState createState() => _MaterialPageState();
}

class _MaterialPageState extends State<MaterialPage> {
  List<dynamic> _materials = [];
  final _storage = const FlutterSecureStorage();
  bool _isAddingMaterial = false;

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
  }

  Future<void> _fetchMaterials() async {
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
      Uri.parse('http:// 192.168.2.138:5506/displayMaterials'),
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

  Future<void> _addMaterial(String name, String cost, String imagePath) async {
    if (_isAddingMaterial) return;
    setState(() {
      _isAddingMaterial = true;
    });

    final token = await _storage.read(key: 'your_secret_key');
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token not found or invalid'),
        ),
      );
      setState(() {
        _isAddingMaterial = false;
      });
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http:// 192.168.2.138:5506/createMaterial'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;
    request.fields['cost'] = cost;
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    final response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Material added successfully'),
        ),
      );
      _fetchMaterials(); // Refresh the material list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add material'),
        ),
      );
    }

    setState(() {
      _isAddingMaterial = false;
    });
  }

  Future<void> _deleteMaterial(int id) async {
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
      Uri.parse('http:// 192.168.2.138:5506/deleteMaterial/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Material deleted successfully'),
        ),
      );
      _fetchMaterials(); // Refresh the material list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete material'),
        ),
      );
    }
  }

  void _showAddMaterialForm() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 90.0),
          child: AddMaterialForm(
            addMaterial: _addMaterial,
            onMaterialAdded: _fetchMaterials,
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Material'),
          content: const Text('Are you sure you want to delete this material?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMaterial(id);
              },
              child: const Text('Delete'),
            ),
          ],
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
                            onPressed: () => _showDeleteConfirmationDialog(material['id']),
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
                onPressed: _isAddingMaterial ? null : _showAddMaterialForm,
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
}

class AddMaterialForm extends StatefulWidget {
  final Function(String, String, String) addMaterial;
  final VoidCallback onMaterialAdded;

  const AddMaterialForm({super.key, required this.addMaterial, required this.onMaterialAdded});

  @override
  _AddMaterialFormState createState() => _AddMaterialFormState();
}

class _AddMaterialFormState extends State<AddMaterialForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  File? _imageFile;
  bool _isAddingMaterial = false;
  final FlutterSecureStorage _storage = const FlutterSecureStorage(); // Define _storage here
  String _selectedCurrency = '\$'; // Default currency

  Future<void> _addMaterial() async {
    if (_isAddingMaterial) return;
    setState(() {
      _isAddingMaterial = true;
    });

    final name = _nameController.text;
    final cost = _costController.text;

    if (name.isEmpty || cost.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing fields!'),
        ),
      );
      setState(() {
        _isAddingMaterial = false;
      });
      return;
    }

    final token = await _storage.read(key: 'your_secret_key');
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token not found or invalid'),
        ),
      );
      setState(() {
        _isAddingMaterial = false;
      });
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http:// 192.168.2.138:5506/createMaterial'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;
    request.fields['cost'] = '$_selectedCurrency$cost'; // Format cost with selected currency
    request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Material added successfully'),
        ),
      );
      Navigator.of(context).pop();
      widget.onMaterialAdded();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add material'),
        ),
      );
    }

    setState(() {
      _isAddingMaterial = false;
    });
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
                      "Add Material",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Fill in the details to add a new material",
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
                          hintText: 'Material Name',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Cost"),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 32,
                      child: Stack(
                        children: [
                          TextFormField(
                            controller: _costController,
                            style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Material Cost',
                              hintStyle: const TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: DropdownButton<String>(
                              value: _selectedCurrency,
                              items: const [
                                DropdownMenuItem(
                                  value: '\$',
                                  child: Text('\$'),
                                ),
                                DropdownMenuItem(
                                  value: '€',
                                  child: Text('€'),
                                ),
                                DropdownMenuItem(
                                  value: 'TND',
                                  child: Text('TND'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCurrency = value!;
                                });
                              },
                            ),
                          ),
                        ],
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
                      onTap: _addMaterial,
                      child: Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width - 32,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text("Add Material", style: TextStyle(color: Colors.white, fontSize: 16)),
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