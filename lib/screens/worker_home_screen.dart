import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/add_report.dart'; // Import the AddReport widget
import 'dart:typed_data';
import '../utils/add_material.dart' as material_utils;

class WorkerHomeScreen extends StatefulWidget {
  final String token;

  const WorkerHomeScreen({super.key, required this.token});

  @override
  _WorkerHomeScreenState createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _workerOrders = [];
  final _storage = const FlutterSecureStorage();
  String? _workerName;
  String? _workerImage;
  int? _workerId;
  final PageController _pageController = PageController();
  int _selectedDrawerIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchWorkerOrders();
    _fetchWorkerDetails();
  }

  void _fetchWorkerOrders() async {
    final response = await http.get(
      Uri.parse('http:// 192.168.2.138:5506/workerOrders'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _workerOrders = json.decode(response.body);
      });
    } else {
      print('Failed to load worker orders');
    }
  }

  void _fetchWorkerDetails() async {
    final response = await http.get(
      Uri.parse('http:// 192.168.2.138:5506/workerDetails'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _workerName = data['name'];
        _workerImage = data['image'];
        _workerId = data['id'];
      });
    } else {
      print('Failed to load worker details');
    }
  }

  void _updateWorkOrderStatus(int id, String status) async {
    final response = await http.put(
      Uri.parse('http:// 192.168.2.138:5506/updateWorkOrderStatus/$id'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Work order status updated to $status')),
      );
      _fetchWorkerOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update work order status')),
      );
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
      Uri.parse('http:// 192.168.2.138:5506/workOrder/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final order = json.decode(response.body);
      showDialog(
        context: context,
        builder: (context) {
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
                          if (image != null) {
                            final imageData = base64Decode(image);
                            return GestureDetector(
                              onTap: () => _showImageDialog(imageData),
                              child: Image.memory(
                                imageData,
                                height: 100,
                                width: 100,
                              ),
                            );
                          } else {
                            return Container();
                          }
                        }).toList(),
                      ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close', style: TextStyle(color: Colors.white)),
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

  Future<void> _showReportDialog(int workOrderId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AddReport(
          workOrderId: workOrderId,
          workerId: _workerId ?? 0, // Pass the workerId
          workerName: _workerName ?? 'Worker',
          workerImage: _workerImage ?? '',
        );
      },
    );

    if (result == true) {
      _fetchWorkerOrders(); // Refresh the list if the report was submitted
    }
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
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
        return _buildWorkOrders();
      case 1:
        return const material_utils.MaterialPage();
      default:
        return const Text("Error");
    }
  }

  Widget _buildWorkOrders() {
    String formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);

    List<dynamic> ordersForSelectedDate = _workerOrders.where((order) {
      DateTime startDate = DateTime.parse(order['start_date']);
      DateTime endDate = DateTime.parse(order['end_date']);
      return (order['status'] != 'closed') &&
             (_selectedDate.isAtSameMomentAs(startDate) ||
             (_selectedDate.isAfter(startDate) && _selectedDate.isBefore(endDate.add(const Duration(days: 1)))));
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: _previousDay,
              ),
              Text(
                formattedDate,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: _nextDay,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: ordersForSelectedDate.length,
            itemBuilder: (context, index) {
              var order = ordersForSelectedDate[index];
              return Card(
                child: ListTile(
                  title: Text(
                    order['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${order['status']}'),
                      Text(order['description']),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () {
                              if (order['status'] == 'open') {
                                _updateWorkOrderStatus(order['id'], 'in progress');
                              } else {
                                _showReportDialog(order['id']);
                              }
                            },
                            child: Text(order['status'] == 'open' ? 'Start Working' : 'Finish Working', style: const TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 8), // Add some space between the buttons
                          ElevatedButton(
                            onPressed: () => _showDetailsDialog(order['id']),
                            child: const Text('Details', style: TextStyle(color: Color(0xff009fd6)),),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Home Screen'),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                children: [
                  _workerImage != null
                      ? CircleAvatar(
                          radius: 40,
                          backgroundImage: MemoryImage(base64Decode(_workerImage!)),
                        )
                      : const CircleAvatar(
                          radius: 40,
                          child: Icon(Icons.person, size: 40),
                        ),
                  const SizedBox(height: 10),
                  Text(
                    'Welcome back, ${_workerName ?? 'Worker'}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.view_list),
              title: const Text('Work Orders'),
              onTap: () => _onSelectItem(0),
            ),
           
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Create Material'),
              onTap: () => _onSelectItem(1),
            ),
             ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Logout'),
              onTap: () async {
                await _storage.delete(key: 'your_secret_key');
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
      ),
      body: Container (
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xff009fd6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: PageView(
        controller: _pageController,
        children: [
          _getDrawerItemWidget(_selectedDrawerIndex),
        ],
      ),
    ),
    );
  }
}