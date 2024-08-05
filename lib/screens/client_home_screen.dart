import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:snow_login/screens/login_screen.dart';
import 'package:intl/intl.dart';

class ClientHomeScreen extends StatefulWidget {
  final String token;

  const ClientHomeScreen({Key? key, required this.token}) : super(key: key);

  @override
  _ClientHomeScreenState createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final _storage = const FlutterSecureStorage();
  final TextEditingController _siteController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _dateOfFault = DateTime.now();
  String? _selectedAsset;
  List<dynamic> _assets = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    final response = await http.get(
      Uri.parse('http://localhost:5506/fetchAssets'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
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

   Future<void> _createWorkRequest() async {
    // Extract the payload from the JWT token
    var parts = widget.token.split('.');
    if (parts.length != 3) {
      print('Invalid token');
      return;
    }
    var payload = parts[1];
    var normalized = base64Url.normalize(payload);
    var decoded = utf8.decode(base64Url.decode(normalized));
    var payloadMap = json.decode(decoded);

    final response = await http.post(
      Uri.parse('http://localhost:5506/createWorkRequest'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'client_id': payloadMap['id'],
        'site': _siteController.text,
        'asset_id': _selectedAsset,
        'date_of_fault': _dateOfFault.toIso8601String(),
        'description': _descriptionController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Work request created successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create work request: ${response.body}')),
      );
    }
  }
 Widget buildTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
      ),
    );
  }


Widget buildDateField( DateTime initialDate) {
    return TextFormField(
      controller: TextEditingController(text: DateFormat('yyyy-MM-dd').format(initialDate)),
      decoration: InputDecoration(
  
        border: OutlineInputBorder(),
      ),
      readOnly: true,
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          setState(() {
            _dateOfFault = pickedDate;
          });
        }
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Client Home'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Client Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.work),
              title: Text('Create Work Request'),
              onTap: () {
                Navigator.pop(context);
                _createWorkRequest();
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Logout'),
              onTap: () {
                _storage.delete(key: 'your_secret_key');
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  ModalRoute.withName('/login'),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height, // Set height to fill the screen
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xff009fd6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Select Asset', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedAsset,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedAsset = newValue;
                      });
                    },
                    items: _assets.map<DropdownMenuItem<String>>((asset) {
                      return DropdownMenuItem<String>(
                        value: asset['id'].toString(),
                        child: Row(
                          children: [
                            asset['image'] != null
                                ? Image.memory(base64Decode(asset['image']), width: 30, height: 30)
                                : Icon(Icons.image_not_supported),
                            SizedBox(width: 10),
                            Text(asset['name']),
                          ],
                        ),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: 'Select Asset',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                  SizedBox(height: 30),
                  Text('Site Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  buildTextField(_siteController),
                  SizedBox(height: 30),
                  Text('Date of Fault', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  buildDateField( _dateOfFault),
                  SizedBox(height: 30),
                  Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  buildTextField(_descriptionController),
                  SizedBox(height: 30),
                  Center(
                  child :ElevatedButton(
                    onPressed: _createWorkRequest,
                    child: Text('Submit Work Request', style: TextStyle(color: Colors.white)),
                    
                     style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.green, // Teal color similar to the image
                     shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                     // Rounded corners
                        ),
                        padding: EdgeInsets.all(20), 
                        // Padding inside the button
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}