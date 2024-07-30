import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  _OrdersState createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String? _selectedWorker;
  String? _selectedAsset;
  List<dynamic> _workers = [];
  List<dynamic> _assets = [];
  List<File> _images = [];
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
    _fetchAssets();
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
      Uri.parse('http://localhost:5506/allWorkers'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _workers = json.decode(response.body);
      });
    } else {
      print('Failed to fetch workers');
    }
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
      print('Failed to fetch assets');
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    setState(() {
      _images.addAll(pickedFiles.map((file) => File(file.path)).toList());
    });
    }

  Future<void> _createWorkOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedWorker == null || _selectedAsset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both a worker and an asset'),
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

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://localhost:5506/createWorkOrder'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['worker_id'] = _selectedWorker!;
    request.fields['asset_id'] = _selectedAsset!;
    request.fields['name'] = _nameController.text;
    request.fields['start_date'] = DateFormat('yyyy-MM-dd').format(_startDate);
    request.fields['end_date'] = DateFormat('yyyy-MM-dd').format(_endDate);
    request.fields['description'] = _descriptionController.text;

    for (var image in _images) {
      request.files.add(await http.MultipartFile.fromPath('images', image.path));
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Work order created successfully'),
        ),
      );
      // Reset form fields
      _formKey.currentState!.reset();
      setState(() {
        _nameController.clear();
        _descriptionController.clear();
        _selectedWorker = null;
        _selectedAsset = null;
        _images = [];
        _startDate = DateTime.now();
        _endDate = DateTime.now();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create work order'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: 
        SingleChildScrollView(
          child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xff009fd6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Name"),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text("Description"),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text("Start Date"),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _startDate = pickedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      width: MediaQuery.of(context).size.width - 32,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(DateFormat('yyyy-MM-dd').format(_startDate)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("End Date"),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _endDate = pickedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      width: MediaQuery.of(context).size.width - 32,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(DateFormat('yyyy-MM-dd').format(_endDate)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Assign Worker"),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedWorker,
                    items: _workers.map<DropdownMenuItem<String>>((worker) {
                      return DropdownMenuItem<String>(
                        value: worker['id'].toString(),
                        child: Row(
                          children: [
                            worker['image'] != null
                                ? CircleAvatar(
                                    backgroundImage: MemoryImage(base64Decode(worker['image'])),
                                  )
                                : const CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                            const SizedBox(width: 8),
                            Text(worker['name']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedWorker = newValue;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a worker';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text("Select Asset"),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedAsset,
                    items: _assets.map<DropdownMenuItem<String>>((asset) {
                      return DropdownMenuItem<String>(
                        value: asset['id'].toString(),
                        child: Row(
                          children: [
                            asset['image'] != null
                                ? CircleAvatar(
                                    backgroundImage: MemoryImage(base64Decode(asset['image'])),
                                  )
                                : const CircleAvatar(
                                    child: Icon(Icons.business),
                                  ),
                            const SizedBox(width: 8),
                            Text(asset['name']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedAsset = newValue;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select an asset';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text("Upload Images"),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      height: 50,
                      width: MediaQuery.of(context).size.width - 32,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text("Upload", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_images.isNotEmpty)
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _images.map((image) {
                        return Image.file(
                          image,
                          height: 100,
                          width: 100,
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        ),
                        onPressed: _createWorkOrder,
                        child: const Text(
                          'Submit',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
    )
    );
  }
}