import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddReport extends StatefulWidget {
  final int workOrderId;
  final int workerId;
  final String workerName;
  final String workerImage;

  const AddReport({
    super.key,
    required this.workOrderId,
    required this.workerId,
    required this.workerName,
    required this.workerImage,
  });

  @override
  _AddReportState createState() => _AddReportState();
}

class _AddReportState extends State<AddReport> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  final List<XFile> _pictures = [];
  final _questions = List<String>.filled(6, '');

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final token = await _storage.read(key: 'your_secret_key');
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token not found or invalid'),
          ),
        );
        return;
      }

      final request = http.MultipartRequest('POST', Uri.parse('http://192.168.2.147:5506/createReport'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['worker_id'] = widget.workerId.toString();
      request.fields['work_order_id'] = widget.workOrderId.toString();
      for (int i = 0; i < _questions.length; i++) {
        request.fields['Question${i + 1}'] = _questions[i];
      }
      for (var picture in _pictures) {
        request.files.add(await http.MultipartFile.fromPath('pictures', picture.path));
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully'),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit report'),
          ),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _pictures.addAll(pickedFiles);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Submit Report'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
          
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Work Order:'),
              Text('${widget.workOrderId}', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    widget.workerImage.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: MemoryImage(base64Decode(widget.workerImage)),
                          radius: 15,
                        )
                      : const CircleAvatar(
                          child: Icon(Icons.person, size: 30),
                          radius: 30,
                        ),
                    const SizedBox(width: 8),
                    Text(widget.workerName, style: TextStyle(fontSize: 20)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ...List.generate(_questions.length, (i) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Question ${i + 1}'),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSaved: (value) {
                      _questions[i] = value ?? ''; // Ensuring null safety
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              )),
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
                  child: const Text("Upload Images", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
              if (_pictures.isNotEmpty)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _pictures.map((picture) {
                    return Image.file(
                      File(picture.path),
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
                    onPressed: _submitReport,
                    child: const Text(
                      'Submit Report',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}