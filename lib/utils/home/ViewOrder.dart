import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
      Uri.parse('http://192.168.1.18:5506/allWorkOrders'),
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
      Uri.parse('http://192.168.1.18:5506/workOrder/$id'),
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
          return AlertDialog(
            title: Text(order['name']),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          return Image.memory(
                            base64Decode(image),
                            height: 100,
                            width: 100,
                          );
                        } catch (e) {
                          return Container(); // Handle invalid base64 strings gracefully
                        }
                      }).toList(),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
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

  void _deleteWorkOrder(int id) async {
    final token = await _storage.read(key: 'your_secret_key');
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token not found or invalid'),
        ),
      );
      return;
    }

    print('Deleting work order with ID: $id');

    final response = await http.delete(
      Uri.parse('http://192.168.1.18:5506/deleteWorkOrder/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      setState(() {
        _allOrders.removeWhere((order) => order['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Work order deleted successfully'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete work order'),
        ),
      );
    }
  }

  void _showDeleteConfirmationDialog(int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Work Order'),
          content: const Text('Are you sure you want to delete this work order?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteWorkOrder(id);
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
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _showDeleteConfirmationDialog(order['id']);
                            },
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${order['status']}'),
                          Text('Description: ${order['description']}'),
                          Text('Start Date: ${order['start_date']}'),
                          Text('End Date: ${order['end_date']}'),
                          Text('Assigned to: ${order['assigned_to']}'),
                          Text('Asset: ${order['asset_name']}'),
                          const SizedBox(height: 8), // Add some space before the button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ElevatedButton(
                                onPressed: () => _showDetailsDialog(order['id']),
                                child: const Text('Details', style: TextStyle(color: Color(0xff009fd6)),
                              ),),
                              const SizedBox(width: 8), // Reduce the space between buttons
                              if (order['status'] == 'closed')
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xff009fd6),
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
                                  child: const Text('View Report', style: TextStyle(color: Colors.white),),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
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
      if (mounted) { // Check if the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token not found or invalid'),
          ),
        );
      }
      return;
    }

    final response = await http.get(
      Uri.parse('http://192.168.1.18:5506/reportByWorkOrderId/${widget.workOrderId}'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _report = json.decode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load report'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report for Work Order ${widget.workOrderId}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Worker: ${_report['worker_name']}'),
            const SizedBox(height: 8),
            Text('Question 1: ${_report['question1']}'),
            Text('Question 2: ${_report['question2']}'),
            Text('Question 3: ${_report['question3']}'),
            Text('Question 4: ${_report['question4']}'),
            Text('Question 5: ${_report['question5']}'),
            Text('Question 6: ${_report['question6']}'),
            const SizedBox(height: 8),
            if (_report['pictures'] != null && _report['pictures'].isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: (_report['pictures'] as List<dynamic>).map((image) {
                  try {
                    return Image.memory(
                      base64Decode(image),
                      height: 100,
                      width: 100,
                    );
                  } catch (e) {
                    return Container(); // Handle invalid base64 strings gracefully
                  }
                }).toList(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}