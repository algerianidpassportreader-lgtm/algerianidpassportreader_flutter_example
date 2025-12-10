import 'package:flutter/material.dart';
import 'package:aaaa_project/screens/mrzInfo.dart';
import 'package:aaaa_project/services/algerian_id_sdk.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AlgerianIdSdk.initializeWithToken();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MrzInfo(), debugShowCheckedModeBanner: false);
  }
}
