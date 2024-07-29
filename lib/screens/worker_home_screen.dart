import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WorkerHomeScreen extends StatefulWidget {
  final String token;

  WorkerHomeScreen({required this.token});

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
      });
    } else {
      print('Failed to load worker details');
    }
  }

  void _updateWorkOrderStatus(int id, String status) async {
    final response = await http.put(
      Uri.parse('http://localhost:5506/updateWorkOrderStatus/$id'),
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
      _fetchWorkerOrders(); // Refresh the list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update work order status')),
      );
    }
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: 1));
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
             (_selectedDate.isAfter(startDate) && _selectedDate.isBefore(endDate.add(Duration(days: 1)))));
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_left),
                onPressed: _previousDay,
              ),
              Text(
                formattedDate,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.arrow_right),
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
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${order['status']}'),
                      Text(order['description']),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          String newStatus = order['status'] == 'open' ? 'in progress' : 'closed';
                          _updateWorkOrderStatus(order['id'], newStatus);
                        },
                        child: Text(order['status'] == 'open' ? 'Start Working' : 'Finish Working'),
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
        title: Text('Worker Home Screen'),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                children: [
                  _workerImage != null
                      ? CircleAvatar(
                          radius: 40,
                          backgroundImage: MemoryImage(base64Decode(_workerImage!)),
                        )
                      : CircleAvatar(
                          radius: 40,
                          child: Icon(Icons.person, size: 40),
                        ),
                  SizedBox(height: 10),
                  Text(
                    'Welcome back, ${_workerName ?? 'Worker'}',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text('Work Orders'),
              onTap: () => _onSelectItem(0),
            ),
            ListTile(
              title: Text('Logout'),
              onTap: () async {
                await _storage.delete(key: 'your_secret_key');
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
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