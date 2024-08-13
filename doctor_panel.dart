import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class DoctorPanel extends StatefulWidget {
  @override
  _DoctorPanelState createState() => _DoctorPanelState();
}

class _DoctorPanelState extends State<DoctorPanel> {
  List<Map<String, dynamic>> patients = [];
  String selectedPatientTc = '';
  TextEditingController angleController = TextEditingController();
  TextEditingController feedbackController = TextEditingController();
  TextEditingController responseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPatients();
  }

  Future<void> fetchPatients() async {
    final response = await http.get(Uri.parse('http://localhost:5000/kullaniciBilgileri'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        patients = data.map((item) => item as Map<String, dynamic>).toList();
      });
    } else {
      throw Exception('Failed to load patient data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor Panel'),
        backgroundColor: Colors.teal,
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey[200],
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Search by TC',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // Add search logic here
                    },
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: patients
                          .where((patient) => patient['Isim']!
                              .toLowerCase()
                              .contains('')) // Add search filter here
                          .map((patient) {
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 4,
                          child: ListTile(
                            contentPadding: EdgeInsets.all(12.0),
                            title: Text(patient['Isim']!),
                            subtitle: Text('TC: ${patient['TC']}'),
                            onTap: () {
                              setState(() {
                                selectedPatientTc = patient['TC']!;
                                // Load patient details if needed
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: selectedPatientTc.isEmpty
                ? Center(child: Text('Select a patient', style: TextStyle(fontSize: 18, color: Colors.grey)))
                : PatientDetailPanel(
                    patient: patients.firstWhere((p) => p['TC'] == selectedPatientTc),
                    angleController: angleController,
                    feedbackController: feedbackController,
                    responseController: responseController,
                  ),
          ),
        ],
      ),
    );
  }
}

class PatientDetailPanel extends StatelessWidget {
  final Map<String, dynamic> patient;
  final TextEditingController angleController;
  final TextEditingController feedbackController;
  final TextEditingController responseController;

  PatientDetailPanel({
    required this.patient,
    required this.angleController,
    required this.feedbackController,
    required this.responseController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patient TC: ${patient['TC']}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Name: ${patient['Isim']} ${patient['Soyadı']}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Gender: ${patient['Cinsiyet']}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 8),
          Text(
            'Weight: ${patient['Kilo']} kg',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 8),
          Text(
            'Height: ${patient['Boy']} cm',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: () => _launchPhone(patient['TelefonNo']!),
            child: Text(
              'Phone: ${patient['TelefonNo']}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.blue),
            ),
          ),
          SizedBox(height: 16),
          Text('Adjust Angle Value', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          TextField(
            controller: angleController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter angle value',
              prefixIcon: Icon(Icons.arrow_forward),
            ),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          Text('Patient Feedback', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          TextField(
            controller: feedbackController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter patient feedback',
              prefixIcon: Icon(Icons.feedback),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 16),
          Text('Provide Feedback', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          TextField(
            controller: responseController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter your feedback',
              prefixIcon: Icon(Icons.comment),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  void _launchPhone(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
