import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ViewReport extends StatelessWidget {
  final int workOrderId;
  const ViewReport({Key? key, required this.workOrderId}) : super(key: key);

  Future<dynamic> fetchReport() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'your_secret_key');
    final response = await http.get(
      Uri.parse('http://192.168.1.18:5506/reportByWorkOrderId/$workOrderId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      // Log the status code and response body for debugging
      print('Failed to load report, Status code: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Failed to load report, Status code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: fetchReport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final report = snapshot.data;
          return AlertDialog(
            backgroundColor: Colors.transparent,
            title: Text('Report for Work Order ID: $workOrderId'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Worker Name: ${report['worker_name']}'),
                  Text('Question 1: ${report['Question1']}'),
                  Text('Question 2: ${report['Question2']}'),
                  Text('Question 3: ${report['Question3']}'),
                  Text('Question 4: ${report['Question4']}'),
                  Text('Question 5: ${report['Question5']}'),
                  Text('Question 6: ${report['Question6']}'),
                  ...report['pictures'].map((pic) => Image.memory(base64Decode(pic))),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        }
      },
    );
  }
}
