import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';


Future<void> saveImage(Uint8List imageData, String imageName) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$imageName';
    final file = File(filePath);
    await file.writeAsBytes(imageData);
    print('Image saved to $filePath');
  } catch (e) {
    print('Failed to save image: $e');
  }
}
class AllOrders extends StatefulWidget {
  const AllOrders({super.key});

  @override
  _AllOrdersState createState() => _AllOrdersState();
}

class _AllOrdersState extends State<AllOrders> {
  List<dynamic> _allOrders = [];
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchAllOrders();
  }

  void _fetchAllOrders() async {
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
      Uri.parse('http://localhost:5506/allWorkOrders'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _allOrders = json.decode(response.body);
      });
    } else {
      print('Failed to load work orders');
    }
  }

  void _showImageDialog(Uint8List imageData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: MemoryImage(imageData),
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDetailsDialog(int id) async {
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
      Uri.parse('http://localhost:5506/workOrder/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final order = json.decode(response.body);
      showDialog(
        context: context,
        barrierColor: Colors.transparent, // Ensure the background does not dim
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0), // Rounded corners for the dialog
            ),
            elevation: 5.0, // Adds shadow under the dialog
            backgroundColor: Colors.transparent, // Make dialog background transparent
            child: Container(
              padding: const EdgeInsets.all(20.0), // Padding inside the dialog
              width: MediaQuery.of(context).size.width * 0.9, // Dialog width is 90% of screen width
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0), // Match dialog rounded corners
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xff009fd6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView( // Use SingleChildScrollView to handle overflow
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Status: ${order['status']}'),
                    Text('Description: ${order['description']}'),
                    Text('Start Date: ${order['start_date']}'),
                    Text('End Date: ${order['end_date']}'),
                    Text('Assigned to: ${order['assigned_to']}'),
                    Text('Asset: ${order['asset_name']}'),
                    if (order['images'] != null && order['images'].isNotEmpty)
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: (order['images'] as List<dynamic>).map((image) {
                          try {
                            final imageData = base64Decode(image);
                            return GestureDetector(
                              onTap: () => _showImageDialog(imageData),
                              child: Image.memory(
                                imageData,
                                height: 100,
                                width: 100,
                              ),
                            );
                          } catch (e) {
                            return Container(); // Handle invalid base64 strings gracefully
                          }
                        }).toList(),
                      ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load work order details'),
        ),
      );
    }
  }

  Widget _buildWorkOrderCard(dynamic order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text('Status: ${order['status']}'),
                Text('Description: ${order['description']}'),
                Text('Start Date: ${order['start_date']}'),
                Text('End Date: ${order['end_date']}'),
                Text('Assigned to: ${order['assigned_to']}'),
                Text('Asset: ${order['asset_name']}'),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => _showDetailsDialog(order['id']),
                      child: const Text('Details', style: TextStyle(color: Color(0xff009fd6))),
                    ),
                    const SizedBox(width: 8), // Space between buttons
                    if (order['status'] == 'closed')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff009fd6),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierColor: Colors.transparent, // Ensure the background does not dim
                            builder: (BuildContext context) {
                              return Dialog(
                                backgroundColor: Colors.transparent,
                                child: ViewReport(workOrderId: order['id']),
                              );
                            },
                          );
                        },
                        child: const Text('View Report', style: TextStyle(color: Colors.white)),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                icon: const Icon(Icons.close), // Using 'close' icon which looks like an 'X'
                onPressed: () => _confirmDelete(order['id']),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this work order?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _deleteWorkOrder(id);
    }
  }

  void _deleteWorkOrder(int id) async {
    final token = await _storage.read(key: 'your_secret_key');
    final response = await http.delete(
      Uri.parse('http://localhost:5506/deleteWorkOrder/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _allOrders.removeWhere((order) => order['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Work order deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete work order')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xff009fd6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _allOrders.length,
                itemBuilder: (context, index) {
                  var order = _allOrders[index];
                  return _buildWorkOrderCard(order);
                },
              ),
            ),
          ],
        ),
      ),
    
    );
  }
}


class ViewReport extends StatefulWidget {
  const ViewReport({super.key, required this.workOrderId});

  final int workOrderId;

  @override
  _ViewReportState createState() => _ViewReportState();
}

class _ViewReportState extends State<ViewReport> {
  Map<String, dynamic> _report = {};
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  void _fetchReport() async {
    final token = await _storage.read(key: 'your_secret_key');
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token not found or invalid'),
          ),
        );
      }
      return;
    }

    final response = await http.get(
      Uri.parse('http://localhost:5506/reportByWorkOrderId/${widget.workOrderId}'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _report = json.decode(response.body) ?? {};
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load report'),
        ),
      );
    }
  }

  Widget _buildReadOnlyTextField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: TextEditingController(text: value ?? 'Not available'), // Use a fallback value if null
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        readOnly: true,
      ),
    );
  }

  void _showImageDialog(Uint8List imageData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: MemoryImage(imageData),
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 5.0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xff009fd6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Report for Work Order ${widget.workOrderId}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildReadOnlyTextField('Worker', _report['worker_name']),
              _buildReadOnlyTextField('Question 1', _report['question1']),
              _buildReadOnlyTextField('Question 2', _report['question2']),
              _buildReadOnlyTextField('Question 3', _report['question3']),
              _buildReadOnlyTextField('Question 4', _report['question4']),
              _buildReadOnlyTextField('Question 5', _report['question5']),
              _buildReadOnlyTextField('Question 6', _report['question6']),
              
              const Text("Pictures"),
              const SizedBox( height: 8),
              if (_report['pictures'] != null && (_report['pictures'] as List<dynamic>).isNotEmpty)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: (_report['pictures'] as List<dynamic>).map((image) {
                    try {
                      final imageData = base64Decode(image);
                      return GestureDetector(
                        onTap: () => _showImageDialog(imageData),
                        child: Image.memory(
                          imageData,
                          height: 100,
                          width: 100,
                        ),
                      );
                    } catch (e) {
                      return Container(); // Handle invalid base64 strings gracefully
                    }
                  }).toList(),
                ),
              const SizedBox(height: 20),
              const Text("Materials Used:"),
              const SizedBox( height: 8),
              if (_report['materials'] != null && (_report['materials'] as List<dynamic>).isNotEmpty)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: (_report['materials'] as List<dynamic>).map((material) {
                    return Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (material['image'] != null && material['image'].isNotEmpty)
                            CircleAvatar(
                              backgroundImage: MemoryImage(base64Decode(material['image'])),
                              radius: 20,
                            ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(material['name']),
                              Text(material['cost'], style: const TextStyle( fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}