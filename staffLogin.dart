import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'machineStatusPage.dart'; // Giriş başarılı olduğunda yönlendirilecek sayfa
import 'LoginPage.dart';

class StaffLoginPage extends StatefulWidget {
  @override
  _StaffLoginPageState createState() => _StaffLoginPageState();
}

class _StaffLoginPageState extends State<StaffLoginPage> {
  final _formKey = GlobalKey<FormState>();
  late String _staffID;
  late String _password;
  bool _loginFailed = false;

  Future<bool> authenticateStaff(String staffID, String password) async {
    final response = await http.get(Uri.parse('http://10.0.2.2:5000/staffGiris'));

    if (response.statusCode == 200) {
      List<dynamic> staffMembers = jsonDecode(response.body);

      for (var staff in staffMembers) {
        if (staff['staffID'].toString() == staffID && staff['staffSifre'] == password) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SizedBox.shrink(), // Başlık metnini kaldırır
        automaticallyImplyLeading: false, // Geri butonunu gizler
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Staff Login',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  if (_loginFailed)
                    Text(
                      'StaffID or password incorrect',
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'StaffID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your StaffID';
                      }
                      return null;
                    },
                    onSaved: (value) => _staffID = value!,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    onSaved: (value) => _password = value!,
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        bool isAuthenticated = await authenticateStaff(_staffID, _password);
                        if (isAuthenticated) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => MachineStatusPage()),
                          );
                        } else {
                          setState(() {
                            _loginFailed = true;
                          });
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                    child: Text('Login'),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    child: Text(
                      'Go to User Login',
                      style: TextStyle(fontSize: 16),
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
