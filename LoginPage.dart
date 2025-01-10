import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'HomePage.dart'; // Giriş başarılı olduğunda yönlendirilecek sayfa
import 'RegisterPage.dart';
import 'LoginSelectionPage.dart'; // LoginSelectionPage'i içe aktar

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

  Future<Map<String, dynamic>?> authenticateUser(String tc, String password) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/kullaniciGiris'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'TC': tc, 'Sifre': password}),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody is Map<String, dynamic> && responseBody.containsKey('KullaniciID')) {
        final kullaniciID = responseBody['KullaniciID'].toString();
        
        // Log login time
        await http.post(
          Uri.parse('http://127.0.0.1:5004/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'KullaniciID': kullaniciID}),
        );

        // Kullanıcı bilgilerini almak için API çağrısı yapın
        final userResponse = await http.get(
          Uri.parse('http://127.0.0.1:5000/kullaniciBilgileri?KullaniciID=$kullaniciID'),
        );

        if (userResponse.statusCode == 200) {
          final userResponseBody = jsonDecode(userResponse.body);
          
          if (userResponseBody is List && userResponseBody.isNotEmpty) {
            final userData = userResponseBody.firstWhere(
              (user) => user['KullaniciID'].toString() == kullaniciID,
              orElse: () => {},
            );
            return {
              'KullaniciID': kullaniciID,
              'Adi': userData['Isim'] ?? 'Unknown User',
            };
          } else {
            throw Exception('Kullanıcı bilgileri bulunamadı');
          }
        } else {
          throw Exception('Kullanıcı bilgileri alınamadı');
        }
      } else {
        throw Exception('Kullanıcı ID bulunamadı');
      }
    } else {
      throw Exception('Başarısız giriş');
    }
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
                      try {
                        var user = await authenticateUser(_tc, _password);
                        if (user != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomePage(
                                kullaniciID: user['KullaniciID'].toString(),
                                kullaniciAdi: user['Adi'] ?? 'Unknown User',
                              ),
                            ),
                          );
                        } else {
                          setState(() {
                            _loginFailed = true;
                          });
                        }
                      } catch (e) {
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
                      MaterialPageRoute(builder: (context) => LoginSelectionPage()),
                    );
                  },
                  child: Text(
                    'Login Selection',
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
