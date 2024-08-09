import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/add_material.dart' as material_utils; // Adjusted import

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
  int _selectedDrawerIndex = 0;
  String? _workerName; 
  String? _workerImage;
  int? _workerId;

  @override
  void initState() {
    super.initState();
    _fetchWorkerOrders();
    _fetchWorkerDetails();
  }

  void _fetchWorkerOrders() async {
    final response = await http.get(
      Uri.parse('http://localhost:5506/workerOrders'),
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
      Uri.parse('http://localhost:5506/workerDetails'),
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

  void _onSelectItem(int index) {
    setState(() {
      _selectedDrawerIndex = index;
    });
  }

  Widget _getDrawerItemWidget(int pos) {
    switch (pos) {
      case 0:
        return _buildWorkOrders();
      case 1:
        return material_utils.MaterialPage(token: widget.token); // Pass token to MaterialPage
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
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  });
                },
              ),
              Text(
                formattedDate,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                },
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
                              // Update work order status
                            },
                            child: Text(order['status'] == 'open' ? 'Start Working' : 'Finish Working', style: const TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              // Show details dialog
                            },
                            child: const Text('Details'),
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
              onTap: () => {_onSelectItem(0), Navigator.of(context).pop()},
              
            ),
            ListTile(
              leading: const Icon(Icons.home_work),
              title: const Text('Materials'),
              
              onTap: () =>  {_onSelectItem(1), Navigator.of(context).pop()},
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