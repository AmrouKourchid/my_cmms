import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AllOrders extends StatefulWidget {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Work Orders'),
        automaticallyImplyLeading: false, // Remove the back button
      ),
      body: ListView.builder(
        itemCount: _allOrders.length,
        itemBuilder: (context, index) {
          var order = _allOrders[index];
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
                  Text('Description: ${order['description']}'),
                  Text('Start Date: ${order['start_date']}'),
                  Text('End Date: ${order['end_date']}'),
                  Text('Assigned to: ${order['assigned_to']}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}