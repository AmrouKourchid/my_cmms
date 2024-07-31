import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
class ViewReport extends StatelessWidget {
  final int workOrderId;
  const ViewReport({Key? key, required this.workOrderId}) : super(key: key);

  Future<dynamic> fetchReport() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'your_secret_key');
    final response = await http.get(
      Uri.parse('http://localhost:5506/reportByWorkOrderId/$workOrderId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
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
            title: Text('Report for Work Order ID: $workOrderId', style: Theme.of(context).textTheme.titleSmall ?? TextStyle()),
            content: SingleChildScrollView(
              child: Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: report['worker_name'],
                      decoration: const InputDecoration(
                        labelText: 'Worker Name',
                        border: OutlineInputBorder(),
                        enabled: false,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(6, (index) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          initialValue: report['question${index + 1}'],
                          decoration: InputDecoration(
                            labelText: 'Question ${index + 1}',
                            border: const OutlineInputBorder(),
                            enabled: false,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    )),
                    if (report['pictures'] != null && report['pictures'].isNotEmpty)
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: report['pictures'].map((pic) {
                          return Image.memory(base64Decode(pic), height: 100, width: 100);
                        }).toList(),
                      ),
                  ],
                ),
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