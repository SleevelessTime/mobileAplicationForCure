import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'doctorPanel.dart'; // Başarılı giriş yönlendirmesi için yeni sayfa
import 'staffLogin.dart'; // Staff login sayfasına dönme

class DoctorLoginPage extends StatefulWidget {
  @override
  _DoctorLoginPageState createState() => _DoctorLoginPageState();
}

class _DoctorLoginPageState extends State<DoctorLoginPage> {
  final _formKey = GlobalKey<FormState>();
  late String _doctorID;
  late String _password;
  bool _loginFailed = false;

  Future<bool> authenticateDoctor(String doctorID, String password) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/doktorGiris'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'DoktorID': doctorID, 'Sifre': password}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> result = jsonDecode(response.body);
      if (result.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SizedBox.shrink(), // Title text removed
        automaticallyImplyLeading: false, // Hides the back button
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
                    'Doctor Login',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  if (_loginFailed)
                    Text(
                      'DoctorID or password incorrect',
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'DoctorID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your DoctorID';
                      }
                      return null;
                    },
                    onSaved: (value) => _doctorID = value!,
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
                        bool isAuthenticated = await authenticateDoctor(_doctorID, _password);
                        if (isAuthenticated) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DoctorPanel(doctorID: _doctorID),
                            ),
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
                        MaterialPageRoute(builder: (context) => StaffLoginPage()),
                      );
                    },
                    child: Text(
                      'Go to Staff Login',
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
