import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snow_login/screens/login_screen.dart';
import 'package:snow_login/screens/home_screen.dart';
import 'package:snow_login/screens/worker_home_screen.dart';
void main(){
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp( const MyApp());
  });
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CMMS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/worker_home': (context) => WorkerHomeScreen(token: ''), // Placeholder token
      },
    );
  }
}