import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'HomePage.dart'; // Giriş başarılı olduğunda yönlendirilecek sayfa
import 'RegisterPage.dart';
import 'staffLogin.dart'; // Staff login sayfası import edildi

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LoginForm(),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  late String _tc;
  late String _password;
  bool _loginFailed = false;

  Future<bool> authenticateUser(String tc, String password) async {
    final response = await http.get(Uri.parse('http://10.0.2.2:5000/kullaniciGiris'));

    if (response.statusCode == 200) {
      List<dynamic> users = jsonDecode(response.body);
      for (var user in users) {
        if (user['TC'] == tc && user['Sifre'] == password) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 60.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Login to your account',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 32),
                if (_loginFailed)
                  Text(
                    'Kullanıcı adı veya şifre yanlış',
                    style: TextStyle(color: Colors.red),
                  ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'TC',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen TC\'nizi girin';
                    }
                    return null;
                  },
                  onSaved: (value) => _tc = value!,
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
                      return 'Lütfen şifrenizi girin';
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
                      bool isAuthenticated = await authenticateUser(_tc, _password);
                      if (isAuthenticated) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HomePage()),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterPage()),
                    );
                  },
                  child: Text(
                    'Register',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StaffLoginPage()),
                    );
                  },
                  child: Text(
                    'Staff Login',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
